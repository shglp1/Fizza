import 'package:fizza_domain/fizza_domain.dart';

class BeneficiaryModel extends BeneficiaryEntity {
  const BeneficiaryModel({
    required super.id,
    required super.parentUserId,
    required super.fullName,
    required super.relation,
    super.schoolName,
    super.grade,
    super.age,
    super.isActive,
  });

  factory BeneficiaryModel.fromJson(Map<String, dynamic> json, String id) {
    return BeneficiaryModel(
      id: id,
      parentUserId: json['parent_user_id'] as String,
      fullName: json['full_name'] as String,
      relation: json['relation'] as String,
      schoolName: json['school_name'] as String?,
      grade: json['grade'] as String?,
      age: json['age'] as int?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parent_user_id': parentUserId,
      'full_name': fullName,
      'relation': relation,
      'school_name': schoolName,
      'grade': grade,
      'age': age,
      'is_active': isActive,
    };
  }

  factory BeneficiaryModel.fromEntity(BeneficiaryEntity entity) {
    return BeneficiaryModel(
      id: entity.id,
      parentUserId: entity.parentUserId,
      fullName: entity.fullName,
      relation: entity.relation,
      schoolName: entity.schoolName,
      grade: entity.grade,
      age: entity.age,
      isActive: entity.isActive,
    );
  }
}
