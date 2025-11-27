import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fizza_core/fizza_core.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';
import '../datasources/auth_datasource.dart';

@LazySingleton(as: IAuthRepository)
class AuthRepositoryImpl implements IAuthRepository {
  final IAuthDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Future<Either<AuthFailure, Unit>> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String p1, int? p2) onCodeSent,
    required Function(AuthFailure p1) onVerificationFailed,
    required Function(String p1) onCodeAutoRetrievalTimeout,
  }) async {
    try {
      await _dataSource.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Auto-resolution logic if needed
        },
        verificationFailed: (FirebaseAuthException e) {
          onVerificationFailed(AuthFailure(e.message ?? 'Verification failed'));
        },
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      );
      return const Right(unit);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, UserEntity>> signInWithCredential({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await _dataSource.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        return const Left(AuthFailure('User is null'));
      }
      return Right(_mapFirebaseUserToEntity(user));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, UserEntity>> getCurrentUser() async {
    try {
      final user = _dataSource.currentUser;
      if (user != null) {
        return Right(_mapFirebaseUserToEntity(user));
      } else {
        return const Left(AuthFailure('No user logged in'));
      }
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Right(unit);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  UserEntity _mapFirebaseUserToEntity(User user) {
    return UserEntity(
      id: user.uid,
      phoneNumber: user.phoneNumber,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      role: 'user', // Default role, will need to fetch from Firestore later
    );
  }
}
