import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import '../entities/subscription_package_entity.dart';

abstract class ILoyaltyService {
  Future<Either<Failure, Unit>> awardPointsForRide({
    required String userId,
    required double distanceKm,
    required bool isFemaleDriver,
  });

  Future<Either<Failure, Unit>> awardPointsForSubscription({
    required String userId,
    required SubscriptionPackageEntity package,
  });

  Future<Either<Failure, Unit>> awardPointsForSafetyReport({
    required String userId,
    required int basePoints,
  });
}
