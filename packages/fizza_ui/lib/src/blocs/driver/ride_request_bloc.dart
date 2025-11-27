import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';

// Events
abstract class RideRequestEvent extends Equatable {
  const RideRequestEvent();
  @override
  List<Object> get props => [];
}

class StartListeningForRequests extends RideRequestEvent {
  final String driverId;
  const StartListeningForRequests(this.driverId);
  @override
  List<Object> get props => [driverId];
}

class StopListeningForRequests extends RideRequestEvent {}

class NewRequestsReceived extends RideRequestEvent {
  final List<RideRequestEntity> requests;
  const NewRequestsReceived(this.requests);
  @override
  List<Object> get props => [requests];
}

class AcceptRideRequest extends RideRequestEvent {
  final String driverId;
  final String requestId;
  const AcceptRideRequest(this.driverId, this.requestId);
  @override
  List<Object> get props => [driverId, requestId];
}

class RejectRideRequest extends RideRequestEvent {
  final String driverId;
  final String requestId;
  const RejectRideRequest(this.driverId, this.requestId);
  @override
  List<Object> get props => [driverId, requestId];
}

// States
abstract class RideRequestState extends Equatable {
  const RideRequestState();
  @override
  List<Object> get props => [];
}

class RideRequestInitial extends RideRequestState {}
class RideRequestListening extends RideRequestState {
  final List<RideRequestEntity> requests;
  const RideRequestListening(this.requests);
  @override
  List<Object> get props => [requests];
}
class RideRequestOperationSuccess extends RideRequestState {} // For accept/reject
class RideRequestError extends RideRequestState {
  final String message;
  const RideRequestError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
@injectable
class RideRequestBloc extends Bloc<RideRequestEvent, RideRequestState> {
  final IDriverRepository _repository;
  StreamSubscription? _subscription;

  RideRequestBloc(this._repository) : super(RideRequestInitial()) {
    on<StartListeningForRequests>(_onStartListening);
    on<NewRequestsReceived>(_onNewRequestsReceived);
    on<AcceptRideRequest>(_onAcceptRequest);
    on<RejectRideRequest>(_onRejectRequest);
    on<StopListeningForRequests>(_onStopListening);
  }

  Future<void> _onStartListening(StartListeningForRequests event, Emitter<RideRequestState> emit) async {
    await _subscription?.cancel();
    _subscription = _repository.getRideRequests(event.driverId).listen(
      (result) {
        result.fold(
          (failure) => add(StopListeningForRequests()), // Or handle error
          (requests) => add(NewRequestsReceived(requests)),
        );
      },
    );
    emit(const RideRequestListening([]));
  }

  Future<void> _onNewRequestsReceived(NewRequestsReceived event, Emitter<RideRequestState> emit) async {
    emit(RideRequestListening(event.requests));
  }

  Future<void> _onAcceptRequest(AcceptRideRequest event, Emitter<RideRequestState> emit) async {
    final result = await _repository.acceptRideRequest(event.driverId, event.requestId);
    result.fold(
      (failure) => emit(RideRequestError(failure.message)),
      (_) => emit(RideRequestOperationSuccess()),
    );
  }

  Future<void> _onRejectRequest(RejectRideRequest event, Emitter<RideRequestState> emit) async {
    final result = await _repository.rejectRideRequest(event.driverId, event.requestId);
    result.fold(
      (failure) => emit(RideRequestError(failure.message)),
      (_) {
        // Just stay in listening state, the stream will update if the request is removed
      },
    );
  }

  Future<void> _onStopListening(StopListeningForRequests event, Emitter<RideRequestState> emit) async {
    await _subscription?.cancel();
    emit(RideRequestInitial());
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
