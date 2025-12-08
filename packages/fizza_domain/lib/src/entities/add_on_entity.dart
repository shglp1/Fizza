import 'package:equatable/equatable.dart';

class AddOnEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final bool isMonthly;

  const AddOnEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.isMonthly = true,
  });

  @override
  List<Object> get props => [id, name, description, price, isMonthly];
}
