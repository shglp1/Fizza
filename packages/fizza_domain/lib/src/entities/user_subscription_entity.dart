import 'package:equatable/equatable.dart';

class UserSubscriptionEntity extends Equatable {
  final String id;
  final String userId;
  final String packageId;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool autoRenew;
  final int ridesUsed;
  final int extraRidesCharged;
  final int ridesRemaining; // Calculated or stored

  const UserSubscriptionEntity({
    required this.id,
    required this.userId,
    required this.packageId,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.autoRenew,
    this.ridesUsed = 0,
    this.extraRidesCharged = 0,
    this.ridesRemaining = 0,
  });

  @override
  List<Object> get props => [
        id,
        userId,
        packageId,
        startDate,
        endDate,
        isActive,
        autoRenew,
        ridesUsed,
        extraRidesCharged,
        ridesRemaining,
      ];
}
