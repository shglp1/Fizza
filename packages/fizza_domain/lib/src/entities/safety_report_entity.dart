import 'package:equatable/equatable.dart';

class SafetyReportEntity extends Equatable {
  final String id;
  final String reporterId; // User or Driver ID
  final String reportedId; // The other party ID (optional)
  final String tripId;
  final String category; // e.g., "Reckless Driving", "Lost Item"
  final String description;
  final List<String> evidencePaths; // URLs to photos/videos
  final DateTime timestamp;
  final String status; // "pending", "resolved"
  final String? approvedBy;
  final DateTime? approvedAt;
  final int pointsAwarded;
  final bool isValid;
  final bool rewardPointsGranted;

  const SafetyReportEntity({
    required this.id,
    required this.reporterId,
    this.reportedId = '',
    required this.tripId,
    required this.category,
    required this.description,
    this.evidencePaths = const [],
    required this.timestamp,
    this.status = 'pending',
    this.isValid = false,
    this.rewardPointsGranted = false,
    this.approvedBy,
    this.approvedAt,
    this.pointsAwarded = 0,
  });

  @override
  List<Object?> get props => [
        id,
        reporterId,
        reportedId,
        tripId,
        category,
        description,
        evidencePaths,
        timestamp,
        status,
        isValid,
        rewardPointsGranted,
        approvedBy,
        approvedAt,
        pointsAwarded,
      ];
}
