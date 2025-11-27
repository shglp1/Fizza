import 'package:equatable/equatable.dart';

class EarningsEntity extends Equatable {
  final String driverId;
  final double todayEarnings;
  final double weekEarnings;
  final double totalEarnings;
  final int todayRides;
  final int weekRides;

  const EarningsEntity({
    required this.driverId,
    required this.todayEarnings,
    required this.weekEarnings,
    required this.totalEarnings,
    required this.todayRides,
    required this.weekRides,
  });

  @override
  List<Object> get props => [driverId, todayEarnings, weekEarnings, totalEarnings, todayRides, weekRides];
}
