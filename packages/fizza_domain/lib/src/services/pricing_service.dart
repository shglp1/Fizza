import '../entities/system_config_entity.dart';

class PricingService {
  final PricingConfig config;

  PricingService(this.config);

  /// Calculates the recommended monthly subscription price for a specific route.
  /// Formula: (Driver Costs + App Overhead) + Margin
  /// Note: This is a simplified per-user calculation assuming a full car (capacity 4).
  double calculateRecommendedMonthlyPrice({
    required double dailyDistanceKm,
    required double carConsumptionLitersPer100Km,
    int workingDays = 22,
    int capacity = 4,
  }) {
    // 1. Driver Costs (Monthly)
    final salary = config.salaryPerDriver;
    
    final totalMonthlyDistance = dailyDistanceKm * workingDays;
    final fuelCost = (totalMonthlyDistance / 100) * carConsumptionLitersPer100Km * config.fuelPrice;
    
    final maintenance = config.maintenancePerMonth;
    final depreciation = config.depreciationPerMonth;
    final insurance = config.insurancePerMonth;

    final totalDriverMonthlyCost = salary + fuelCost + maintenance + depreciation + insurance;

    // 2. Cost Per User (assuming full capacity)
    final costPerUser = totalDriverMonthlyCost / capacity;

    // 3. Total Cost Per User (including App Overhead)
    final totalCostPerUser = costPerUser + config.overheadPerUser;

    // 4. Final Price with Margin
    final price = totalCostPerUser * (1 + config.marginPercentage);

    return double.parse(price.toStringAsFixed(2));
  }

  /// Calculates the theoretical value of a single trip.
  /// Used for tracking "value delivered" vs subscription price.
  double calculateTheoreticalTripValue(double distanceKm) {
    return config.baseFare + (distanceKm * config.pricePerKm);
  }
}
