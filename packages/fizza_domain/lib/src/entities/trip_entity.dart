import 'package:equatable/equatable.dart';

class TripEntity extends Equatable {
  final String id;
  final String userId;
  final String driverId;
  final String? familyMemberId; // If the ride is for a child
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime scheduledTime;
  final String status; // 'scheduled', 'ongoing', 'completed', 'cancelled'
  final double cost;
  final bool isFemaleDriverRequested;
  final bool isAssistantRequested;

  const TripEntity({
    required this.id,
    required this.userId,
    required this.driverId,
    this.familyMemberId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.scheduledTime,
    required this.status,
    required this.cost,
    this.isFemaleDriverRequested = false,
    this.isAssistantRequested = false,
  });

  @override
  List<Object?> get props => [
    id, userId, driverId, familyMemberId, pickupLocation, dropoffLocation, 
    scheduledTime, status, cost, isFemaleDriverRequested, isAssistantRequested
  ];
}
