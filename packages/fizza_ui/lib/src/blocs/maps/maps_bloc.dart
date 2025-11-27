import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';

// Events
abstract class MapsEvent extends Equatable {
  const MapsEvent();
  @override
  List<Object> get props => [];
}

class LoadCurrentLocation extends MapsEvent {}

class SearchPlaces extends MapsEvent {
  final String query;
  const SearchPlaces(this.query);
  @override
  List<Object> get props => [query];
}

class GetRoute extends MapsEvent {
  final LocationEntity origin;
  final LocationEntity destination;
  const GetRoute(this.origin, this.destination);
  @override
  List<Object> get props => [origin, destination];
}

// States
abstract class MapsState extends Equatable {
  const MapsState();
  @override
  List<Object?> get props => [];
}

class MapsInitial extends MapsState {}
class MapsLoading extends MapsState {}
class MapsLocationLoaded extends MapsState {
  final LocationEntity location;
  const MapsLocationLoaded(this.location);
  @override
  List<Object> get props => [location];
}
class MapsPlacesLoaded extends MapsState {
  final List<LocationEntity> places;
  const MapsPlacesLoaded(this.places);
  @override
  List<Object> get props => [places];
}
class MapsRouteLoaded extends MapsState {
  final RouteEntity route;
  const MapsRouteLoaded(this.route);
  @override
  List<Object> get props => [route];
}
class MapsError extends MapsState {
  final String message;
  const MapsError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
@injectable
class MapsBloc extends Bloc<MapsEvent, MapsState> {
  final IMapsRepository _repository;

  MapsBloc(this._repository) : super(MapsInitial()) {
    on<LoadCurrentLocation>(_onLoadCurrentLocation);
    on<SearchPlaces>(_onSearchPlaces);
    on<GetRoute>(_onGetRoute);
  }

  Future<void> _onLoadCurrentLocation(LoadCurrentLocation event, Emitter<MapsState> emit) async {
    emit(MapsLoading());
    final result = await _repository.getCurrentLocation();
    result.fold(
      (failure) => emit(MapsError(failure.message)),
      (location) => emit(MapsLocationLoaded(location)),
    );
  }

  Future<void> _onSearchPlaces(SearchPlaces event, Emitter<MapsState> emit) async {
    emit(MapsLoading());
    final result = await _repository.searchPlaces(event.query);
    result.fold(
      (failure) => emit(MapsError(failure.message)),
      (places) => emit(MapsPlacesLoaded(places)),
    );
  }

  Future<void> _onGetRoute(GetRoute event, Emitter<MapsState> emit) async {
    emit(MapsLoading());
    final result = await _repository.getRoute(event.origin, event.destination);
    result.fold(
      (failure) => emit(MapsError(failure.message)),
      (route) => emit(MapsRouteLoaded(route)),
    );
  }
}
