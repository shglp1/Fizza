import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import '../entities/user_entity.dart';
import '../failures/auth_failures.dart';

abstract class IAuthRepository {
  Future<Either<AuthFailure, Unit>> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String, int?) onCodeSent,
    required Function(AuthFailure) onVerificationFailed,
    required Function(String) onCodeAutoRetrievalTimeout,
  });

  Future<Either<AuthFailure, UserEntity>> signInWithCredential({
    required String verificationId,
    required String smsCode,
  });

  Future<Either<AuthFailure, UserEntity>> getCurrentUser();
  
  Future<Either<AuthFailure, Unit>> signOut();
}
