import 'package:equatable/equatable.dart';

class GamificationProfileEntity extends Equatable {
  final String userId;
  final int totalPoints;
  final int currentLevel;
  final List<String> badges; // List of badge IDs or names
  final int nextLevelThreshold;

  const GamificationProfileEntity({
    required this.userId,
    required this.totalPoints,
    required this.currentLevel,
    required this.badges,
    required this.nextLevelThreshold,
  });

  @override
  List<Object> get props => [userId, totalPoints, currentLevel, badges, nextLevelThreshold];
}
