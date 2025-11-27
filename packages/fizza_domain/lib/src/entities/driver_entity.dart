import 'package:equatable/equatable.dart';

class DriverEntity extends Equatable {
  final String id;
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
  final bool isSuspended;
  final String? suspensionReason;

  const DriverEntity({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.vehicleModel,
    required this.vehiclePlate,
    this.vehicleYear = 2020,
    this.isOnline = false,
    this.isAvailable = false,
    this.commissionRate = 0.12,
    this.rating = 5.0,
    this.ratingCount = 0,
    this.isSuspended = false,
    this.suspensionReason,
  });

  @override
  List<Object?> get props => [
        id,
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
        isSuspended,
        suspensionReason,
      ];
}
