import 'package:equatable/equatable.dart';

class BeneficiaryEntity extends Equatable {
  final String id;
  final String parentUserId;
  final String fullName;
  final String relation; // e.g., 'child', 'sibling', 'spouse'
  final String? schoolName;
  final String? grade;
  final int? age;
  final bool isActive;

  const BeneficiaryEntity({
    required this.id,
    required this.parentUserId,
    required this.fullName,
    required this.relation,
    this.schoolName,
    this.grade,
    this.age,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
        id,
        parentUserId,
        fullName,
        relation,
        schoolName,
        grade,
        age,
        isActive,
      ];
}
