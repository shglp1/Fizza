import 'package:equatable/equatable.dart';

class FamilyMemberEntity extends Equatable {
  final String id;
  final String parentId;
  final String name;
  final String? photoUrl;
  final String? schoolName;
  final String? grade;
  final bool isSpecialNeeds; // For accessibility/assistant features

  const FamilyMemberEntity({
    required this.id,
    required this.parentId,
    required this.name,
    this.photoUrl,
    this.schoolName,
    this.grade,
    this.isSpecialNeeds = false,
  });

  @override
  List<Object?> get props => [id, parentId, name, photoUrl, schoolName, grade, isSpecialNeeds];
}
