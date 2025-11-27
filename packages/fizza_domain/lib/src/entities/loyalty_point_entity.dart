import 'package:equatable/equatable.dart';
import 'loyalty_event_type.dart';

class LoyaltyPointEntity extends Equatable {
  final String id;
  final String userId;
  final int amount;
  final LoyaltyEventType type;
  final String? referenceId; // rideId, subscriptionId, reportId
  final DateTime timestamp;

  const LoyaltyPointEntity({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    this.referenceId,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, userId, amount, type, referenceId, timestamp];
}
