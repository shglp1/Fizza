import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';

// Events
abstract class WalletEvent extends Equatable {
  const WalletEvent();
  @override
  List<Object> get props => [];
}

class LoadWallet extends WalletEvent {
  final String userId;
  const LoadWallet(this.userId);
  @override
  List<Object> get props => [userId];
}

class TopUpWallet extends WalletEvent {
  final String walletId;
  final double amount;
  const TopUpWallet(this.walletId, this.amount);
  @override
  List<Object> get props => [walletId, amount];
}

// States
abstract class WalletState extends Equatable {
  const WalletState();
  @override
  List<Object> get props => [];
}

class WalletInitial extends WalletState {}
class WalletLoading extends WalletState {}
class WalletLoaded extends WalletState {
  final WalletEntity wallet;
  final List<WalletTransactionEntity> transactions;
  const WalletLoaded(this.wallet, this.transactions);
  @override
  List<Object> get props => [wallet, transactions];
}
class WalletError extends WalletState {
  final String message;
  const WalletError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
@injectable
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final IWalletRepository _repository;

  WalletBloc(this._repository) : super(WalletInitial()) {
    on<LoadWallet>(_onLoadWallet);
    on<TopUpWallet>(_onTopUpWallet);
  }

  Future<void> _onLoadWallet(LoadWallet event, Emitter<WalletState> emit) async {
    emit(WalletLoading());
    final walletResult = await _repository.getWallet(event.userId);
    
    await walletResult.fold(
      (failure) async => emit(WalletError(failure.message)),
      (wallet) async {
        final transactionsResult = await _repository.getTransactions(event.userId); // Assuming walletId is userId for simplicity
        transactionsResult.fold(
          (failure) => emit(WalletLoaded(wallet, [])), // Load wallet even if transactions fail? Or error?
          (transactions) => emit(WalletLoaded(wallet, transactions)),
        );
      },
    );
  }

  Future<void> _onTopUpWallet(TopUpWallet event, Emitter<WalletState> emit) async {
    if (event.amount < 20 || event.amount > 500) {
      emit(const WalletError('Top-up amount must be between 20 SAR and 500 SAR'));
      return;
    }

    emit(WalletLoading());
    final result = await _repository.topUpWallet(event.walletId, event.amount);
    result.fold(
      (failure) => emit(WalletError(failure.message)),
      (_) => add(LoadWallet(event.walletId)), // Reload wallet
    );
  }
}
