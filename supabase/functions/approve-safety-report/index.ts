// supabase/functions/approve-safety-report/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { calculateSafetyReportPoints } from "../_shared/loyalty.ts"

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const supabaseClient = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        // Get User from Auth Header to check Admin role
        const authHeader = req.headers.get('Authorization')!
        const { data: { user }, error: authError } = await supabaseClient.auth.getUser(authHeader.replace('Bearer ', ''))

        if (authError || !user) throw new Error('Unauthenticated')

        // Check Admin Role
        const { data: profile } = await supabaseClient
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single()

        if (profile?.role !== 'admin') throw new Error('Permission denied')

        const { reportId, isValid } = await req.json()

        // 1. Fetch Report
        const { data: report, error: reportError } = await supabaseClient
            .from('safety_reports')
            .select('*')
            .eq('id', reportId)
            .single()

        if (reportError || !report) throw new Error('Report not found')

        // 2. Check Monthly Cap & Award Points
        let finalPoints = 0
        let rewardGranted = false

        if (isValid) {
            const { data: configDoc } = await supabaseClient
                .from('system_configs')
                .select('config')
                .eq('key', 'default')
                .single()
            const config = configDoc?.config || {}
            const maxReports = config.safety?.max_rewarded_reports_per_month || 3

            const { data: userProfile } = await supabaseClient
                .from('profiles')
                .select('rewarded_reports_count, loyalty_points')
                .eq('id', report.user_id)
                .single()

            if (userProfile && userProfile.rewarded_reports_count < maxReports) {
                finalPoints = calculateSafetyReportPoints({ loyalty: config.loyalty || {} } as any)

                await supabaseClient
                    .from('profiles')
                    .update({
                        loyalty_points: userProfile.loyalty_points + finalPoints,
                        rewarded_reports_count: userProfile.rewarded_reports_count + 1
                    })
                    .eq('id', report.user_id)

                rewardGranted = true
            }
        }

        // 3. Update Report
        await supabaseClient
            .from('safety_reports')
            .update({
                status: isValid ? 'approved' : 'rejected',
                points_awarded: finalPoints,
                reward_points_granted: rewardGranted,
                approved_by: user.id,
                approved_at: new Date().toISOString()
            })
            .eq('id', reportId)

        return new Response(
            JSON.stringify({ success: true, pointsAwarded: finalPoints }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

    } catch (error: any) {
        return new Response(
            JSON.stringify({ error: String(error?.message ?? error) }),
            {
                status: 400,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            },
        )
    }
})
