import 'package:equatable/equatable.dart';
import 'location_entity.dart';

class RideRequestEntity extends Equatable {
  final String id;
  final String userId;
  final LocationEntity pickupLocation;
  final LocationEntity dropoffLocation;
  final String status;
  final DateTime timestamp;
  final bool isScheduled;
  final DateTime? scheduledTime;
  final List<String> addOns;
  final double estimatedFare;
  final double distanceKm;

  const RideRequestEntity({
    required this.id,
    required this.userId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.status,
    required this.timestamp,
    this.isScheduled = false,
    this.scheduledTime,
    this.addOns = const [],
    this.estimatedFare = 0.0,
    this.distanceKm = 0.0,
  });

  @override
  List<Object?> get props => [id, userId, pickupLocation, dropoffLocation, status, timestamp, isScheduled, scheduledTime, addOns, estimatedFare, distanceKm];
}
