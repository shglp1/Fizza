import 'package:equatable/equatable.dart';

class LocationEntity extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;
  final double? heading;

  const LocationEntity({
    required this.latitude,
    required this.longitude,
    this.address,
    this.heading,
  });

  @override
  List<Object?> get props => [latitude, longitude, address, heading];
}
