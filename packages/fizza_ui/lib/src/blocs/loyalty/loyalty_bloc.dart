import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';

// Events
abstract class LoyaltyEvent extends Equatable {
  const LoyaltyEvent();
  @override
  List<Object> get props => [];
}

class LoadLoyaltyPoints extends LoyaltyEvent {
  final String userId;
  const LoadLoyaltyPoints(this.userId);
  @override
  List<Object> get props => [userId];
}

class LoadAvailableRewards extends LoyaltyEvent {}

class RedeemReward extends LoyaltyEvent {
  final String userId;
  final RewardEntity reward;
  const RedeemReward(this.userId, this.reward);
  @override
  List<Object> get props => [userId, reward];
}

// States
abstract class LoyaltyState extends Equatable {
  const LoyaltyState();
  @override
  List<Object> get props => [];
}

class LoyaltyInitial extends LoyaltyState {}
class LoyaltyLoading extends LoyaltyState {}
class LoyaltyLoaded extends LoyaltyState {
  final List<LoyaltyPointEntity> history;
  final List<RewardEntity> availableRewards;
  const LoyaltyLoaded(this.history, this.availableRewards);
  @override
  List<Object> get props => [history, availableRewards];
}
class LoyaltyRedemptionSuccess extends LoyaltyState {}
class LoyaltyError extends LoyaltyState {
  final String message;
  const LoyaltyError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
@injectable
class LoyaltyBloc extends Bloc<LoyaltyEvent, LoyaltyState> {
  final ILoyaltyRepository _repository;

  LoyaltyBloc(this._repository) : super(LoyaltyInitial()) {
    on<LoadLoyaltyPoints>(_onLoadPoints);
    on<LoadAvailableRewards>(_onLoadRewards);
    on<RedeemReward>(_onRedeemReward);
  }

  Future<void> _onLoadPoints(LoadLoyaltyPoints event, Emitter<LoyaltyState> emit) async {
    emit(LoyaltyLoading());
    final pointsResult = await _repository.getPointsHistory(event.userId);
    final rewardsResult = await _repository.getAvailableRewards();
    
    pointsResult.fold(
      (failure) => emit(LoyaltyError(failure.message)),
      (history) {
        rewardsResult.fold(
          (failure) => emit(LoyaltyLoaded(history, [])),
          (rewards) => emit(LoyaltyLoaded(history, rewards)),
        );
      },
    );
  }

  Future<void> _onLoadRewards(LoadAvailableRewards event, Emitter<LoyaltyState> emit) async {
    // This might be redundant if we load everything in LoadLoyaltyPoints, but useful for separate screens
    emit(LoyaltyLoading());
    final result = await _repository.getAvailableRewards();
    result.fold(
      (failure) => emit(LoyaltyError(failure.message)),
      (rewards) => emit(LoyaltyLoaded([], rewards)), // Empty history if only loading rewards
    );
  }

  Future<void> _onRedeemReward(RedeemReward event, Emitter<LoyaltyState> emit) async {
    emit(LoyaltyLoading());
    final result = await _repository.redeemReward(userId: event.userId, reward: event.reward);
    result.fold(
      (failure) => emit(LoyaltyError(failure.message)),
      (_) {
        emit(LoyaltyRedemptionSuccess());
        add(LoadLoyaltyPoints(event.userId)); // Reload points
      },
    );
  }
}
