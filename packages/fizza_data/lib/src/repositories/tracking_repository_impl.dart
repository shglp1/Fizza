import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ITrackingRepository)
class TrackingRepositoryImpl implements ITrackingRepository {
  final FirebaseFirestore _firestore;

  TrackingRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, Unit>> updateDriverLocation(String driverId, LocationEntity location) async {
    try {
      await _firestore.collection('drivers').doc(driverId).update({
        'location': {
          'lat': location.latitude,
          'lng': location.longitude,
          'heading': location.heading,
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, LocationEntity>> trackDriverLocation(String driverId) {
    return _firestore.collection('drivers').doc(driverId).snapshots().map((doc) {
      if (!doc.exists) {
        return const Left(ServerFailure('Driver not found'));
      }
      final data = doc.data();
      if (data == null || data['location'] == null) {
        return const Left(ServerFailure('Location not available'));
      }
      final loc = data['location'];
      return Right(LocationEntity(
        latitude: loc['lat'],
        longitude: loc['lng'],
        heading: (loc['heading'] as num?)?.toDouble(),
      ));
    });
  }
}
