import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';

// Events
abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();
  @override
  List<Object> get props => [];
}

class LoadPackages extends SubscriptionEvent {}

class LoadUserSubscription extends SubscriptionEvent {
  final String userId;
  const LoadUserSubscription(this.userId);
  @override
  List<Object> get props => [userId];
}

class SubscribeToPackage extends SubscriptionEvent {
  final String userId;
  final SubscriptionPackageEntity package;
  final String paymentMethodId;
  const SubscribeToPackage({
    required this.userId,
    required this.package,
    required this.paymentMethodId,
  });
  @override
  List<Object> get props => [userId, package, paymentMethodId];
}

class CancelSubscription extends SubscriptionEvent {
  final String subscriptionId;
  final String userId;
  const CancelSubscription(this.subscriptionId, this.userId);
  @override
  List<Object> get props => [subscriptionId, userId];
}

// States
abstract class SubscriptionState extends Equatable {
  const SubscriptionState();
  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {}
class SubscriptionLoading extends SubscriptionState {}
class SubscriptionPackagesLoaded extends SubscriptionState {
  final List<SubscriptionPackageEntity> packages;
  const SubscriptionPackagesLoaded(this.packages);
  @override
  List<Object> get props => [packages];
}
class UserSubscriptionLoaded extends SubscriptionState {
  final UserSubscriptionEntity? subscription;
  final List<SubscriptionPackageEntity> availablePackages;
  const UserSubscriptionLoaded(this.subscription, this.availablePackages);
  @override
  List<Object?> get props => [subscription, availablePackages];
}
class SubscriptionOperationSuccess extends SubscriptionState {}
class SubscriptionError extends SubscriptionState {
  final String message;
  const SubscriptionError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
@injectable
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final ISubscriptionRepository _repository;

  SubscriptionBloc(this._repository) : super(SubscriptionInitial()) {
    on<LoadPackages>(_onLoadPackages);
    on<LoadUserSubscription>(_onLoadUserSubscription);
    on<SubscribeToPackage>(_onSubscribeToPackage);
    on<CancelSubscription>(_onCancelSubscription);
  }

  Future<void> _onLoadPackages(LoadPackages event, Emitter<SubscriptionState> emit) async {
    emit(SubscriptionLoading());
    final result = await _repository.getAvailablePackages();
    result.fold(
      (failure) => emit(SubscriptionError(failure.message)),
      (packages) => emit(SubscriptionPackagesLoaded(packages)),
    );
  }

  Future<void> _onLoadUserSubscription(LoadUserSubscription event, Emitter<SubscriptionState> emit) async {
    emit(SubscriptionLoading());
    // Load both subscription and packages to show context
    final subResult = await _repository.getCurrentSubscription(event.userId);
    final pkgResult = await _repository.getAvailablePackages();
    
    subResult.fold(
      (failure) => emit(SubscriptionError(failure.message)),
      (subscription) {
        pkgResult.fold(
          (failure) => emit(UserSubscriptionLoaded(subscription, [])), // Partial success
          (packages) => emit(UserSubscriptionLoaded(subscription, packages)),
        );
      },
    );
  }

  Future<void> _onSubscribeToPackage(SubscribeToPackage event, Emitter<SubscriptionState> emit) async {
    emit(SubscriptionLoading());
    final result = await _repository.subscribeToPackage(
      userId: event.userId,
      package: event.package,
      paymentMethodId: event.paymentMethodId,
    );
    result.fold(
      (failure) => emit(SubscriptionError(failure.message)),
      (_) {
        emit(SubscriptionOperationSuccess());
        add(LoadUserSubscription(event.userId));
      },
    );
  }

  Future<void> _onCancelSubscription(CancelSubscription event, Emitter<SubscriptionState> emit) async {
    emit(SubscriptionLoading());
    final result = await _repository.cancelSubscription(event.subscriptionId);
    result.fold(
      (failure) => emit(SubscriptionError(failure.message)),
      (_) {
        emit(SubscriptionOperationSuccess());
        add(LoadUserSubscription(event.userId));
      },
    );
  }
}
