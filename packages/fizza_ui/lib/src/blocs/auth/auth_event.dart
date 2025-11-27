import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthStarted extends AuthEvent {}

class AuthPhoneSubmitted extends AuthEvent {
  final String phoneNumber;
  const AuthPhoneSubmitted(this.phoneNumber);
  @override
  List<Object> get props => [phoneNumber];
}

class AuthOtpSubmitted extends AuthEvent {
  final String verificationId;
  final String smsCode;
  const AuthOtpSubmitted({required this.verificationId, required this.smsCode});
  @override
  List<Object> get props => [verificationId, smsCode];
}

class AuthLoggedOut extends AuthEvent {}

class AuthCodeSentEvent extends AuthEvent {
  final String verificationId;
  const AuthCodeSentEvent(this.verificationId);
  @override
  List<Object> get props => [verificationId];
}

class AuthErrorEvent extends AuthEvent {
  final String message;
  const AuthErrorEvent(this.message);
  @override
  List<Object> get props => [message];
}
