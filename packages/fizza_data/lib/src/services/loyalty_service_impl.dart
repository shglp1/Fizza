import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';
import '../datasources/system_config_datasource.dart';

@LazySingleton(as: ILoyaltyService)
class LoyaltyServiceImpl implements ILoyaltyService {
  final FirebaseFirestore _firestore;
  final ISystemConfigDataSource _configDataSource;

  LoyaltyServiceImpl(this._firestore, this._configDataSource);

  @override
  Future<Either<Failure, Unit>> awardPointsForRide({
    required String userId,
    required double distanceKm,
    required bool isFemaleDriver,
  }) async {
    try {
      final config = await _configDataSource.getConfig();
      int points = config.loyalty.pointsPerRide;
      
      if (isFemaleDriver) {
        points += config.loyalty.pointsFemaleDriver;
      }

      await _awardPoints(userId, points, 'Ride Completion');
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> awardPointsForSubscription({
    required String userId,
    required SubscriptionPackageEntity package,
  }) async {
    try {
      final config = await _configDataSource.getConfig();
      
      // Determine if long-term (e.g., > 30 days)
      final isLongTerm = package.durationDays > 30;
      
      int points = isLongTerm 
          ? config.loyalty.pointsLongTermSub 
          : config.loyalty.pointsMonthlySub;

      await _awardPoints(userId, points, 'Subscription: ${package.name}');
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  // Note: This method intentionally ignores the basePoints argument.
  //       All loyalty point amounts come from SystemConfig, which is the
  //       single source of truth. Callers should not pass hard-coded values.
  Future<Either<Failure, Unit>> awardPointsForSafetyReport({
    required String userId,
    required int basePoints,
  }) async {
    try {
      // basePoints usually comes from config passed by caller, or we can fetch config here.
      // The prompt implies we should use config.loyalty.pointsSafetyReport.
      // But the interface asks for basePoints. Let's ignore basePoints arg if we want to enforce config,
      // or use it if the caller already fetched it. 
      // To be safe and centralized, let's fetch config here.
      
      final config = await _configDataSource.getConfig();
      final points = config.loyalty.pointsSafetyReport;

      await _awardPoints(userId, points, 'Safety Report Reward');
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<void> _awardPoints(String userId, int points, String description) async {
    if (points <= 0) return;

    final userRef = _firestore.collection('users').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) return;

      transaction.update(userRef, {
        'loyaltyPoints': FieldValue.increment(points),
      });
      
      // Optional: Add to history
      /*
      final historyRef = userRef.collection('loyalty_history').doc();
      transaction.set(historyRef, {
        'points': points,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
      });
      */
    });
  }
}
