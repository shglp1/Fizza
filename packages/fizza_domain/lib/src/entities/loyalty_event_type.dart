enum LoyaltyEventType {
  rideCompleted,
  rideWithFemaleDriver,
  newSubscription,
  longTermSubscription,
  safetyReportValid,
  manualAdjustment, // For admin or other cases
}

extension LoyaltyEventTypeExtension on LoyaltyEventType {
  String get description {
    switch (this) {
      case LoyaltyEventType.rideCompleted:
        return 'Ride Completed';
      case LoyaltyEventType.rideWithFemaleDriver:
        return 'Ride with Female Driver';
      case LoyaltyEventType.newSubscription:
        return 'New Subscription';
      case LoyaltyEventType.longTermSubscription:
        return 'Long-term Subscription';
      case LoyaltyEventType.safetyReportValid:
        return 'Valid Safety Report';
      case LoyaltyEventType.manualAdjustment:
        return 'Manual Adjustment';
    }
  }
}
