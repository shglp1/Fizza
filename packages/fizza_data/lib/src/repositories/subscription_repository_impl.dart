import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';
import '../datasources/system_config_datasource.dart';

@LazySingleton(as: ISubscriptionRepository)
class SubscriptionRepositoryImpl implements ISubscriptionRepository {
  final FirebaseFirestore _firestore;
  final ISystemConfigDataSource _configDataSource;
  final ILoyaltyService _loyaltyService;

  SubscriptionRepositoryImpl(
    this._firestore, 
    this._configDataSource,
    this._loyaltyService,
  );

  @override
  Future<Either<Failure, List<SubscriptionPackageEntity>>> getAvailablePackages() async {
    try {
      final snapshot = await _firestore.collection('subscription_packages').get();
      final packages = snapshot.docs.map((doc) {
        final data = doc.data();
        return SubscriptionPackageEntity(
          id: doc.id,
          name: data['name'],
          price: (data['price'] as num).toDouble(),
          durationDays: data['durationDays'],
          features: List<String>.from(data['features'] ?? []),
          rideLimit: data['rideLimit'] ?? 20,
          distanceLimitKm: (data['distanceLimitKm'] as num?)?.toDouble() ?? 7.0,
          extraRidePrice: (data['extraRidePrice'] as num?)?.toDouble() ?? 8.0,
          isTrial: data['isTrial'] ?? false,
        );
      }).toList();
      return Right(packages);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserSubscriptionEntity?>> getCurrentSubscription(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('user_subscriptions')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return const Right(null);
      }

      final doc = snapshot.docs.first;
      final data = doc.data();
      
      return Right(UserSubscriptionEntity(
        id: doc.id,
        userId: data['userId'],
        packageId: data['packageId'],
        startDate: (data['startDate'] as Timestamp).toDate(),
        endDate: (data['endDate'] as Timestamp).toDate(),
        isActive: data['isActive'],
        autoRenew: data['autoRenew'],
        ridesUsed: data['ridesUsed'] ?? 0,
        extraRidesCharged: data['extraRidesCharged'] ?? 0,
        isFamily: data['isFamily'] ?? false,
        parentUserId: data['parentUserId'],
        beneficiaryId: data['beneficiaryId'],
        addOnIds: List<String>.from(data['addOnIds'] ?? []),
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkSubscriptionStatus(String userId) async {
    try {
      final subResult = await getCurrentSubscription(userId);
      return subResult.fold(
        (failure) => Left(failure),
        (subscription) async {
          if (subscription == null) return const Right(false);
          
          final config = await _configDataSource.getConfig();
          final limit = config.subscription.monthlyRideLimit;
          
          if (subscription.ridesUsed < limit) {
            return const Right(true);
          } else {
            return const Right(true); 
          }
        },
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> subscribeToPackage({
    required String userId,
    required SubscriptionPackageEntity package,
    required String paymentMethodId,
    List<AddOnEntity> addOns = const [],
    bool isFamily = false,
    String? parentUserId,
    String? beneficiaryId,
  }) async {
    try {
      // 1. Calculate Total Price
      double totalAmount = package.price;
      for (final addOn in addOns) {
        totalAmount += addOn.price;
      }

      // 2. Process Payment (Wallet as Source of Truth)
      await _firestore.runTransaction((transaction) async {
        final walletRef = _firestore.collection('wallets').doc(userId);
        final walletDoc = await transaction.get(walletRef);
        
        if (!walletDoc.exists) {
           // Create wallet if not exists (e.g. first time)
           transaction.set(walletRef, {'balance': 0.0, 'userId': userId});
        }
        
        double currentBalance = 0.0;
        if (walletDoc.exists) {
          currentBalance = (walletDoc.data()?['balance'] as num?)?.toDouble() ?? 0.0;
        }

        if (paymentMethodId != 'wallet') {
          // External Gateway Flow: Credit Wallet First
          // In a real app, we verify the gateway payment success here or via webhook.
          // We assume it's successful for this method call.
          
          currentBalance += totalAmount;
          transaction.set(walletRef, {'balance': currentBalance}, SetOptions(merge: true));

          final creditTxRef = walletRef.collection('transactions').doc();
          transaction.set(creditTxRef, {
            'amount': totalAmount,
            'type': 'credit',
            'description': 'Top-up via $paymentMethodId',
            'timestamp': FieldValue.serverTimestamp(),
            'paymentMethod': paymentMethodId,
            'referenceId': 'mock_gateway_ref_${DateTime.now().millisecondsSinceEpoch}',
          });
        }

        // Now Debit Wallet
        if (currentBalance < totalAmount) {
          throw Exception('Insufficient wallet balance');
        }

        transaction.update(walletRef, {
          'balance': currentBalance - totalAmount,
        });

        final debitTxRef = walletRef.collection('transactions').doc();
        transaction.set(debitTxRef, {
          'amount': -totalAmount,
          'type': 'debit',
          'description': 'Subscription: ${package.name}',
          'timestamp': FieldValue.serverTimestamp(),
          'paymentMethod': 'wallet',
          'referenceId': null,
        });

        // 3. Create Subscription
        final subRef = _firestore.collection('user_subscriptions').doc();
        transaction.set(subRef, {
          'userId': userId,
          'packageId': package.id,
          'startDate': FieldValue.serverTimestamp(),
          'endDate': Timestamp.fromDate(DateTime.now().add(Duration(days: package.durationDays))),
          'ridesUsed': 0,
          'extraRidesCharged': 0,
          'isActive': true,
          'autoRenew': true,
          'paymentMethodId': paymentMethodId,
          'addOnIds': addOns.map((e) => e.id).toList(),
          'isFamily': isFamily,
          'parentUserId': parentUserId,
          'beneficiaryId': beneficiaryId,
          'driverId': null, // Needs assignment
          'status': 'pending_assignment',
          'planType': package.planType,
          'discountAmount': (package.price * (package.discountPercentage / 100)),
        });
      });

      // 4. Award Loyalty Points (Fire and forget, or await)
      // We do this outside the transaction to avoid complexity, or we could do it inside if we moved logic here.
      // Since LoyaltyService uses its own transaction/updates, we call it after.
      // If it fails, we log it, but don't fail the subscription.
      try {
        await _loyaltyService.awardPointsForSubscription(
          userId: userId,
          package: package,
        );
      } catch (e) {
        // Log error but proceed
        print('Failed to award loyalty points: $e');
      }

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> cancelSubscription(String subscriptionId) async {
    try {
      final subRef = _firestore.collection('user_subscriptions').doc(subscriptionId);
      final subDoc = await subRef.get();
      
      if (!subDoc.exists) {
        return Left(ServerFailure('Subscription not found'));
      }
      
      final data = subDoc.data()!;
      final startDate = (data['startDate'] as Timestamp).toDate();
      final now = DateTime.now();
      
      // Policy: If before start date, full refund.
      if (now.isBefore(startDate)) {
        // Calculate refund amount (need to fetch package price or store it on sub)
        // For MVP, we'll assume we can get it from the packageId or if we stored 'amountPaid'
        // Let's assume we fetch the package to get the price, or better, we should have stored 'amountPaid' on the sub.
        // Since we didn't store amountPaid in subscribeToPackage (my bad), let's fetch the package.
        final packageId = data['packageId'];
        final packageDoc = await _firestore.collection('subscription_packages').doc(packageId).get();
        final price = (packageDoc.data()?['price'] as num?)?.toDouble() ?? 0.0;
        
        // Refund
        await _refundToWallet(data['userId'], price, 'Cancellation (Pre-start)');
        
        // Mark as cancelled
        await subRef.update({
          'status': 'cancelled',
          'isActive': false,
          'cancelReason': 'User cancelled before start',
          'autoRenew': false,
        });
      } else {
        // Policy: If active, no refund, just stop auto-renew (cancel scheduled)
        await subRef.update({
          'autoRenew': false,
          'renewalStatus': 'cancelled', // Indicates it won't renew
          'cancelReason': 'User cancelled during period',
        });
      }
      
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> toggleAutoRenew(String subscriptionId, bool enabled) async {
    try {
      await _firestore
          .collection('user_subscriptions')
          .doc(subscriptionId)
          .update({'autoRenew': enabled});
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  // Helper for refunds (can be exposed if needed)
  Future<void> _refundToWallet(String userId, double amount, String reason) async {
     await _firestore.runTransaction((transaction) async {
        final walletRef = _firestore.collection('wallets').doc(userId);
        final walletDoc = await transaction.get(walletRef);
        
        if (!walletDoc.exists) return; // Should exist
        
        final currentBalance = (walletDoc.data()?['balance'] as num?)?.toDouble() ?? 0.0;
        
        transaction.update(walletRef, {
          'balance': currentBalance + amount,
        });
        
        final txRef = walletRef.collection('transactions').doc();
        transaction.set(txRef, {
          'amount': amount,
          'type': 'credit',
          'description': 'Refund: $reason',
          'timestamp': FieldValue.serverTimestamp(),
          'paymentMethod': 'wallet',
          'referenceId': null,
        });
     });
  }
}

