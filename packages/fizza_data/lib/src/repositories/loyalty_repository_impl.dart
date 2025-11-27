import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ILoyaltyRepository)
class LoyaltyRepositoryImpl implements ILoyaltyRepository {
  final FirebaseFirestore _firestore;

  LoyaltyRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, Unit>> earnPoints({
    required String userId,
    required LoyaltyEventType type,
    required int amount,
    String? referenceId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // 1. Add point transaction
        final pointRef = _firestore.collection('loyalty_points').doc();
        transaction.set(pointRef, {
          'userId': userId,
          'amount': amount,
          'type': type.toString().split('.').last,
          'referenceId': referenceId,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // 2. Update user profile (total points and level)
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) throw Exception('User not found');
        
        final currentPoints = (userDoc.data()?['loyaltyPoints'] as num?)?.toInt() ?? 0;
        final newPoints = currentPoints + amount;
        
        // Simple level logic: Level 1 (0-500), Level 2 (501-2000), Level 3 (2001+)
        int newLevel = 1;
        if (newPoints > 2000) {
          newLevel = 3;
        } else if (newPoints > 500) {
          newLevel = 2;
        }

        transaction.update(userRef, {
          'loyaltyPoints': newPoints,
          'loyaltyLevel': newLevel,
        });
      });

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LoyaltyPointEntity>>> getPointsHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('loyalty_points')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      final points = snapshot.docs.map((doc) {
        final data = doc.data();
        return LoyaltyPointEntity(
          id: doc.id,
          userId: data['userId'],
          amount: data['amount'],
          type: LoyaltyEventType.values.firstWhere(
            (e) => e.toString().split('.').last == data['type'],
            orElse: () => LoyaltyEventType.manualAdjustment,
          ),
          referenceId: data['referenceId'],
          timestamp: (data['timestamp'] as Timestamp).toDate(),
        );
      }).toList();

      return Right(points);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> redeemReward({
    required String userId,
    required RewardEntity reward,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) throw Exception('User not found');
        
        final currentPoints = (userDoc.data()?['loyaltyPoints'] as num?)?.toInt() ?? 0;
        
        if (currentPoints < reward.cost) {
          throw Exception('Insufficient points');
        }

        // Deduct points
        transaction.update(userRef, {
          'loyaltyPoints': currentPoints - reward.cost,
        });

        // Record redemption
        final redemptionRef = _firestore.collection('reward_redemptions').doc();
        transaction.set(redemptionRef, {
          'userId': userId,
          'rewardId': reward.id,
          'cost': reward.cost,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        // Add negative point transaction for history
         final pointRef = _firestore.collection('loyalty_points').doc();
        transaction.set(pointRef, {
          'userId': userId,
          'amount': -reward.cost,
          'type': 'redemption',
          'referenceId': reward.id,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });
      
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GamificationProfileEntity>> getGamificationProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return const Left(ServerFailure('User not found'));

      final data = doc.data()!;
      final points = (data['loyaltyPoints'] as num?)?.toInt() ?? 0;
      final level = (data['loyaltyLevel'] as num?)?.toInt() ?? 1;
      final badges = List<String>.from(data['badges'] ?? []);

      // Calculate next level threshold
      int nextThreshold = 500;
      if (level >= 2) nextThreshold = 2000;
      if (level >= 3) nextThreshold = 10000; // Cap

      return Right(GamificationProfileEntity(
        userId: userId,
        totalPoints: points,
        currentLevel: level,
        badges: badges,
        nextLevelThreshold: nextThreshold,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RewardEntity>>> getAvailableRewards() async {
    try {
      // Mock rewards
      return Right([
        const RewardEntity(
          id: '1',
          name: '10% Off Next Ride',
          description: 'Get a discount on your next trip.',
          cost: 100,
          imageUrl: 'assets/rewards/discount_10.png',
        ),
        const RewardEntity(
          id: '2',
          name: 'Free Coffee',
          description: 'Redeem at partner cafes.',
          cost: 250,
          imageUrl: 'assets/rewards/coffee.png',
        ),
        const RewardEntity(
          id: '3',
          name: 'Premium Car Upgrade',
          description: 'Upgrade to a luxury car for one ride.',
          cost: 500,
          imageUrl: 'assets/rewards/luxury_car.png',
        ),
      ]);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
