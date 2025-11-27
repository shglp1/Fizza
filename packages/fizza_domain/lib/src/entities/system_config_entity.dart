import 'package:equatable/equatable.dart';

class SystemConfigEntity extends Equatable {
  final PricingConfig pricing;
  final SubscriptionConfig subscription;
  final LoyaltyConfig loyalty;
  final SafetyConfig safety;

  const SystemConfigEntity({
    required this.pricing,
    required this.subscription,
    required this.loyalty,
    required this.safety,
  });

  @override
  List<Object> get props => [pricing, subscription, loyalty, safety];
}

class PricingConfig extends Equatable {
  final double baseFare;
  final double pricePerKm;
  final double minFare;
  final int cancellationFeeWindowHours;
  final double cancellationFeeAmount;
  final double driverCommissionRate;

  const PricingConfig({
    required this.baseFare,
    required this.pricePerKm,
    required this.minFare,
    required this.cancellationFeeWindowHours,
    required this.cancellationFeeAmount,
    required this.driverCommissionRate,
  });

  @override
  List<Object> get props => [baseFare, pricePerKm, minFare, cancellationFeeWindowHours, cancellationFeeAmount, driverCommissionRate];
}

class SubscriptionConfig extends Equatable {
  final double monthlyPlanPrice;
  final int monthlyRideLimit;
  final double rideDistanceLimitKm;
  final double extraRidePrice;

  const SubscriptionConfig({
    required this.monthlyPlanPrice,
    required this.monthlyRideLimit,
    required this.rideDistanceLimitKm,
    required this.extraRidePrice,
  });

  @override
  List<Object> get props => [monthlyPlanPrice, monthlyRideLimit, rideDistanceLimitKm, extraRidePrice];
}

class LoyaltyConfig extends Equatable {
  final int pointsPerRide;
  final int pointsFemaleDriver;
  final int pointsMonthlySub;
  final int pointsLongTermSub;
  final int pointsSafetyReport;
  final Map<String, int> levelThresholds;

  const LoyaltyConfig({
    required this.pointsPerRide,
    required this.pointsFemaleDriver,
    required this.pointsMonthlySub,
    required this.pointsLongTermSub,
    required this.pointsSafetyReport,
    required this.levelThresholds,
  });

  @override
  List<Object> get props => [pointsPerRide, pointsFemaleDriver, pointsMonthlySub, pointsLongTermSub, pointsSafetyReport, levelThresholds];
}

class SafetyConfig extends Equatable {
  final int maxRewardedReportsPerMonth;
  final int autoSuspendReportCount;

  const SafetyConfig({
    required this.maxRewardedReportsPerMonth,
    required this.autoSuspendReportCount,
  });

  @override
  List<Object> get props => [maxRewardedReportsPerMonth, autoSuspendReportCount];
}
