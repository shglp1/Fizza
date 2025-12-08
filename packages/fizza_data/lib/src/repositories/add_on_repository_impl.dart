import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: IAddOnRepository)
class AddOnRepositoryImpl implements IAddOnRepository {
  final FirebaseFirestore _firestore;

  AddOnRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, List<AddOnEntity>>> getAddOns() async {
    try {
      final snapshot = await _firestore.collection('add_ons').get();
      final addOns = snapshot.docs.map((doc) {
        final data = doc.data();
        return AddOnEntity(
          id: doc.id,
          name: data['name'],
          description: data['description'],
          price: (data['price'] as num).toDouble(),
          isMonthly: data['isMonthly'] ?? true,
        );
      }).toList();
      return Right(addOns);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addAddOn(AddOnEntity addOn) async {
    try {
      await _firestore.collection('add_ons').doc(addOn.id).set({
        'name': addOn.name,
        'description': addOn.description,
        'price': addOn.price,
        'isMonthly': addOn.isMonthly,
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateAddOn(AddOnEntity addOn) async {
    try {
      await _firestore.collection('add_ons').doc(addOn.id).update({
        'name': addOn.name,
        'description': addOn.description,
        'price': addOn.price,
        'isMonthly': addOn.isMonthly,
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAddOn(String addOnId) async {
    try {
      await _firestore.collection('add_ons').doc(addOnId).delete();
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
