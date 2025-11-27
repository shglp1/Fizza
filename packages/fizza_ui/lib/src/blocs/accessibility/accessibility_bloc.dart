import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';

// Events
abstract class AccessibilityEvent extends Equatable {
  const AccessibilityEvent();
  @override
  List<Object> get props => [];
}

class LoadAccessibilitySettings extends AccessibilityEvent {
  final String userId;
  const LoadAccessibilitySettings(this.userId);
  @override
  List<Object> get props => [userId];
}

class UpdateAccessibilitySettings extends AccessibilityEvent {
  final AccessibilitySettingsEntity settings;
  const UpdateAccessibilitySettings(this.settings);
  @override
  List<Object> get props => [settings];
}

// States
abstract class AccessibilityState extends Equatable {
  const AccessibilityState();
  @override
  List<Object> get props => [];
}

class AccessibilityInitial extends AccessibilityState {}
class AccessibilityLoading extends AccessibilityState {}
class AccessibilityLoaded extends AccessibilityState {
  final AccessibilitySettingsEntity settings;
  const AccessibilityLoaded(this.settings);
  @override
  List<Object> get props => [settings];
}
class AccessibilityError extends AccessibilityState {
  final String message;
  const AccessibilityError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
@injectable
class AccessibilityBloc extends Bloc<AccessibilityEvent, AccessibilityState> {
  final ISafetyRepository _repository;

  AccessibilityBloc(this._repository) : super(AccessibilityInitial()) {
    on<LoadAccessibilitySettings>(_onLoadSettings);
    on<UpdateAccessibilitySettings>(_onUpdateSettings);
  }

  Future<void> _onLoadSettings(LoadAccessibilitySettings event, Emitter<AccessibilityState> emit) async {
    emit(AccessibilityLoading());
    final result = await _repository.getAccessibilitySettings(event.userId);
    result.fold(
      (failure) => emit(AccessibilityError(failure.message)),
      (settings) => emit(AccessibilityLoaded(settings)),
    );
  }

  Future<void> _onUpdateSettings(UpdateAccessibilitySettings event, Emitter<AccessibilityState> emit) async {
    emit(AccessibilityLoading());
    final result = await _repository.updateAccessibilitySettings(event.settings);
    result.fold(
      (failure) => emit(AccessibilityError(failure.message)),
      (_) => emit(AccessibilityLoaded(event.settings)),
    );
  }
}
