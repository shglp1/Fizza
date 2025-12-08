import 'package:equatable/equatable.dart';

class OperationalConfig extends Equatable {
  final int operatingStartHour;
  final int operatingEndHour;
  final double maxPickupDistanceKm;

  const OperationalConfig({
    required this.operatingStartHour,
    required this.operatingEndHour,
    required this.maxPickupDistanceKm,
  });

  @override
  List<Object> get props => [operatingStartHour, operatingEndHour, maxPickupDistanceKm];
}

class SystemConfigEntity extends Equatable {
  final PricingConfig pricing;
  final SubscriptionConfig subscription;
  final LoyaltyConfig loyalty;
  final SafetyConfig safety;
  final OperationalConfig operational;

  const SystemConfigEntity({
    required this.pricing,
    required this.subscription,
    required this.loyalty,
    required this.safety,
    required this.operational,
  });

  @override
  List<Object> get props => [pricing, subscription, loyalty, safety, operational];
}

class PricingConfig extends Equatable {
  final double baseFare;
  final double pricePerKm;
  final double minFare;
  final int cancellationFeeWindowHours;
  final double cancellationFeeAmount;
  final double driverCommissionRate;
  
  // Cost-Based Pricing Components
  final double salaryPerDriver;
  final double fuelPrice; // Per Liter
  final double maintenancePerMonth;
  final double depreciationPerMonth;
  final double insurancePerMonth;
  final double overheadPerUser;
  final double marginPercentage; // e.g., 0.20 for 20%

  const PricingConfig({
    required this.baseFare,
    required this.pricePerKm,
    required this.minFare,
    required this.cancellationFeeWindowHours,
    required this.cancellationFeeAmount,
    required this.driverCommissionRate,
    this.salaryPerDriver = 3000.0,
    this.fuelPrice = 2.33,
    this.maintenancePerMonth = 200.0,
    this.depreciationPerMonth = 833.0,
    this.insurancePerMonth = 150.0,
    this.overheadPerUser = 50.0,
    this.marginPercentage = 0.20,
  });

  @override
  List<Object> get props => [
        baseFare,
        pricePerKm,
        minFare,
        cancellationFeeWindowHours,
        cancellationFeeAmount,
        driverCommissionRate,
        salaryPerDriver,
        fuelPrice,
        maintenancePerMonth,
        depreciationPerMonth,
        insurancePerMonth,
        overheadPerUser,
        marginPercentage,
      ];
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
