import 'package:equatable/equatable.dart';

/// Opaque handle. The PIN itself never leaves the repository.
final class PinDraft extends Equatable {
  const PinDraft({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}
