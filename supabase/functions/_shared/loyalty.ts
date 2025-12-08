// supabase/functions/_shared/loyalty.ts

export interface SystemConfig {
    loyalty: {
        points_per_ride: number;
        points_female_driver: number;
        points_monthly_sub: number;
        points_long_term_sub: number;
        points_safety_report: number;
    };
}

export function calculateRidePoints(config: SystemConfig, isFemaleDriver: boolean): number {
    let points = config.loyalty.points_per_ride || 5;
    if (isFemaleDriver) {
        points += (config.loyalty.points_female_driver || 10);
    }
    return points;
}

export function calculateSafetyReportPoints(config: SystemConfig): number {
    return config.loyalty.points_safety_report || 40;
}
