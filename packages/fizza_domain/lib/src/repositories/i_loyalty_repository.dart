import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import '../entities/loyalty_point_entity.dart';
import '../entities/loyalty_event_type.dart';
import '../entities/reward_entity.dart';
import '../entities/gamification_profile_entity.dart';

abstract class ILoyaltyRepository {
  Future<Either<Failure, Unit>> earnPoints({
    required String userId,
    required LoyaltyEventType type,
    required int amount,
    String? referenceId,
  });
  
  Future<Either<Failure, List<LoyaltyPointEntity>>> getPointsHistory(String userId);
  
  Future<Either<Failure, Unit>> redeemReward({
    required String userId,
    required RewardEntity reward,
  });
  
  Future<Either<Failure, GamificationProfileEntity>> getGamificationProfile(String userId);
  
  Future<Either<Failure, List<RewardEntity>>> getAvailableRewards();
}
