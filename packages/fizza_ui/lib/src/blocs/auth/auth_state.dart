import 'package:equatable/equatable.dart';
import 'package:fizza_domain/fizza_domain.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthCodeSent extends AuthState {
  final String verificationId;
  const AuthCodeSent(this.verificationId);
  @override
  List<Object?> get props => [verificationId];
}
