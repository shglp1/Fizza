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

  SubscriptionRepositoryImpl(this._firestore, this._configDataSource);

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
          
          // Get package limits (could be stored in subscription or fetched)
          // For MVP, we can fetch config or package. 
          // Assuming we fetch config for global rules or package for specific rules.
          // Let's use config for MVP simplicity as per rules.
          final config = await _configDataSource.getConfig();
          final limit = config.subscription.monthlyRideLimit;
          
          if (subscription.ridesUsed < limit) {
            return const Right(true);
          } else {
            // Allow overage but it implies extra charge logic will handle it
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
  }) async {
    try {
      // Mock Payment Processing
      // In real app, call payment gateway here using paymentMethodId
      
      final startDate = DateTime.now();
      final endDate = startDate.add(Duration(days: package.durationDays));

      await _firestore.collection('user_subscriptions').add({
        'userId': userId,
        'packageId': package.id,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'ridesRemaining': package.ridesIncluded,
        'isActive': true,
        'autoRenew': true,
        'paymentMethodId': paymentMethodId,
      });

      // Also create a transaction record in wallet or payment history
      await _firestore.collection('payment_history').add({
        'userId': userId,
        'amount': package.price,
        'description': 'Subscription to ${package.name}',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'success',
      });

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> cancelSubscription(String subscriptionId) async {
    try {
      await _firestore
          .collection('user_subscriptions')
          .doc(subscriptionId)
          .update({'autoRenew': false});
      // Note: Usually cancellation means turning off auto-renew, not immediate termination.
      // If immediate termination is needed, set isActive to false.
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
}
