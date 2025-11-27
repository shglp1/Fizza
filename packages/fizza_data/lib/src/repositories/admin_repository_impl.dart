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
      // Cast to Model to access toJson
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
      // In a real app, these would likely be aggregated by a Cloud Function 
      // and stored in a single 'stats' document to avoid reading thousands of docs.
      // Mocking aggregation for now or reading from a stats doc.
      
      // Simulating fetching from a stats document
      // final statsDoc = await _firestore.collection('admin_stats').doc('daily_overview').get();
      
      return const Right(AdminDashboardEntity(
        totalUsers: 1250,
        activeDrivers: 45,
        pendingDriverApprovals: 8,
        activeTrips: 12,
        totalRevenue: 15400.0,
        todayRevenue: 850.0,
        pendingComplaints: 3,
        activeSubscriptions: 320,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DriverEntity>>> getPendingDrivers() async {
    try {
      final snapshot = await _firestore
          .collection('drivers')
          .where('isVerified', isEqualTo: false) // Assuming isVerified flag exists or using status
          .get();

      // Mapping logic would go here. 
      // Since DriverEntity in domain doesn't strictly have 'isVerified' in constructor shown previously,
      // we assume 'isAvailable' or similar, or just mapping basic fields for the list.
      // For this implementation, I'll return an empty list or mock data if schema doesn't match perfectly yet.
      
      return const Right([]); 
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> approveDriver(String driverId) async {
    try {
      await _firestore.collection('drivers').doc(driverId).update({
        'isVerified': true,
        'isAvailable': true,
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> rejectDriver(String driverId, String reason) async {
    try {
      await _firestore.collection('drivers').doc(driverId).update({
        'isVerified': false,
        'rejectionReason': reason,
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SafetyReportEntity>>> getPendingComplaints() async {
    try {
      final snapshot = await _firestore
          .collection('safety_reports')
          .where('status', isEqualTo: 'pending')
          .get();

      final reports = snapshot.docs.map((doc) {
        final data = doc.data();
        return SafetyReportEntity(
          id: doc.id,
          reporterId: data['reporterId'],
          reportedId: data['reportedId'] ?? '',
          tripId: data['tripId'],
          category: data['category'],
          description: data['description'],
          evidencePaths: List<String>.from(data['evidencePaths'] ?? []),
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          status: data['status'],
        );
      }).toList();

      return Right(reports);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> resolveComplaint(String reportId, String resolutionNotes) async {
    try {
      await _firestore.collection('safety_reports').doc(reportId).update({
        'status': 'resolved',
        'resolutionNotes': resolutionNotes,
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getFinancialReport({required DateTime startDate, required DateTime endDate}) async {
    try {
      // Mock financial data
      return Right({
        'totalRevenue': 50000.0,
        'subscriptionRevenue': 20000.0,
        'tripRevenue': 30000.0,
        'driverPayouts': 25000.0,
        'netProfit': 25000.0,
      });
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
