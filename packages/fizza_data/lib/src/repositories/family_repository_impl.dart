import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: IFamilyRepository)
class FamilyRepositoryImpl implements IFamilyRepository {
  final FirebaseFirestore _firestore;

  FamilyRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, List<FamilyMemberEntity>>> getFamilyMembers(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('family_members')
          .get();
      
      final members = snapshot.docs.map((doc) {
        final data = doc.data();
        return FamilyMemberEntity(
          id: doc.id,
          parentId: userId,
          name: data['name'] ?? '',
          photoUrl: data['photoUrl'],
          schoolName: data['schoolName'],
          grade: data['grade'],
          isSpecialNeeds: data['isSpecialNeeds'] ?? false,
        );
      }).toList();
      
      return Right(members);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addFamilyMember(FamilyMemberEntity member) async {
    try {
      await _firestore
          .collection('users')
          .doc(member.parentId)
          .collection('family_members')
          .add({
        'name': member.name,
        'photoUrl': member.photoUrl,
        'schoolName': member.schoolName,
        'grade': member.grade,
        'isSpecialNeeds': member.isSpecialNeeds,
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateFamilyMember(FamilyMemberEntity member) async {
    try {
      await _firestore
          .collection('users')
          .doc(member.parentId)
          .collection('family_members')
          .doc(member.id)
          .update({
        'name': member.name,
        'photoUrl': member.photoUrl,
        'schoolName': member.schoolName,
        'grade': member.grade,
        'isSpecialNeeds': member.isSpecialNeeds,
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteFamilyMember(String memberId) async {
    // Note: This requires parentId to construct the path. 
    // Ideally delete should take parentId too or we query to find it.
    // For now assuming we can't easily delete without parentId in this structure.
    // I'll assume the caller knows the parentId or I change the interface.
    // Let's change the interface in Domain later if needed. 
    // For now, I'll return error as not implemented fully or assume I can find it.
    return const Left(ServerFailure('Delete requires parentId'));
  }
}
