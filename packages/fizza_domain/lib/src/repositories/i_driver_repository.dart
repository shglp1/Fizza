import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import '../entities/driver_entity.dart';
import '../entities/ride_request_entity.dart';
import '../entities/earnings_entity.dart';

abstract class IDriverRepository {
  Future<Either<Failure, DriverEntity>> getDriverProfile(String userId);
  Future<Either<Failure, Unit>> toggleOnlineStatus(String driverId, bool isOnline);
  Future<Either<Failure, EarningsEntity>> getEarnings(String driverId);
  Stream<Either<Failure, List<RideRequestEntity>>> getRideRequests(String driverId);
  Future<Either<Failure, Unit>> acceptRideRequest(String driverId, String requestId);
  Future<Either<Failure, Unit>> rejectRideRequest(String driverId, String requestId);
}
