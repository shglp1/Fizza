import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: INotificationService)
class NotificationServiceImpl implements INotificationService {
  @override
  Future<Either<Failure, Unit>> notifyTripStarted(String userId, String tripId) async {
    // No-op for v3.3
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> notifyTripCompleted(String userId, String tripId) async {
    // No-op for v3.3
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> notifyDriverNoShow(String userId, String tripId) async {
    // No-op for v3.3
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> notifySubscriptionExpiring(String userId, String subscriptionId) async {
    // No-op for v3.3
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> notifyWalletTopUp(String userId, double amount) async {
    // No-op for v3.3
    return const Right(unit);
  }
}
