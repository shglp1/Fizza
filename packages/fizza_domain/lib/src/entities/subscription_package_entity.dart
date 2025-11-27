import 'package:equatable/equatable.dart';

class SubscriptionPackageEntity extends Equatable {
  final String id;
  final String name;
  final double price;
  final int durationDays;
  final List<String> features;
  final int rideLimit;
  final double distanceLimitKm;
  final double extraRidePrice;
  final bool isTrial;

  const SubscriptionPackageEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.features,
    required this.rideLimit,
    required this.distanceLimitKm,
    required this.extraRidePrice,
    this.isTrial = false,
  });

  @override
  List<Object> get props => [id, name, price, durationDays, features, rideLimit, distanceLimitKm, extraRidePrice, isTrial];
}
