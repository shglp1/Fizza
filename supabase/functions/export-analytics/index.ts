// supabase/functions/export-analytics/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

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

        // Security Check (Admin Only)
        const authHeader = req.headers.get('Authorization')!
        const { data: { user }, error: authError } = await supabaseClient.auth.getUser(authHeader.replace('Bearer ', ''))
        if (authError || !user) throw new Error('Unauthenticated')

        const { data: profile } = await supabaseClient
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single()

        if (profile?.role !== 'admin') throw new Error('Permission denied')

        const { type } = await req.json() // 'basic', 'financial', 'operations'

        // Fetch stats
        const { data: stats, error: statsError } = await supabaseClient
            .from('stats_daily')
            .select('*')
            .order('date', { ascending: false })
            .limit(30)

        if (statsError) throw new Error(statsError.message)

        let csvContent = ''

        if (type === 'financial') {
            csvContent = 'Date,Total Revenue,Total Trips\n'
            stats?.forEach(d => {
                csvContent += `${d.date},${d.total_revenue},${d.total_trips}\n`
            })
        } else if (type === 'operations') {
            csvContent = 'Date,Total Trips,Avg Delay,Complaints,Best Driver,Worst Driver\n'
            stats?.forEach(d => {
                csvContent += `${d.date},${d.total_trips},${d.average_delay_minutes},${d.complaints_count},${d.best_driver_id},${d.worst_driver_id}\n`
            })
        } else {
            // Basic
            csvContent = 'Date,Total Trips,Active Subs\n'
            stats?.forEach(d => {
                csvContent += `${d.date},${d.total_trips},${d.active_subscriptions}\n`
            })
        }

        return new Response(
            JSON.stringify({ csv: csvContent }),
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
