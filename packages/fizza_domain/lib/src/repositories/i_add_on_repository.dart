import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import '../entities/add_on_entity.dart';

abstract class IAddOnRepository {
  Future<Either<Failure, List<AddOnEntity>>> getAddOns();
  Future<Either<Failure, Unit>> addAddOn(AddOnEntity addOn);
  Future<Either<Failure, Unit>> updateAddOn(AddOnEntity addOn);
  Future<Either<Failure, Unit>> deleteAddOn(String addOnId);
}
