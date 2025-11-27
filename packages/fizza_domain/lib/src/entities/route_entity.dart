import 'package:equatable/equatable.dart';
import 'location_entity.dart';

class RouteEntity extends Equatable {
  final List<LocationEntity> points;
  final double distanceMeters;
  final double durationSeconds;
  final String encodedPolyline;

  const RouteEntity({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.encodedPolyline,
  });

  @override
  List<Object> get props => [points, distanceMeters, durationSeconds, encodedPolyline];
}
