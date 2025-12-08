import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';

abstract class INotificationService {
  Future<Either<Failure, Unit>> notifyTripStarted(String userId, String tripId);
  Future<Either<Failure, Unit>> notifyTripCompleted(String userId, String tripId);
  Future<Either<Failure, Unit>> notifyDriverNoShow(String userId, String tripId);
  Future<Either<Failure, Unit>> notifySubscriptionExpiring(String userId, String subscriptionId);
  Future<Either<Failure, Unit>> notifyWalletTopUp(String userId, double amount);
}
