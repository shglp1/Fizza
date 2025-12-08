import 'package:equatable/equatable.dart';

class AdminDashboardEntity extends Equatable {
  final int totalUsers;
  final int activeDrivers;
  final int pendingDriverApprovals;
  final int activeTrips;
  final double totalRevenue;
  final double todayRevenue;
  final int pendingComplaints;
  final int activeSubscriptions;
  final String? worstDriverId;

  const AdminDashboardEntity({
    required this.totalUsers,
    required this.activeDrivers,
    required this.pendingDriverApprovals,
    required this.activeTrips,
    required this.totalRevenue,
    required this.todayRevenue,
    required this.pendingComplaints,
    required this.activeSubscriptions,
    this.worstDriverId,
  });

  @override
  List<Object?> get props => [
        totalUsers,
        activeDrivers,
        pendingDriverApprovals,
        activeTrips,
        totalRevenue,
        todayRevenue,
        pendingComplaints,
        activeSubscriptions,
        worstDriverId,
      ];
}
