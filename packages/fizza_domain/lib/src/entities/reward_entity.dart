import 'package:equatable/equatable.dart';

class RewardEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final int cost;
  final String imageUrl;
  final bool isAvailable;

  const RewardEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.imageUrl,
    this.isAvailable = true,
  });

  @override
  List<Object> get props => [id, name, description, cost, imageUrl, isAvailable];
}
