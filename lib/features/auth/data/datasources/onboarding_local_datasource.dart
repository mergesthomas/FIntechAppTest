import '../../domain/entities/onboarding_slide.dart';

final class OnboardingLocalDataSource {
  const OnboardingLocalDataSource();

  List<OnboardingSlide> slides() {
    return const [
      OnboardingSlide(
        titleKey: 'onboarding.grow.title',
        bodyKey: 'onboarding.grow.body',
        showAuthActions: true,
      ),
      OnboardingSlide(
        titleKey: 'onboarding.exchange.title',
        bodyKey: 'onboarding.exchange.body',
        showAuthActions: false,
      ),
      OnboardingSlide(
        titleKey: 'onboarding.card.title',
        bodyKey: 'onboarding.card.body',
        showAuthActions: false,
      ),
    ];
  }
}
