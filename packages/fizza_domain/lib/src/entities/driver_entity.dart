import 'package:equatable/equatable.dart';
import 'location_entity.dart';

class DriverEntity extends Equatable {
  final String id;
  final String userId;
  final bool isOnline;
  final bool isAvailable; // Not in a ride
  final LocationEntity? currentLocation;
  final String vehicleType;
  final String vehiclePlateNumber;
  final double rating;
  final int totalRides;

  const DriverEntity({
    required this.id,
    required this.userId,
    required this.isOnline,
    required this.isAvailable,
    this.currentLocation,
    required this.vehicleType,
    required this.vehiclePlateNumber,
    required this.rating,
    required this.totalRides,
  });

  @override
  List<Object?> get props => [id, userId, isOnline, isAvailable, currentLocation, vehicleType, vehiclePlateNumber, rating, totalRides];
}
