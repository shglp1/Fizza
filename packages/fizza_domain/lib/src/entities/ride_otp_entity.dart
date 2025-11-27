import 'package:equatable/equatable.dart';

class RideOtpEntity extends Equatable {
  final String rideId;
  final String otpCode; // 4-digit code
  final String qrCodeData; // Encrypted string for QR
  final DateTime expiryTime;

  const RideOtpEntity({
    required this.rideId,
    required this.otpCode,
    required this.qrCodeData,
    required this.expiryTime,
  });

  @override
  List<Object> get props => [rideId, otpCode, qrCodeData, expiryTime];
}
