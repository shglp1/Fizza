// supabase/functions/complete-trip/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { calculateRidePoints } from "../_shared/loyalty.ts"

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

        const { tripId, driverId, actualDistance, actualDuration } = await req.json()

        // 1. Validate
        const { data: trip, error: tripError } = await supabaseClient
            .from('trips')
            .select('*, user_id')
            .eq('id', tripId)
            .single()

        if (tripError || !trip) throw new Error('Trip not found')
        if (trip.status === 'completed') throw new Error('Trip already completed')

        // 2. Calculate Earnings
        const { data: configDoc } = await supabaseClient
            .from('system_configs')
            .select('config')
            .eq('key', 'default')
            .single()

        const config = configDoc?.config || {}
        const baseFare = config.pricing?.base_fare || 10
        const pricePerKm = config.pricing?.price_per_km || 2
        const commissionRate = config.pricing?.driver_commission_rate || 0.15

        const grossAmount = baseFare + (actualDistance * pricePerKm)
        const driverEarnings = grossAmount * (1 - commissionRate)

        // 3. Update Trip
        const { error: updateTripError } = await supabaseClient
            .from('trips')
            .update({
                status: 'completed',
                actual_distance_km: actualDistance,
                actual_duration_min: actualDuration,
                cost: grossAmount,
                driver_earnings: driverEarnings,
                completed_at: new Date().toISOString()
            })
            .eq('id', tripId)

        if (updateTripError) throw new Error(updateTripError.message)

        // 4. Update Driver Stats
        // We use RPC for atomic increment if possible, or just read-write.
        // For migration speed, we'll do read-write but RPC `increment_driver_stats` is better.
        // I'll stick to read-write for now as I can't create RPCs easily.
        const { data: driver } = await supabaseClient
            .from('drivers')
            .select('total_rides, total_earnings, gender')
            .eq('id', driverId)
            .single()

        if (driver) {
            await supabaseClient
                .from('drivers')
                .update({
                    total_rides: driver.total_rides + 1,
                    total_earnings: driver.total_earnings + driverEarnings
                })
                .eq('id', driverId)
        }

        // 5. Loyalty Points
        if (trip.user_id) {
            const isFemaleDriver = driver?.gender === 'female'
            const points = calculateRidePoints({ loyalty: config.loyalty || {} } as any, isFemaleDriver)

            const { data: profile } = await supabaseClient
                .from('profiles')
                .select('loyalty_points')
                .eq('id', trip.user_id)
                .single()

            if (profile) {
                await supabaseClient
                    .from('profiles')
                    .update({ loyalty_points: profile.loyalty_points + points })
                    .eq('id', trip.user_id)
            }
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
