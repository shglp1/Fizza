import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';
import '../datasources/system_config_datasource.dart';
import '../models/system_config_model.dart';

@LazySingleton(as: IAdminRepository)
class AdminRepositoryImpl implements IAdminRepository {
  final FirebaseFirestore _firestore;
  final ISystemConfigDataSource _configDataSource;

  AdminRepositoryImpl(this._firestore, this._configDataSource);

  @override
  Future<Either<Failure, SystemConfigEntity>> getSystemConfig() async {
    try {
      final config = await _configDataSource.getConfig();
      return Right(config);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateSystemConfig(SystemConfigEntity config) async {
    try {
      // Cast to Model to access toJson or reconstruct
      final model = config is SystemConfigModel 
          ? config 
          : SystemConfigModel(
              pricing: PricingConfigModel(
                baseFare: config.pricing.baseFare,
                pricePerKm: config.pricing.pricePerKm,
                minFare: config.pricing.minFare,
                cancellationFeeWindowHours: config.pricing.cancellationFeeWindowHours,
                cancellationFeeAmount: config.pricing.cancellationFeeAmount,
                driverCommissionRate: config.pricing.driverCommissionRate,
                salaryPerDriver: config.pricing.salaryPerDriver,
                fuelPrice: config.pricing.fuelPrice,
                maintenancePerMonth: config.pricing.maintenancePerMonth,
                depreciationPerMonth: config.pricing.depreciationPerMonth,
                insurancePerMonth: config.pricing.insurancePerMonth,
                overheadPerUser: config.pricing.overheadPerUser,
                marginPercentage: config.pricing.marginPercentage,
              ),
              subscription: SubscriptionConfigModel(
                monthlyPlanPrice: config.subscription.monthlyPlanPrice,
                monthlyRideLimit: config.subscription.monthlyRideLimit,
                rideDistanceLimitKm: config.subscription.rideDistanceLimitKm,
                extraRidePrice: config.subscription.extraRidePrice,
              ),
              loyalty: LoyaltyConfigModel(
                pointsPerRide: config.loyalty.pointsPerRide,
                pointsFemaleDriver: config.loyalty.pointsFemaleDriver,
                pointsMonthlySub: config.loyalty.pointsMonthlySub,
                pointsLongTermSub: config.loyalty.pointsLongTermSub,
                pointsSafetyReport: config.loyalty.pointsSafetyReport,
                levelThresholds: config.loyalty.levelThresholds,
              ),
              safety: SafetyConfigModel(
                maxRewardedReportsPerMonth: config.safety.maxRewardedReportsPerMonth,
                autoSuspendReportCount: config.safety.autoSuspendReportCount,
              ),
              operational: OperationalConfigModel(
                operatingStartHour: config.operational.operatingStartHour,
                operatingEndHour: config.operational.operatingEndHour,
                maxPickupDistanceKm: config.operational.maxPickupDistanceKm,
              ),
            );
            
      await _configDataSource.updateConfig(model);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AdminDashboardEntity>> getDashboardStats() async {
    try {
      // 1. Get Counts (Using Firestore Count Aggregation)
      final usersCount = await _firestore.collection('users').count().get();
      final activeDriversCount = await _firestore.collection('drivers').where('isAvailable', isEqualTo: true).count().get();
      final pendingDriversCount = await _firestore.collection('drivers').where('isVerified', isEqualTo: false).count().get();
      final activeTripsCount = await _firestore.collection('trips').where('status', isEqualTo: 'started').count().get();
      final pendingComplaintsCount = await _firestore.collection('safety_reports').where('status', isEqualTo: 'pending').count().get();
      final activeSubsCount = await _firestore.collection('user_subscriptions').where('isActive', isEqualTo: true).count().get();

      // 2. Get Today's Stats
      final today = DateTime.now().toIso8601String().split('T')[0];
      final dailyStatsDoc = await _firestore.collection('stats_daily').doc(today).get();
      final todayRevenue = (dailyStatsDoc.data()?['totalRevenue'] as num?)?.toDouble() ?? 0.0;
      final worstDriverId = dailyStatsDoc.data()?['worstDriverId'] as String?;

      // 3. Get Total Revenue
      final globalStatsDoc = await _firestore.collection('stats_global').doc('summary').get();
      final totalRevenue = (globalStatsDoc.data()?['totalRevenue'] as num?)?.toDouble() ?? 0.0;

      return Right(AdminDashboardEntity(
        totalUsers: usersCount.count ?? 0,
        activeDrivers: activeDriversCount.count ?? 0,
        pendingDriverApprovals: pendingDriversCount.count ?? 0,
        activeTrips: activeTripsCount.count ?? 0,
        totalRevenue: totalRevenue,
        todayRevenue: todayRevenue,
        pendingComplaints: pendingComplaintsCount.count ?? 0,
        activeSubscriptions: activeSubsCount.count ?? 0,
        worstDriverId: worstDriverId,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getFinancialReport({required DateTime startDate, required DateTime endDate}) async {
    try {
      final startStr = startDate.toIso8601String().split('T')[0];
      final endStr = endDate.toIso8601String().split('T')[0];

      final snapshot = await _firestore.collection('stats_daily')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: startStr)
          .where(FieldPath.documentId, isLessThanOrEqualTo: endStr)
          .get();

      double totalRevenue = 0;
      double totalTrips = 0;
      double totalDelay = 0;
      int complaintsCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalRevenue += (data['totalRevenue'] as num?)?.toDouble() ?? 0.0;
        totalTrips += (data['totalTrips'] as num?)?.toInt() ?? 0;
        totalDelay += (data['totalDelay'] as num?)?.toDouble() ?? 0.0;
        complaintsCount += (data['complaintsCount'] as num?)?.toInt() ?? 0;
      }

      // Estimate costs/payouts based on config
      final config = await _configDataSource.getConfig();
      final driverShare = totalRevenue * (1 - config.pricing.driverCommissionRate);
      final netProfit = totalRevenue - driverShare;

      return Right({
        'totalRevenue': totalRevenue,
        'subscriptionRevenue': totalRevenue,
        'tripRevenue': 0.0,
        'driverPayouts': driverShare,
        'netProfit': netProfit,
        'totalTrips': totalTrips,
        'avgDelay': totalTrips > 0 ? totalDelay / totalTrips : 0,
        'complaintsCount': complaintsCount,
      });
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
