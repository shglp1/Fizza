import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import '../entities/subscription_package_entity.dart';
import '../entities/user_subscription_entity.dart';
import '../entities/add_on_entity.dart';

abstract class ISubscriptionRepository {
  Future<Either<Failure, List<SubscriptionPackageEntity>>> getAvailablePackages();
  Future<Either<Failure, UserSubscriptionEntity?>> getCurrentSubscription(String userId);
  Future<Either<Failure, Unit>> subscribeToPackage({
    required String userId,
    required SubscriptionPackageEntity package,
    required String paymentMethodId, // 'wallet' or gateway token
    List<AddOnEntity> addOns = const [],
    bool isFamily = false,
    String? parentUserId,
    String? beneficiaryId,
  });
  Future<Either<Failure, Unit>> cancelSubscription(String subscriptionId);
  
  /// Returns true if valid, or Left(Failure) if limit reached/expired.
  /// If allowOverage is true, it might return Right(true) even if limit reached but extra charge applies.
  Future<Either<Failure, bool>> checkSubscriptionStatus(String userId);
  Future<Either<Failure, Unit>> toggleAutoRenew(String subscriptionId, bool enabled);
}
