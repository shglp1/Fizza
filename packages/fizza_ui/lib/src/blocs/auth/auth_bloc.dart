import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';
import 'auth_event.dart';
import 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final IAuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthPhoneSubmitted>(_onAuthPhoneSubmitted);
    on<AuthCodeSentEvent>(_onAuthCodeSent);
    on<AuthOtpSubmitted>(_onAuthOtpSubmitted);
    on<AuthErrorEvent>(_onAuthError);
    on<AuthLoggedOut>(_onAuthLoggedOut);
  }

  Future<void> _onAuthStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _authRepository.getCurrentUser();
    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onAuthPhoneSubmitted(AuthPhoneSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _authRepository.verifyPhoneNumber(
      phoneNumber: event.phoneNumber,
      onCodeSent: (verificationId, resendToken) {
        add(AuthCodeSentEvent(verificationId));
      },
      onVerificationFailed: (failure) {
        add(AuthErrorEvent(failure.message));
      },
      onCodeAutoRetrievalTimeout: (verificationId) {
        // Optional: Handle timeout
      },
    );
  }

  Future<void> _onAuthCodeSent(AuthCodeSentEvent event, Emitter<AuthState> emit) async {
    emit(AuthCodeSent(event.verificationId));
  }

  Future<void> _onAuthOtpSubmitted(AuthOtpSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _authRepository.signInWithCredential(
      verificationId: event.verificationId,
      smsCode: event.smsCode,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onAuthError(AuthErrorEvent event, Emitter<AuthState> emit) async {
    emit(AuthError(event.message));
  }

  Future<void> _onAuthLoggedOut(AuthLoggedOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _authRepository.signOut();
    emit(AuthUnauthenticated());
  }
}
