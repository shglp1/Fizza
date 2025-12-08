// supabase/functions/assign-subscription/index.ts
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

        const { userId, packageId, pickupLocation, dropoffLocation, pickupTime, returnTime, addOnIds } = await req.json()

        // 1. Validate Input
        if (!userId || !packageId || !pickupLocation || !dropoffLocation || !pickupTime || !returnTime) {
            throw new Error('Missing required fields')
        }

        // 2. Fetch Package & Config
        const { data: pkg, error: pkgError } = await supabaseClient
            .from('subscription_packages')
            .select('*')
            .eq('id', packageId)
            .single()

        if (pkgError || !pkg) throw new Error('Package not found')

        const { data: configDoc } = await supabaseClient
            .from('system_configs')
            .select('config')
            .eq('key', 'default')
            .single()

        const config = configDoc?.config || {}
        const MAX_DISTANCE_KM = config.operational?.max_pickup_distance_km || 10

        // 3. Find Candidate Drivers
        // Fetch user profile to check parent_user_id
        const { data: userProfile } = await supabaseClient
            .from('profiles')
            .select('parent_user_id')
            .eq('id', userId)
            .single()

        const parentUserId = userProfile?.parent_user_id

        let query = supabaseClient
            .from('drivers')
            .select(`
                id, 
                current_location, 
                gender, 
                user_subscriptions!driver_id (count)
            `)
            .eq('is_available', true)
            .eq('is_suspended', false)

        if (pkg.is_female_only) {
            query = query.eq('gender', 'female')
        }

        const { data: drivers, error: driverError } = await query

        if (driverError) throw new Error(driverError.message)

        let bestDriverId = null
        let minDistance = MAX_DISTANCE_KM

        const calculateDistance = (lat1: number, lon1: number, lat2: number, lon2: number) => {
            const R = 6371;
            const dLat = (lat2 - lat1) * Math.PI / 180;
            const dLon = (lon2 - lon1) * Math.PI / 180;
            const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
                Math.sin(dLon / 2) * Math.sin(dLon / 2);
            const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
            return R * c;
        }

        for (const driver of drivers) {
            // Check active subs count (capacity)
            const { count } = await supabaseClient
                .from('user_subscriptions')
                .select('*', { count: 'exact', head: true })
                .eq('driver_id', driver.id)
                .eq('status', 'active')

            if ((count || 0) >= 4) continue

            // Distance Check
            // GeoJSON safety check
            if (!driver.current_location || !driver.current_location.coordinates || driver.current_location.coordinates.length < 2) continue;

            const driverLon = driver.current_location.coordinates[0]
            const driverLat = driver.current_location.coordinates[1]

            const dist = calculateDistance(
                pickupLocation.latitude, pickupLocation.longitude,
                driverLat, driverLon
            )

            if (dist > MAX_DISTANCE_KM) continue

            // Family Priority
            if (parentUserId) {
                const { data: parentSub } = await supabaseClient
                    .from('user_subscriptions')
                    .select('id')
                    .eq('driver_id', driver.id)
                    .or(`user_id.eq.${parentUserId},parent_user_id.eq.${parentUserId}`)
                    .limit(1)

                if (parentSub && parentSub.length > 0) {
                    bestDriverId = driver.id
                    break // Found family driver
                }
            }

            if (dist < minDistance) {
                minDistance = dist
                bestDriverId = driver.id
            }
        }

        if (!bestDriverId) {
            if (pkg.is_female_only) throw new Error('NO_FEMALE_DRIVER_AVAILABLE')
            throw new Error('NO_DRIVER_AVAILABLE')
        }

        // 4. Assign Driver & Create Subscription
        // Check for pending using maybeSingle() to avoid error on 0 rows
        const { data: pendingSub } = await supabaseClient
            .from('user_subscriptions')
            .select('id')
            .eq('user_id', userId)
            .eq('package_id', packageId)
            .eq('status', 'pending_assignment')
            .maybeSingle()

        let subId

        // Calculate dates based on package duration
        const durationDays = pkg.duration_days ?? 30
        const startDate = new Date()
        const endDate = new Date(startDate.getTime() + durationDays * 24 * 60 * 60 * 1000)

        const subData = {
            user_id: userId,
            package_id: packageId,
            driver_id: bestDriverId,
            status: 'active',
            start_date: startDate.toISOString(),
            end_date: endDate.toISOString(),
            pickup_location: { type: 'Point', coordinates: [pickupLocation.longitude, pickupLocation.latitude] },
            dropoff_location: { type: 'Point', coordinates: [dropoffLocation.longitude, dropoffLocation.latitude] },
            pickup_time: pickupTime,
            return_time: returnTime,
            add_on_ids: addOnIds || [],
            parent_user_id: parentUserId,
            plan_type: pkg.plan_type, // Inherit from package
            auto_renew: true, // Default as per schema/logic
            is_female_only: pkg.is_female_only
        }

        if (pendingSub) {
            subId = pendingSub.id
            await supabaseClient
                .from('user_subscriptions')
                .update(subData)
                .eq('id', subId)
        } else {
            const { data: newSub, error: createError } = await supabaseClient
                .from('user_subscriptions')
                .insert(subData)
                .select()
                .single()

            if (createError) throw new Error(createError.message)
            subId = newSub.id
        }

        return new Response(
            JSON.stringify({ success: true, subscriptionId: subId, driverId: bestDriverId }),
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
