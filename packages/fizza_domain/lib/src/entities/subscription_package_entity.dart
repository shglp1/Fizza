import 'package:equatable/equatable.dart';

class SubscriptionPackageEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationDays;
  final List<String> features;
  final int rideLimit;
  final double distanceLimitKm;
  final double extraRidePrice;
  final bool isTrial;
  final bool isFamilyPackage;
  final bool isFemaleOnly;
  final int maxFamilyMembers;

  const SubscriptionPackageEntity({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    required this.durationDays,
    required this.features,
    required this.rideLimit,
    required this.distanceLimitKm,
    required this.extraRidePrice,
    this.isTrial = false,
    this.isFamilyPackage = false,
    this.isFemaleOnly = false,
    this.maxFamilyMembers = 0,
    this.planType = 'monthly',
    this.discountPercentage = 0,
  });

  final String planType;
  final int discountPercentage;

  @override
  List<Object> get props => [
        id,
        name,
        description,
        price,
        durationDays,
        features,
        rideLimit,
        distanceLimitKm,
        extraRidePrice,
        isTrial,
        isFamilyPackage,
        isFemaleOnly,
        maxFamilyMembers,
        planType,
        discountPercentage,
      ];
}
