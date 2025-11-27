import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ISafetyRepository)
class SafetyRepositoryImpl implements ISafetyRepository {
  final FirebaseFirestore _firestore;

  SafetyRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, RideOtpEntity>> generateRideOtp(String rideId) async {
    try {
      // Generate 4-digit code
      final code = (1000 + Random().nextInt(9000)).toString();
      final expiry = DateTime.now().add(const Duration(minutes: 15));
      final qrData = 'fizza_ride:$rideId:$code'; // Simple encoding

      await _firestore.collection('rides').doc(rideId).update({
        'otp': {
          'code': code,
          'expiry': Timestamp.fromDate(expiry),
          'qrData': qrData,
        }
      });

      return Right(RideOtpEntity(
        rideId: rideId,
        otpCode: code,
        qrCodeData: qrData,
        expiryTime: expiry,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> validateRideOtp(String rideId, String code) async {
    try {
      final doc = await _firestore.collection('rides').doc(rideId).get();
      if (!doc.exists) return const Left(ServerFailure('Ride not found'));
      
      final data = doc.data()!;
      if (data['otp'] == null) return const Left(ServerFailure('No OTP generated for this ride'));

      final storedCode = data['otp']['code'];
      final expiry = (data['otp']['expiry'] as Timestamp).toDate();

      if (DateTime.now().isAfter(expiry)) {
        return const Left(ServerFailure('OTP expired'));
      }

      if (storedCode == code) {
        // Mark ride as started
        await _firestore.collection('rides').doc(rideId).update({
          'status': 'started',
          'startedAt': FieldValue.serverTimestamp(),
        });
        return const Right(true);
      } else {
        return const Right(false);
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> submitReport(SafetyReportEntity report) async {
    try {
      await _firestore.collection('safety_reports').add({
        'reporterId': report.reporterId,
        'reportedId': report.reportedId,
        'tripId': report.tripId,
        'category': report.category,
        'description': report.description,
        'evidencePaths': report.evidencePaths,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      
      // Trigger "Earn" logic (add points)
      // In real app, this might be a Cloud Function trigger
      await _firestore.collection('users').doc(report.reporterId).update({
        'loyaltyPoints': FieldValue.increment(10), // 10 points for reporting
      });

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SafetyReportEntity>>> getUserReports(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('safety_reports')
          .where('reporterId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      final reports = snapshot.docs.map((doc) {
        final data = doc.data();
        return SafetyReportEntity(
          id: doc.id,
          reporterId: data['reporterId'],
          reportedId: data['reportedId'] ?? '',
          tripId: data['tripId'],
          category: data['category'],
          description: data['description'],
          evidencePaths: List<String>.from(data['evidencePaths'] ?? []),
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          status: data['status'] ?? 'pending',
        );
      }).toList();

      return Right(reports);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AccessibilitySettingsEntity>> getAccessibilitySettings(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return const Left(ServerFailure('User not found'));

      final data = doc.data()!;
      final settings = data['accessibility'] ?? {};

      return Right(AccessibilitySettingsEntity(
        userId: userId,
        isDeafMute: settings['isDeafMute'] ?? false,
        requiresAssistant: settings['requiresAssistant'] ?? false,
        requiresWheelchair: settings['requiresWheelchair'] ?? false,
        emergencyContactName: settings['emergencyContactName'],
        emergencyContactPhone: settings['emergencyContactPhone'],
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateAccessibilitySettings(AccessibilitySettingsEntity settings) async {
    try {
      await _firestore.collection('users').doc(settings.userId).update({
        'accessibility': {
          'isDeafMute': settings.isDeafMute,
          'requiresAssistant': settings.requiresAssistant,
          'requiresWheelchair': settings.requiresWheelchair,
          'emergencyContactName': settings.emergencyContactName,
          'emergencyContactPhone': settings.emergencyContactPhone,
        }
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
