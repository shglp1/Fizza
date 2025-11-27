import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';

// Events
abstract class TrackingEvent extends Equatable {
  const TrackingEvent();
  @override
  List<Object> get props => [];
}

class StartTracking extends TrackingEvent {
  final String driverId;
  const StartTracking(this.driverId);
  @override
  List<Object> get props => [driverId];
}

class StopTracking extends TrackingEvent {}

class UpdateDriverLocation extends TrackingEvent {
  final LocationEntity location;
  const UpdateDriverLocation(this.location);
  @override
  List<Object> get props => [location];
}

class TrackingErrorEvent extends TrackingEvent {
  final String message;
  const TrackingErrorEvent(this.message);
  @override
  List<Object> get props => [message];
}

// States
abstract class TrackingState extends Equatable {
  const TrackingState();
  @override
  List<Object> get props => [];
}

class TrackingInitial extends TrackingState {}
class TrackingLoading extends TrackingState {}
class TrackingActive extends TrackingState {
  final LocationEntity location;
  const TrackingActive(this.location);
  @override
  List<Object> get props => [location];
}
class TrackingError extends TrackingState {
  final String message;
  const TrackingError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
@injectable
class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  final ITrackingRepository _repository;
  StreamSubscription? _subscription;

  TrackingBloc(this._repository) : super(TrackingInitial()) {
    on<StartTracking>(_onStartTracking);
    on<UpdateDriverLocation>(_onUpdateDriverLocation);
    on<TrackingErrorEvent>(_onTrackingErrorEvent);
    on<StopTracking>(_onStopTracking);
  }

  Future<void> _onStartTracking(StartTracking event, Emitter<TrackingState> emit) async {
    emit(TrackingLoading());
    await _subscription?.cancel();
    _subscription = _repository.trackDriverLocation(event.driverId).listen(
      (result) {
        result.fold(
          (failure) => add(TrackingErrorEvent(failure.message)),
          (location) => add(UpdateDriverLocation(location)),
        );
      },
    );
  }

  Future<void> _onUpdateDriverLocation(UpdateDriverLocation event, Emitter<TrackingState> emit) async {
    emit(TrackingActive(event.location));
  }

  Future<void> _onTrackingErrorEvent(TrackingErrorEvent event, Emitter<TrackingState> emit) async {
    emit(TrackingError(event.message));
  }

  Future<void> _onStopTracking(StopTracking event, Emitter<TrackingState> emit) async {
    await _subscription?.cancel();
    emit(TrackingInitial());
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
