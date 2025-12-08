// supabase/functions/aggregate-daily-stats/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    // This function is intended to be called by a Cron Job (e.g. pg_cron or Supabase Cron)
    // It should be secured so only the system can call it.
    // We can check for a specific header or just rely on Service Role if called internally.
    // For now, we'll allow it but assume it's triggered securely.
    // CORS لو حابب تتركه زي ما هو
    const cronSecretHeader = req.headers.get('x-cron-secret') || '';
    const cronSecretEnv = Deno.env.get('CRON_SECRET') || '';

    // امنع أي أحد بدون السكرت
    if (!cronSecretEnv || cronSecretHeader !== cronSecretEnv) {
        return new Response(
            JSON.stringify({ error: 'Unauthorized cron caller' }),
            {
                status: 401,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            },
        );
    }

    try {
        const supabaseClient = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        const today = new Date().toISOString().split('T')[0]
        const startOfDay = new Date(new Date().setHours(0, 0, 0, 0)).toISOString()

        // 1. Trips & Revenue
        const { data: trips, error: tripsError } = await supabaseClient
            .from('trips')
            .select('cost, driver_id, scheduled_time, actual_pickup_time')
            .eq('status', 'completed')
            .gte('completed_at', startOfDay)

        if (tripsError) throw new Error(tripsError.message)

        let totalTrips = 0
        let totalRevenue = 0
        let totalDelay = 0
        const driverTripCounts: Record<string, number> = {}

        trips?.forEach(t => {
            totalTrips++
            totalRevenue += (t.cost || 0)

            if (t.scheduled_time && t.actual_pickup_time) {
                const scheduled = new Date(t.scheduled_time).getTime()
                const actual = new Date(t.actual_pickup_time).getTime()
                const delay = (actual - scheduled) / 60000
                if (delay > 0) totalDelay += delay
            }

            if (t.driver_id) {
                driverTripCounts[t.driver_id] = (driverTripCounts[t.driver_id] || 0) + 1
            }
        })

        // 2. Complaints
        const { count: complaintsCount, error: complaintsError } = await supabaseClient
            .from('safety_reports')
            .select('*', { count: 'exact', head: true })
            .gte('created_at', startOfDay)

        if (complaintsError) throw new Error(complaintsError.message)

        // 3. Active Subs
        const { count: activeSubscriptions, error: subsError } = await supabaseClient
            .from('user_subscriptions')
            .select('*', { count: 'exact', head: true })
            .eq('status', 'active')

        if (subsError) throw new Error(subsError.message)

        // 4. Best/Worst Driver
        let bestDriverId = null
        let maxTrips = -1
        let worstDriverId = null
        let minTrips = 999999

        for (const [driverId, count] of Object.entries(driverTripCounts)) {
            if (count > maxTrips) {
                maxTrips = count
                bestDriverId = driverId
            }
            if (count < minTrips) {
                minTrips = count
                worstDriverId = driverId
            }
        }

        if (totalTrips === 0) {
            minTrips = 0
            worstDriverId = null
        }

        // Write to stats_daily
        await supabaseClient
            .from('stats_daily')
            .upsert({
                date: today,
                total_trips: totalTrips,
                total_revenue: totalRevenue,
                total_delay_minutes: totalDelay,
                complaints_count: complaintsCount || 0,
                active_subscriptions: activeSubscriptions || 0,
                best_driver_id: bestDriverId,
                worst_driver_id: worstDriverId,
                average_delay_minutes: totalTrips > 0 ? totalDelay / totalTrips : 0,
                generated_at: new Date().toISOString()
            })

        // Update Global Summary
        // We need to fetch current global stats first or use RPC increment.
        // For simplicity, we'll just increment blindly if we had a way, but standard update needs read.
        // Actually, stats_global is a summary. We should probably just re-calculate or increment.
        // The original code used FieldValue.increment.
        // We can do the same via RPC or just read-update.
        // Let's read-update.
        const { data: globalStats } = await supabaseClient
            .from('stats_global')
            .select('*')
            .eq('key', 'summary')
            .single()

        if (globalStats) {
            await supabaseClient
                .from('stats_global')
                .update({
                    total_revenue: globalStats.total_revenue + totalRevenue,
                    total_trips: globalStats.total_trips + totalTrips,
                    updated_at: new Date().toISOString()
                })
                .eq('key', 'summary')
        } else {
            await supabaseClient
                .from('stats_global')
                .insert({
                    key: 'summary',
                    total_revenue: totalRevenue,
                    total_trips: totalTrips
                })
        }

        return new Response(
            JSON.stringify({ success: true }),
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
