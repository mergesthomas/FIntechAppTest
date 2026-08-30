import 'package:equatable/equatable.dart';

final class OnboardingSlide extends Equatable {
  const OnboardingSlide({
    required this.titleKey,
    required this.bodyKey,
    required this.showAuthActions,
  });

  final String titleKey;
  final String bodyKey;
  final bool showAuthActions;

  @override
  List<Object?> get props => [titleKey, bodyKey, showAuthActions];
}
