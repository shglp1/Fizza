import 'package:equatable/equatable.dart';

class UserSubscriptionEntity extends Equatable {
  final String id;
  final String userId;
  final String packageId;
  final DateTime startDate;
  final DateTime endDate;
  final int ridesRemaining;
  final bool isActive;
  final bool autoRenew;

  const UserSubscriptionEntity({
    required this.id,
    required this.userId,
    required this.packageId,
    required this.startDate,
    required this.endDate,
    required this.ridesRemaining,
    required this.isActive,
    required this.autoRenew,
  });

  @override
  List<Object> get props => [id, userId, packageId, startDate, endDate, ridesRemaining, isActive, autoRenew];
}
