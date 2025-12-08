import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import '../entities/beneficiary_entity.dart';

abstract class IBeneficiariesRepository {
  Future<Either<Failure, List<BeneficiaryEntity>>> getBeneficiariesForParent(String parentUserId);
  Future<Either<Failure, Unit>> createOrUpdateBeneficiary(BeneficiaryEntity beneficiary);
  Future<Either<Failure, Unit>> deactivateBeneficiary(String beneficiaryId);
}
