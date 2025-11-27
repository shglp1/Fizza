import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import '../entities/subscription_package_entity.dart';
import '../entities/user_subscription_entity.dart';

abstract class ISubscriptionRepository {
  Future<Either<Failure, List<SubscriptionPackageEntity>>> getAvailablePackages();
  Future<Either<Failure, UserSubscriptionEntity?>> getCurrentSubscription(String userId);
  Future<Either<Failure, Unit>> subscribeToPackage({
    required String userId,
    required SubscriptionPackageEntity package,
    required String paymentMethodId, // Mock payment
  });
  Future<Either<Failure, Unit>> cancelSubscription(String subscriptionId);
  Future<Either<Failure, Unit>> toggleAutoRenew(String subscriptionId, bool enabled);
}
