import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';
import '../models/beneficiary_model.dart';

@LazySingleton(as: IBeneficiariesRepository)
class BeneficiariesRepositoryImpl implements IBeneficiariesRepository {
  final FirebaseFirestore _firestore;

  BeneficiariesRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, List<BeneficiaryEntity>>> getBeneficiariesForParent(String parentUserId) async {
    try {
      final snapshot = await _firestore
          .collection('beneficiaries')
          .where('parent_user_id', isEqualTo: parentUserId)
          .where('is_active', isEqualTo: true)
          .get();

      final beneficiaries = snapshot.docs.map((doc) {
        return BeneficiaryModel.fromJson(doc.data(), doc.id);
      }).toList();

      return Right(beneficiaries);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> createOrUpdateBeneficiary(BeneficiaryEntity beneficiary) async {
    try {
      final model = BeneficiaryModel.fromEntity(beneficiary);
      final colRef = _firestore.collection('beneficiaries');
      
      final docRef = beneficiary.id.isEmpty 
          ? colRef.doc() 
          : colRef.doc(beneficiary.id);
      
      // If it's a new doc (auto-id), we might want to ensure the ID is in the model if we were returning it,
      // but for now we just save the data. The model.toJson() doesn't include the ID usually if it's separate.
      // However, BeneficiaryModel.fromEntity puts the entity.id into the model. 
      // If entity.id is empty, model.id is empty.
      // Firestore doesn't automatically put the doc ID into the data unless we do it.
      // But typically we read the ID from the doc.id when fetching.
      
      await docRef.set(model.toJson(), SetOptions(merge: true));
      
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deactivateBeneficiary(String beneficiaryId) async {
    try {
      await _firestore.collection('beneficiaries').doc(beneficiaryId).update({
        'is_active': false,
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
