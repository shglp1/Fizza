import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';

// Events
abstract class SafetyEvent extends Equatable {
  const SafetyEvent();
  @override
  List<Object> get props => [];
}

class GenerateOtp extends SafetyEvent {
  final String rideId;
  const GenerateOtp(this.rideId);
  @override
  List<Object> get props => [rideId];
}

class ValidateOtp extends SafetyEvent {
  final String rideId;
  final String code;
  const ValidateOtp(this.rideId, this.code);
  @override
  List<Object> get props => [rideId, code];
}

class SubmitSafetyReport extends SafetyEvent {
  final SafetyReportEntity report;
  const SubmitSafetyReport(this.report);
  @override
  List<Object> get props => [report];
}

class LoadUserReports extends SafetyEvent {
  final String userId;
  const LoadUserReports(this.userId);
  @override
  List<Object> get props => [userId];
}

// States
abstract class SafetyState extends Equatable {
  const SafetyState();
  @override
  List<Object> get props => [];
}

class SafetyInitial extends SafetyState {}
class SafetyLoading extends SafetyState {}
class SafetyOtpGenerated extends SafetyState {
  final RideOtpEntity otp;
  const SafetyOtpGenerated(this.otp);
  @override
  List<Object> get props => [otp];
}
class SafetyOtpValidated extends SafetyState {
  final bool isValid;
  const SafetyOtpValidated(this.isValid);
  @override
  List<Object> get props => [isValid];
}
class SafetyReportSubmitted extends SafetyState {}
class SafetyReportsLoaded extends SafetyState {
  final List<SafetyReportEntity> reports;
  const SafetyReportsLoaded(this.reports);
  @override
  List<Object> get props => [reports];
}
class SafetyError extends SafetyState {
  final String message;
  const SafetyError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
@injectable
class SafetyBloc extends Bloc<SafetyEvent, SafetyState> {
  final ISafetyRepository _repository;

  SafetyBloc(this._repository) : super(SafetyInitial()) {
    on<GenerateOtp>(_onGenerateOtp);
    on<ValidateOtp>(_onValidateOtp);
    on<SubmitSafetyReport>(_onSubmitReport);
    on<LoadUserReports>(_onLoadUserReports);
  }

  Future<void> _onGenerateOtp(GenerateOtp event, Emitter<SafetyState> emit) async {
    emit(SafetyLoading());
    final result = await _repository.generateRideOtp(event.rideId);
    result.fold(
      (failure) => emit(SafetyError(failure.message)),
      (otp) => emit(SafetyOtpGenerated(otp)),
    );
  }

  Future<void> _onValidateOtp(ValidateOtp event, Emitter<SafetyState> emit) async {
    emit(SafetyLoading());
    final result = await _repository.validateRideOtp(event.rideId, event.code);
    result.fold(
      (failure) => emit(SafetyError(failure.message)),
      (isValid) => emit(SafetyOtpValidated(isValid)),
    );
  }

  Future<void> _onSubmitReport(SubmitSafetyReport event, Emitter<SafetyState> emit) async {
    emit(SafetyLoading());
    final result = await _repository.submitReport(event.report);
    result.fold(
      (failure) => emit(SafetyError(failure.message)),
      (_) => emit(SafetyReportSubmitted()),
    );
  }

  Future<void> _onLoadUserReports(LoadUserReports event, Emitter<SafetyState> emit) async {
    emit(SafetyLoading());
    final result = await _repository.getUserReports(event.userId);
    result.fold(
      (failure) => emit(SafetyError(failure.message)),
      (reports) => emit(SafetyReportsLoaded(reports)),
    );
  }
}
