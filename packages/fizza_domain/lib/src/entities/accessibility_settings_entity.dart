import 'package:equatable/equatable.dart';

class AccessibilitySettingsEntity extends Equatable {
  final String userId;
  final bool isDeafMute;
  final bool requiresAssistant; // For elderly or kids
  final bool requiresWheelchair;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  const AccessibilitySettingsEntity({
    required this.userId,
    this.isDeafMute = false,
    this.requiresAssistant = false,
    this.requiresWheelchair = false,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  @override
  List<Object?> get props => [userId, isDeafMute, requiresAssistant, requiresWheelchair, emergencyContactName, emergencyContactPhone];
  
  AccessibilitySettingsEntity copyWith({
    String? userId,
    bool? isDeafMute,
    bool? requiresAssistant,
    bool? requiresWheelchair,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) {
    return AccessibilitySettingsEntity(
      userId: userId ?? this.userId,
      isDeafMute: isDeafMute ?? this.isDeafMute,
      requiresAssistant: requiresAssistant ?? this.requiresAssistant,
      requiresWheelchair: requiresWheelchair ?? this.requiresWheelchair,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
    );
  }
}
