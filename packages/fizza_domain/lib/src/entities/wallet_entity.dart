import 'package:equatable/equatable.dart';

class WalletEntity extends Equatable {
  final String userId;
  final double balance;
  final String currency;

  const WalletEntity({
    required this.userId,
    required this.balance,
    this.currency = 'SAR',
  });

  @override
  List<Object> get props => [userId, balance, currency];
}

class WalletTransactionEntity extends Equatable {
  final String id;
  final String walletId;
  final double amount;
  final String type; // 'credit', 'debit'
  final String description;
  final DateTime timestamp;

  const WalletTransactionEntity({
    required this.id,
    required this.walletId,
    required this.amount,
    required this.type,
    required this.description,
    required this.timestamp,
  });

  @override
  List<Object> get props => [id, walletId, amount, type, description, timestamp];
}
