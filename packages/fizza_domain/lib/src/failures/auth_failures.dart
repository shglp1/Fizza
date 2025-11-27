import 'package:fizza_core/fizza_core.dart';

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class InvalidPhoneNumberFailure extends AuthFailure {
  const InvalidPhoneNumberFailure() : super('Invalid phone number');
}

class InvalidOtpFailure extends AuthFailure {
  const InvalidOtpFailure() : super('Invalid OTP');
}
