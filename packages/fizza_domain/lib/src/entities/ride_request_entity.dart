import 'package:equatable/equatable.dart';
import 'location_entity.dart';

class RideRequestEntity extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final LocationEntity pickupLocation;
  final LocationEntity dropoffLocation;
  final double estimatedFare;
  final double estimatedDistance;
  final double estimatedDuration; // in seconds
  final DateTime timestamp;

  const RideRequestEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.estimatedFare,
    required this.estimatedDistance,
    required this.estimatedDuration,
    required this.timestamp,
  });

  @override
  List<Object> get props => [id, userId, userName, pickupLocation, dropoffLocation, estimatedFare, estimatedDistance, estimatedDuration, timestamp];
}
