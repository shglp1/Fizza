import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String? email;
  final String? phoneNumber;
  final String? displayName;
  final String? photoUrl;
  final String role; // 'user', 'driver', 'admin'

  const UserEntity({
    required this.id,
    this.email,
    this.phoneNumber,
    this.displayName,
    this.photoUrl,
    required this.role,
  });

  @override
  List<Object?> get props => [id, email, phoneNumber, displayName, photoUrl, role];
}
