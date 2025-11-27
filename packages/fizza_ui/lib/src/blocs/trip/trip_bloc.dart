import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';

// Events
abstract class TripEvent extends Equatable {
  const TripEvent();
  @override
  List<Object> get props => [];
}

class LoadTripHistory extends TripEvent {
  final String userId;
  const LoadTripHistory(this.userId);
  @override
  List<Object> get props => [userId];
}

class ScheduleTrip extends TripEvent {
  final TripEntity trip;
  const ScheduleTrip(this.trip);
  @override
  List<Object> get props => [trip];
}

class CancelTrip extends TripEvent {
  final String tripId;
  final String userId; // To reload history
  const CancelTrip(this.tripId, this.userId);
  @override
  List<Object> get props => [tripId, userId];
}

class CalculateFare extends TripEvent {
  final double distanceKm;
  const CalculateFare(this.distanceKm);
  @override
  List<Object> get props => [distanceKm];
}

// States
abstract class TripState extends Equatable {
  const TripState();
  @override
  List<Object> get props => [];
}

class TripInitial extends TripState {}
class TripLoading extends TripState {}
class TripHistoryLoaded extends TripState {
  final List<TripEntity> trips;
  const TripHistoryLoaded(this.trips);
  @override
  List<Object> get props => [trips];
}
class TripFareCalculated extends TripState {
  final double fare;
  const TripFareCalculated(this.fare);
  @override
  List<Object> get props => [fare];
}
class TripOperationSuccess extends TripState {} // For scheduling/cancelling
class TripError extends TripState {
  final String message;
  const TripError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
@injectable
class TripBloc extends Bloc<TripEvent, TripState> {
  final ITripRepository _repository;

  TripBloc(this._repository) : super(TripInitial()) {
    on<LoadTripHistory>(_onLoadTripHistory);
    on<ScheduleTrip>(_onScheduleTrip);
    on<CancelTrip>(_onCancelTrip);
    on<CalculateFare>(_onCalculateFare);
  }

  Future<void> _onLoadTripHistory(LoadTripHistory event, Emitter<TripState> emit) async {
    emit(TripLoading());
    final result = await _repository.getTripHistory(event.userId);
    result.fold(
      (failure) => emit(TripError(failure.message)),
      (trips) => emit(TripHistoryLoaded(trips)),
    );
  }

  Future<void> _onScheduleTrip(ScheduleTrip event, Emitter<TripState> emit) async {
    emit(TripLoading());
    final result = await _repository.scheduleTrip(event.trip);
    result.fold(
      (failure) => emit(TripError(failure.message)),
      (_) {
        emit(TripOperationSuccess());
        add(LoadTripHistory(event.trip.userId));
      },
    );
  }

  Future<void> _onCancelTrip(CancelTrip event, Emitter<TripState> emit) async {
    emit(TripLoading());
    final result = await _repository.cancelTrip(event.tripId);
    result.fold(
      (failure) => emit(TripError(failure.message)),
      (_) {
        emit(TripOperationSuccess());
        add(LoadTripHistory(event.userId));
      },
    );
  }

  Future<void> _onCalculateFare(CalculateFare event, Emitter<TripState> emit) async {
    emit(TripLoading());
    final result = await _repository.calculateFare(event.distanceKm);
    result.fold(
      (failure) => emit(TripError(failure.message)),
      (fare) => emit(TripFareCalculated(fare)),
    );
  }
}
