
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
  final bool isFamily;
  final String? parentUserId; // If this is a family member subscription
  final String? beneficiaryId; // The specific child/dependent using this subscription
  final List<String> addOnIds; // Selected add-ons
  final bool isFemaleOnly;
  final String renewalStatus; // 'active', 'pending', 'cancelled'

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
    this.isFamily = false,
    this.parentUserId,
    this.beneficiaryId,
    this.addOnIds = const [],
    this.isFemaleOnly = false,
    this.renewalStatus = 'active',
    this.planType = 'monthly', // monthly, 3_months, 6_months, yearly
    this.discountAmount = 0.0,
    this.cancelReason,
  });

  final String planType;
  final double discountAmount;
  final String? cancelReason;

  @override
  List<Object?> get props => [
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
        isFamily,
        parentUserId,
        beneficiaryId,
        addOnIds,
        isFemaleOnly,
        renewalStatus,
        planType,
        discountAmount,
        cancelReason,
      ];
}
