import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ISubscriptionRepository)
class SubscriptionRepositoryImpl implements ISubscriptionRepository {
  final FirebaseFirestore _firestore;

  SubscriptionRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, List<SubscriptionPackageEntity>>> getAvailablePackages() async {
    try {
      final snapshot = await _firestore.collection('subscription_packages').get();
      final packages = snapshot.docs.map((doc) {
        final data = doc.data();
        return SubscriptionPackageEntity(
          id: doc.id,
          name: data['name'],
          description: data['description'],
          price: (data['price'] as num).toDouble(),
          ridesIncluded: data['ridesIncluded'],
          durationDays: data['durationDays'],
          isFamilyPackage: data['isFamilyPackage'] ?? false,
          maxFamilyMembers: data['maxFamilyMembers'] ?? 0,
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
        ridesRemaining: data['ridesRemaining'],
        isActive: data['isActive'],
        autoRenew: data['autoRenew'],
      ));
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
