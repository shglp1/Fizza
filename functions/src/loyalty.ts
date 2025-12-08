import * as admin from 'firebase-admin';

// Helper interface for System Config (subset)
interface SystemConfig {
    loyalty: {
        points_per_ride: number;
        points_female_driver: number;
        points_monthly_sub: number;
        points_long_term_sub: number;
        points_safety_report: number;
    };
}

/**
 * Calculates points for a completed ride.
 */
export function calculateRidePoints(config: SystemConfig, isFemaleDriver: boolean): number {
    let points = config.loyalty.points_per_ride || 5;
    if (isFemaleDriver) {
        points += (config.loyalty.points_female_driver || 10);
    }
    return points;
}

/**
 * Calculates points for a safety report.
 */
export function calculateSafetyReportPoints(config: SystemConfig): number {
    return config.loyalty.points_safety_report || 40;
}

/**
 * Awards points to a user.
 */
export async function awardPoints(userId: string, points: number, description: string): Promise<void> {
    if (points <= 0) return;

    const db = admin.firestore();
    const userRef = db.collection('users').doc(userId);

    await userRef.update({
        loyaltyPoints: admin.firestore.FieldValue.increment(points),
    });

    // Optional: Add to history if needed
    /*
    await userRef.collection('loyalty_history').add({
        points,
        description,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    */
}
