import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import '../entities/location_entity.dart';
import '../entities/route_entity.dart';

abstract class IMapsRepository {
  Future<Either<Failure, LocationEntity>> getCurrentLocation();
  Future<Either<Failure, List<LocationEntity>>> searchPlaces(String query);
  Future<Either<Failure, RouteEntity>> getRoute(LocationEntity origin, LocationEntity destination);
  Future<Either<Failure, String>> getAddressFromCoordinates(double lat, double lng);
}

abstract class ITrackingRepository {
  Future<Either<Failure, Unit>> updateDriverLocation(String driverId, LocationEntity location);
  Stream<Either<Failure, LocationEntity>> trackDriverLocation(String driverId);
}
