import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: IDriverRepository)
class DriverRepositoryImpl implements IDriverRepository {
  final FirebaseFirestore _firestore;

  DriverRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, DriverEntity>> getDriverProfile(String userId) async {
    try {
      final doc = await _firestore.collection('drivers').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return Right(DriverEntity(
          id: doc.id,
          userId: userId,
          name: data['name'] ?? 'Unknown',
          phoneNumber: data['phoneNumber'] ?? '',
          vehicleModel: data['vehicleModel'] ?? 'Unknown',
          vehiclePlate: data['vehiclePlate'] ?? 'Unknown',
          vehicleYear: data['vehicleYear'] ?? 2020,
          isOnline: data['isOnline'] ?? false,
          isAvailable: data['isAvailable'] ?? false,
          commissionRate: (data['commissionRate'] as num?)?.toDouble() ?? 0.12,
          rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
          ratingCount: data['ratingCount'] ?? 0,
          totalRides: data['totalRides'] ?? 0,
          isSuspended: data['isSuspended'] ?? false,
          suspensionReason: data['suspensionReason'],
          currentLocation: data['location'] != null 
              ? LocationEntity(
                  latitude: data['location']['lat'],
                  longitude: data['location']['lng'],
                  heading: (data['location']['heading'] as num?)?.toDouble(),
                )
              : null,
        ));
      } else {
        return const Left(ServerFailure('Driver profile not found'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> toggleOnlineStatus(String driverId, bool isOnline) async {
    try {
      await _firestore.collection('drivers').doc(driverId).update({'isOnline': isOnline});
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, EarningsEntity>> getEarnings(String driverId) async {
    try {
      // In a real app, calculate from 'trips' collection or a dedicated 'earnings' subcollection
      // Mocking for now
      return Right(EarningsEntity(
        driverId: driverId,
        todayEarnings: 150.0,
        weekEarnings: 850.0,
        totalEarnings: 3200.0,
        todayRides: 5,
        weekRides: 28,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<RideRequestEntity>>> getRideRequests(String driverId) {
    return _firestore
        .collection('ride_requests')
        .where('status', isEqualTo: 'pending')
        // .where('nearbyDrivers', arrayContains: driverId) // In real app, use GeoFire or Cloud Functions to assign
        .snapshots()
        .map((snapshot) {
      try {
        final requests = snapshot.docs.map((doc) {
          final data = doc.data();
          return RideRequestEntity(
            id: doc.id,
            userId: data['userId'],
            userName: data['userName'],
            pickupLocation: LocationEntity(
              latitude: data['pickup']['lat'],
              longitude: data['pickup']['lng'],
              address: data['pickup']['address'],
            ),
            dropoffLocation: LocationEntity(
              latitude: data['dropoff']['lat'],
              longitude: data['dropoff']['lng'],
              address: data['dropoff']['address'],
            ),
            estimatedFare: (data['estimatedFare'] as num).toDouble(),
            distanceKm: (data['distanceKm'] as num).toDouble(),
            estimatedDuration: (data['estimatedDuration'] as num).toDouble(),
            timestamp: (data['timestamp'] as Timestamp).toDate(),
            status: data['status'],
          );
        }).toList();
        return Right(requests);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    });
  }

  @override
  Future<Either<Failure, Unit>> acceptRideRequest(String driverId, String requestId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final requestRef = _firestore.collection('ride_requests').doc(requestId);
        final requestDoc = await transaction.get(requestRef);
        
        if (!requestDoc.exists) {
          throw Exception('Request not found');
        }
        
        if (requestDoc.data()!['status'] != 'pending') {
          throw Exception('Request already accepted');
        }

        transaction.update(requestRef, {
          'status': 'accepted',
          'driverId': driverId,
          'acceptedAt': FieldValue.serverTimestamp(),
        });
        
        // Also create a trip record or update existing one
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> rejectRideRequest(String driverId, String requestId) async {
    try {
      // Just remove driver from potential list or ignore locally
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
