enum AppRoute {
  onboarding('/onboarding'),
  login('/login'),
  signUp('/signup'),
  verifySms('/verify-sms'),
  createPin('/create-pin'),
  confirmPin('/confirm-pin'),
  enableBiometric('/enable-biometric'),
  home('/home'),
  profile('/profile'),
  products('/products'),
  security('/security'),
  inbox('/inbox'),
  news('/news'),
  explore('/explore'),
  funding('/funding'),
  borrow('/borrow'),
  earn('/earn'),
  card('/card'),
  swap('/swap'),
  orders('/orders'),
  futures('/futures'),
  market('/market');

  const AppRoute(this.path);

  final String path;
}
