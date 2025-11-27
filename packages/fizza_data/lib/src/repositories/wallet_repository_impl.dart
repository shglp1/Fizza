import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: IWalletRepository)
class WalletRepositoryImpl implements IWalletRepository {
  final FirebaseFirestore _firestore;

  WalletRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, WalletEntity>> getWallet(String userId) async {
    try {
      final doc = await _firestore.collection('wallets').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return Right(WalletEntity(
          userId: userId,
          balance: (data['balance'] as num).toDouble(),
          currency: data['currency'] ?? 'SAR',
        ));
      } else {
        // Create empty wallet if not exists
        final newWallet = WalletEntity(userId: userId, balance: 0.0);
        await _firestore.collection('wallets').doc(userId).set({
          'balance': 0.0,
          'currency': 'SAR',
        });
        return Right(newWallet);
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WalletTransactionEntity>>> getTransactions(String walletId) async {
    try {
      final snapshot = await _firestore
          .collection('wallets')
          .doc(walletId)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .get();

      final transactions = snapshot.docs.map((doc) {
        final data = doc.data();
        return WalletTransactionEntity(
          id: doc.id,
          walletId: walletId,
          amount: (data['amount'] as num).toDouble(),
          type: data['type'],
          description: data['description'],
          timestamp: (data['timestamp'] as Timestamp).toDate(),
        );
      }).toList();

      return Right(transactions);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> topUpWallet(String walletId, double amount) async {
    try {
      // Use transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        final walletRef = _firestore.collection('wallets').doc(walletId);
        final walletDoc = await transaction.get(walletRef);
        
        if (!walletDoc.exists) {
          throw Exception('Wallet not found');
        }

        final currentBalance = (walletDoc.data()!['balance'] as num).toDouble();
        final newBalance = currentBalance + amount;

        transaction.update(walletRef, {'balance': newBalance});

        final transactionRef = walletRef.collection('transactions').doc();
        transaction.set(transactionRef, {
          'amount': amount,
          'type': 'credit',
          'description': 'Top up',
          'timestamp': FieldValue.serverTimestamp(),
        });
      });
      
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
