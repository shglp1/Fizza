import 'package:equatable/equatable.dart';
import 'location_entity.dart';

class RideRequestEntity extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final LocationEntity pickupLocation;
  final LocationEntity dropoffLocation;
  final String status;
  final DateTime timestamp;
  final bool isScheduled;
  final DateTime? scheduledTime;
  final List<String> addOns;
  final double estimatedFare;
  final double distanceKm;
  final double estimatedDuration; // in seconds

  const RideRequestEntity({
    required this.id,
    required this.userId,
    this.userName = '',
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.status,
    required this.timestamp,
    this.isScheduled = false,
    this.scheduledTime,
    this.addOns = const [],
    this.estimatedFare = 0.0,
    this.distanceKm = 0.0,
    this.estimatedDuration = 0.0,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        pickupLocation,
        dropoffLocation,
        status,
        timestamp,
        isScheduled,
        scheduledTime,
        addOns,
        estimatedFare,
        distanceKm,
        estimatedDuration,
      ];
}
