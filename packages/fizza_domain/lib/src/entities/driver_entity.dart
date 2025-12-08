import 'package:equatable/equatable.dart';
import 'location_entity.dart';

enum DriverTier {
  standard,
  vip,
  female,
}

class DriverEntity extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String phoneNumber;
  final String vehicleModel;
  final String vehiclePlate;
  final int vehicleYear;
  final bool isOnline;
  final bool isAvailable;
  final double commissionRate;
  final double rating;
  final int ratingCount;
  final int totalRides;
  final bool isSuspended;
  final String? suspensionReason;
  final LocationEntity? currentLocation;
  final DriverTier tier;

  const DriverEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.vehicleModel,
    required this.vehiclePlate,
    this.vehicleYear = 2018,
    this.isOnline = false,
    this.isAvailable = false,
    this.commissionRate = 0.15,
    this.rating = 5.0,
    this.ratingCount = 0,
    this.totalRides = 0,
    this.isSuspended = false,
    this.suspensionReason,
    this.currentLocation,
    this.tier = DriverTier.standard,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        phoneNumber,
        vehicleModel,
        vehiclePlate,
        vehicleYear,
        isOnline,
        isAvailable,
        commissionRate,
        rating,
        ratingCount,
        totalRides,
        isSuspended,
        suspensionReason,
        currentLocation,
        tier,
      ];
}
