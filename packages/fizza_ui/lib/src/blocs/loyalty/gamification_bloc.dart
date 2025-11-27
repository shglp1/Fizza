import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';

// Events
abstract class GamificationEvent extends Equatable {
  const GamificationEvent();
  @override
  List<Object> get props => [];
}

class LoadGamificationProfile extends GamificationEvent {
  final String userId;
  const LoadGamificationProfile(this.userId);
  @override
  List<Object> get props => [userId];
}

// States
abstract class GamificationState extends Equatable {
  const GamificationState();
  @override
  List<Object> get props => [];
}

class GamificationInitial extends GamificationState {}
class GamificationLoading extends GamificationState {}
class GamificationLoaded extends GamificationState {
  final GamificationProfileEntity profile;
  const GamificationLoaded(this.profile);
  @override
  List<Object> get props => [profile];
}
class GamificationError extends GamificationState {
  final String message;
  const GamificationError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
@injectable
class GamificationBloc extends Bloc<GamificationEvent, GamificationState> {
  final ILoyaltyRepository _repository;

  GamificationBloc(this._repository) : super(GamificationInitial()) {
    on<LoadGamificationProfile>(_onLoadProfile);
  }

  Future<void> _onLoadProfile(LoadGamificationProfile event, Emitter<GamificationState> emit) async {
    emit(GamificationLoading());
    final result = await _repository.getGamificationProfile(event.userId);
    result.fold(
      (failure) => emit(GamificationError(failure.message)),
      (profile) => emit(GamificationLoaded(profile)),
    );
  }
}
