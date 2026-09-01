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
  card('/card'),
  swap('/swap'),
  orders('/orders'),
  market('/market'),
  watchlistAdd('/watchlist/add');

  const AppRoute(this.path);

  final String path;
}
