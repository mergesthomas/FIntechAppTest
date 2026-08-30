import 'package:equatable/equatable.dart';

final class ProductTile extends Equatable {
  const ProductTile({
    required this.id,
    required this.label,
    required this.group,
    required this.enabled,
  });

  final String id;
  final String label;
  final String group;
  final bool enabled;

  @override
  List<Object?> get props => [id, label, group, enabled];
}
