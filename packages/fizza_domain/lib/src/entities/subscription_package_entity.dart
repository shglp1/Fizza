import 'package:equatable/equatable.dart';

class SubscriptionPackageEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final int ridesIncluded;
  final int durationDays;
  final bool isFamilyPackage;
  final int maxFamilyMembers;

  const SubscriptionPackageEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.ridesIncluded,
    required this.durationDays,
    this.isFamilyPackage = false,
    this.maxFamilyMembers = 0,
  });

  @override
  List<Object> get props => [id, name, description, price, ridesIncluded, durationDays, isFamilyPackage, maxFamilyMembers];
}
