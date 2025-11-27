import 'package:equatable/equatable.dart';

enum AdminRole { superAdmin, support, finance, manager }

class AdminUserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final AdminRole role;
  final List<String> permissions;

  const AdminUserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.permissions,
  });

  @override
  List<Object> get props => [id, email, name, role, permissions];
}
