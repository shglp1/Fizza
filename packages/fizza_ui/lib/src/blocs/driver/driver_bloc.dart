import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';

// Events
abstract class DriverEvent extends Equatable {
  const DriverEvent();
  @override
  List<Object> get props => [];
}

class LoadDriverProfile extends DriverEvent {
  final String userId;
  const LoadDriverProfile(this.userId);
  @override
  List<Object> get props => [userId];
}

class ToggleOnlineStatus extends DriverEvent {
  final String driverId;
  final bool isOnline;
  const ToggleOnlineStatus(this.driverId, this.isOnline);
  @override
  List<Object> get props => [driverId, isOnline];
}

class LoadEarnings extends DriverEvent {
  final String driverId;
  const LoadEarnings(this.driverId);
  @override
  List<Object> get props => [driverId];
}

// States
abstract class DriverState extends Equatable {
  const DriverState();
  @override
  List<Object?> get props => [];
}

class DriverInitial extends DriverState {}
class DriverLoading extends DriverState {}
class DriverProfileLoaded extends DriverState {
  final DriverEntity driver;
  const DriverProfileLoaded(this.driver);
  @override
  List<Object> get props => [driver];
}
class DriverEarningsLoaded extends DriverState {
  final EarningsEntity earnings;
  const DriverEarningsLoaded(this.earnings);
  @override
  List<Object> get props => [earnings];
}
class DriverError extends DriverState {
  final String message;
  const DriverError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
@injectable
class DriverBloc extends Bloc<DriverEvent, DriverState> {
  final IDriverRepository _repository;

  DriverBloc(this._repository) : super(DriverInitial()) {
    on<LoadDriverProfile>(_onLoadDriverProfile);
    on<ToggleOnlineStatus>(_onToggleOnlineStatus);
    on<LoadEarnings>(_onLoadEarnings);
  }

  Future<void> _onLoadDriverProfile(LoadDriverProfile event, Emitter<DriverState> emit) async {
    emit(DriverLoading());
    final result = await _repository.getDriverProfile(event.userId);
    result.fold(
      (failure) => emit(DriverError(failure.message)),
      (driver) => emit(DriverProfileLoaded(driver)),
    );
  }

  Future<void> _onToggleOnlineStatus(ToggleOnlineStatus event, Emitter<DriverState> emit) async {
    // Optimistic update or loading? Let's do loading for safety.
    // Ideally we should keep the current profile loaded and just update status.
    // For simplicity, I'll emit loading then reload profile.
    emit(DriverLoading());
    final result = await _repository.toggleOnlineStatus(event.driverId, event.isOnline);
    result.fold(
      (failure) => emit(DriverError(failure.message)),
      (_) => add(LoadDriverProfile(event.driverId)), // Reload to get updated status
    );
  }

  Future<void> _onLoadEarnings(LoadEarnings event, Emitter<DriverState> emit) async {
    emit(DriverLoading());
    final result = await _repository.getEarnings(event.driverId);
    result.fold(
      (failure) => emit(DriverError(failure.message)),
      (earnings) => emit(DriverEarningsLoaded(earnings)),
    );
  }
}
