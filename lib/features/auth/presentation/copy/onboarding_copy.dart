/// Screenshot marketing text. COMPLIANCE: do not ship as legal APY/fee copy.
abstract final class OnboardingCopy {
  static const titles = {
    'onboarding.grow.title': 'Grow and preserve your wealth',
    'onboarding.exchange.title': 'Exchange over 100 digital assets',
    'onboarding.card.title': 'Spend with the Card',
  };

  static const bodies = {
    'onboarding.grow.body': 'Join clients who use the app.',
    'onboarding.exchange.body': 'Swap assets in the app.',
    'onboarding.card.body': 'Credit vs Debit mode.',
  };

  static String title(String key) => titles[key] ?? key;

  static String body(String key) => bodies[key] ?? key;
}
