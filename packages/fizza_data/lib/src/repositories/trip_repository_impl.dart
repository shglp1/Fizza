import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ITripRepository)
class TripRepositoryImpl implements ITripRepository {
  final FirebaseFirestore _firestore;

  TripRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, List<TripEntity>>> getTripHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('trips')
          .where('userId', isEqualTo: userId)
          .orderBy('scheduledTime', descending: true)
          .get();

      final trips = snapshot.docs.map((doc) => _mapDocToTrip(doc)).toList();
      return Right(trips);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TripEntity>> getTripDetails(String tripId) async {
    try {
      final doc = await _firestore.collection('trips').doc(tripId).get();
      if (doc.exists) {
        return Right(_mapDocToTrip(doc));
      } else {
        return const Left(ServerFailure('Trip not found'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> scheduleTrip(TripEntity trip) async {
    try {
      await _firestore.collection('trips').add({
        'userId': trip.userId,
        'driverId': trip.driverId,
        'familyMemberId': trip.familyMemberId,
        'pickupLocation': trip.pickupLocation,
        'dropoffLocation': trip.dropoffLocation,
        'scheduledTime': Timestamp.fromDate(trip.scheduledTime),
        'status': trip.status,
        'cost': trip.cost,
        'isFemaleDriverRequested': trip.isFemaleDriverRequested,
        'isAssistantRequested': trip.isAssistantRequested,
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> cancelTrip(String tripId) async {
    try {
      await _firestore.collection('trips').doc(tripId).update({'status': 'cancelled'});
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  TripEntity _mapDocToTrip(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TripEntity(
      id: doc.id,
      userId: data['userId'],
      driverId: data['driverId'],
      familyMemberId: data['familyMemberId'],
      pickupLocation: data['pickupLocation'],
      dropoffLocation: data['dropoffLocation'],
      scheduledTime: (data['scheduledTime'] as Timestamp).toDate(),
      status: data['status'],
      cost: (data['cost'] as num).toDouble(),
      isFemaleDriverRequested: data['isFemaleDriverRequested'] ?? false,
      isAssistantRequested: data['isAssistantRequested'] ?? false,
    );
  }
}
