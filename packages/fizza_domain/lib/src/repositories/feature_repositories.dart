import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import '../entities/family_member_entity.dart';
import '../entities/wallet_entity.dart';
import '../entities/trip_entity.dart';

abstract class IFamilyRepository {
  Future<Either<Failure, List<FamilyMemberEntity>>> getFamilyMembers(String userId);
  Future<Either<Failure, Unit>> addFamilyMember(FamilyMemberEntity member);
  Future<Either<Failure, Unit>> updateFamilyMember(FamilyMemberEntity member);
  Future<Either<Failure, Unit>> deleteFamilyMember(String memberId);
}

abstract class IWalletRepository {
  Future<Either<Failure, WalletEntity>> getWallet(String userId);
  Future<Either<Failure, List<WalletTransactionEntity>>> getTransactions(String walletId);
  Future<Either<Failure, Unit>> topUpWallet(String walletId, double amount);
}

abstract class ITripRepository {
  Future<Either<Failure, List<TripEntity>>> getTripHistory(String userId);
  Future<Either<Failure, TripEntity>> getTripDetails(String tripId);
  Future<Either<Failure, Unit>> scheduleTrip(TripEntity trip);
  Future<Either<Failure, Unit>> cancelTrip(String tripId);
  Future<Either<Failure, double>> calculateFare(double distanceKm);
}
