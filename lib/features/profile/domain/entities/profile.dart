import 'package:equatable/equatable.dart';

final class ProfileOverview extends Equatable {
  const ProfileOverview({
    required this.greeting,
    required this.loyaltyTier,
    required this.isPrivate,
  });

  final String greeting;
  final String loyaltyTier;
  final bool isPrivate;

  @override
  List<Object?> get props => [greeting, loyaltyTier, isPrivate];
}

final class ProfileShortcut extends Equatable {
  const ProfileShortcut({required this.id, required this.label});

  final String id;
  final String label;

  @override
  List<Object?> get props => [id, label];
}
