import 'package:fizza_domain/fizza_domain.dart';

class SystemConfigModel extends SystemConfigEntity {
  const SystemConfigModel({
    required super.pricing,
    required super.subscription,
    required super.loyalty,
    required super.safety,
    required super.operational,
  });

  factory SystemConfigModel.fromJson(Map<String, dynamic> json) {
    return SystemConfigModel(
      pricing: PricingConfigModel.fromJson(json['pricing'] ?? {}),
      subscription: SubscriptionConfigModel.fromJson(json['subscription'] ?? {}),
      loyalty: LoyaltyConfigModel.fromJson(json['loyalty'] ?? {}),
      safety: SafetyConfigModel.fromJson(json['safety'] ?? {}),
      operational: OperationalConfigModel.fromJson(json['operational'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pricing': (pricing as PricingConfigModel).toJson(),
      'subscription': (subscription as SubscriptionConfigModel).toJson(),
      'loyalty': (loyalty as LoyaltyConfigModel).toJson(),
      'safety': (safety as SafetyConfigModel).toJson(),
      'operational': (operational as OperationalConfigModel).toJson(),
    };
  }
  
  // Default config if none exists
  factory SystemConfigModel.defaultConfig() {
    return const SystemConfigModel(
      pricing: PricingConfigModel(
        baseFare: 5.0,
        pricePerKm: 1.2,
        minFare: 10.0,
        cancellationFeeWindowHours: 72,
        cancellationFeeAmount: 10.0,
        driverCommissionRate: 0.15,
        salaryPerDriver: 3000.0,
        fuelPrice: 2.33,
        maintenancePerMonth: 200.0,
        depreciationPerMonth: 833.0,
        insurancePerMonth: 150.0,
        overheadPerUser: 50.0,
        marginPercentage: 0.20,
      ),
      subscription: SubscriptionConfigModel(
        monthlyPlanPrice: 199.0,
        monthlyRideLimit: 20,
        rideDistanceLimitKm: 7.0,
        extraRidePrice: 8.0,
      ),
      loyalty: LoyaltyConfigModel(
        pointsPerRide: 5,
        pointsFemaleDriver: 10,
        pointsMonthlySub: 30,
        pointsLongTermSub: 100,
        pointsSafetyReport: 40,
        levelThresholds: {'bronze': 0, 'silver': 500, 'gold': 2000},
      ),
      safety: SafetyConfigModel(
        maxRewardedReportsPerMonth: 3,
        autoSuspendReportCount: 3,
      ),
      operational: OperationalConfigModel(
        operatingStartHour: 6,
        operatingEndHour: 23,
        maxPickupDistanceKm: 10.0,
      ),
    );
  }
}

class OperationalConfigModel extends OperationalConfig {
  const OperationalConfigModel({
    required super.operatingStartHour,
    required super.operatingEndHour,
    required super.maxPickupDistanceKm,
  });

  factory OperationalConfigModel.fromJson(Map<String, dynamic> json) {
    return OperationalConfigModel(
      operatingStartHour: (json['operating_start_hour'] as num?)?.toInt() ?? 6,
      operatingEndHour: (json['operating_end_hour'] as num?)?.toInt() ?? 23,
      maxPickupDistanceKm: (json['max_pickup_distance_km'] as num?)?.toDouble() ?? 10.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'operating_start_hour': operatingStartHour,
    'operating_end_hour': operatingEndHour,
    'max_pickup_distance_km': maxPickupDistanceKm,
  };
}

class PricingConfigModel extends PricingConfig {
  const PricingConfigModel({
    required super.baseFare,
    required super.pricePerKm,
    required super.minFare,
    required super.cancellationFeeWindowHours,
    required super.cancellationFeeAmount,
    required super.driverCommissionRate,
    required super.salaryPerDriver,
    required super.fuelPrice,
    required super.maintenancePerMonth,
    required super.depreciationPerMonth,
    required super.insurancePerMonth,
    required super.overheadPerUser,
    required super.marginPercentage,
  });

  factory PricingConfigModel.fromJson(Map<String, dynamic> json) {
    return PricingConfigModel(
      baseFare: (json['base_fare'] as num?)?.toDouble() ?? 5.0,
      pricePerKm: (json['price_per_km'] as num?)?.toDouble() ?? 1.2,
      minFare: (json['min_fare'] as num?)?.toDouble() ?? 10.0,
      cancellationFeeWindowHours: (json['cancellation_fee_window_hours'] as num?)?.toInt() ?? 72,
      cancellationFeeAmount: (json['cancellation_fee_amount'] as num?)?.toDouble() ?? 10.0,
      driverCommissionRate: (json['driver_commission_rate'] as num?)?.toDouble() ?? 0.15,
      salaryPerDriver: (json['salary_per_driver'] as num?)?.toDouble() ?? 3000.0,
      fuelPrice: (json['fuel_price'] as num?)?.toDouble() ?? 2.33,
      maintenancePerMonth: (json['maintenance_per_month'] as num?)?.toDouble() ?? 200.0,
      depreciationPerMonth: (json['depreciation_per_month'] as num?)?.toDouble() ?? 833.0,
      insurancePerMonth: (json['insurance_per_month'] as num?)?.toDouble() ?? 150.0,
      overheadPerUser: (json['overhead_per_user'] as num?)?.toDouble() ?? 50.0,
      marginPercentage: (json['margin_percentage'] as num?)?.toDouble() ?? 0.20,
    );
  }

  Map<String, dynamic> toJson() => {
    'base_fare': baseFare,
    'price_per_km': pricePerKm,
    'min_fare': minFare,
    'cancellation_fee_window_hours': cancellationFeeWindowHours,
    'cancellation_fee_amount': cancellationFeeAmount,
    'driver_commission_rate': driverCommissionRate,
    'salary_per_driver': salaryPerDriver,
    'fuel_price': fuelPrice,
    'maintenance_per_month': maintenancePerMonth,
    'depreciation_per_month': depreciationPerMonth,
    'insurance_per_month': insurancePerMonth,
    'overhead_per_user': overheadPerUser,
    'margin_percentage': marginPercentage,
  };
}

class SubscriptionConfigModel extends SubscriptionConfig {
  const SubscriptionConfigModel({
    required super.monthlyPlanPrice,
    required super.monthlyRideLimit,
    required super.rideDistanceLimitKm,
    required super.extraRidePrice,
  });

  factory SubscriptionConfigModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionConfigModel(
      monthlyPlanPrice: (json['monthly_plan_price'] as num?)?.toDouble() ?? 199.0,
      monthlyRideLimit: (json['monthly_ride_limit'] as num?)?.toInt() ?? 20,
      rideDistanceLimitKm: (json['ride_distance_limit_km'] as num?)?.toDouble() ?? 7.0,
      extraRidePrice: (json['extra_ride_price'] as num?)?.toDouble() ?? 8.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'monthly_plan_price': monthlyPlanPrice,
    'monthly_ride_limit': monthlyRideLimit,
    'ride_distance_limit_km': rideDistanceLimitKm,
    'extra_ride_price': extraRidePrice,
  };
}

class LoyaltyConfigModel extends LoyaltyConfig {
  const LoyaltyConfigModel({
    required super.pointsPerRide,
    required super.pointsFemaleDriver,
    required super.pointsMonthlySub,
    required super.pointsLongTermSub,
    required super.pointsSafetyReport,
    required super.levelThresholds,
  });

  factory LoyaltyConfigModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyConfigModel(
      pointsPerRide: (json['points_per_ride'] as num?)?.toInt() ?? 5,
      pointsFemaleDriver: (json['points_female_driver'] as num?)?.toInt() ?? 10,
      pointsMonthlySub: (json['points_monthly_sub'] as num?)?.toInt() ?? 30,
      pointsLongTermSub: (json['points_long_term_sub'] as num?)?.toInt() ?? 100,
      pointsSafetyReport: (json['points_safety_report'] as num?)?.toInt() ?? 40,
      levelThresholds: Map<String, int>.from(json['level_thresholds'] ?? {'bronze': 0, 'silver': 500, 'gold': 2000}),
    );
  }

  Map<String, dynamic> toJson() => {
    'points_per_ride': pointsPerRide,
    'points_female_driver': pointsFemaleDriver,
    'points_monthly_sub': pointsMonthlySub,
    'points_long_term_sub': pointsLongTermSub,
    'points_safety_report': pointsSafetyReport,
    'level_thresholds': levelThresholds,
  };
}

class SafetyConfigModel extends SafetyConfig {
  const SafetyConfigModel({
    required super.maxRewardedReportsPerMonth,
    required super.autoSuspendReportCount,
  });

  factory SafetyConfigModel.fromJson(Map<String, dynamic> json) {
    return SafetyConfigModel(
      maxRewardedReportsPerMonth: (json['max_rewarded_reports_per_month'] as num?)?.toInt() ?? 3,
      autoSuspendReportCount: (json['auto_suspend_report_count'] as num?)?.toInt() ?? 3,
    );
  }

  Map<String, dynamic> toJson() => {
    'max_rewarded_reports_per_month': maxRewardedReportsPerMonth,
    'auto_suspend_report_count': autoSuspendReportCount,
  };
}
