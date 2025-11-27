import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import '../entities/ride_otp_entity.dart';
import '../entities/safety_report_entity.dart';
import '../entities/accessibility_settings_entity.dart';

abstract class ISafetyRepository {
  // OTP/QR
  Future<Either<Failure, RideOtpEntity>> generateRideOtp(String rideId);
  Future<Either<Failure, bool>> validateRideOtp(String rideId, String code);

  // Reporting
  Future<Either<Failure, Unit>> submitReport(SafetyReportEntity report);
  Future<Either<Failure, List<SafetyReportEntity>>> getUserReports(String userId);

  // Accessibility
  Future<Either<Failure, AccessibilitySettingsEntity>> getAccessibilitySettings(String userId);
  Future<Either<Failure, Unit>> updateAccessibilitySettings(AccessibilitySettingsEntity settings);
}
