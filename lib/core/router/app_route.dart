enum AppRoute {
  onboarding('/onboarding'),
  login('/login'),
  signUp('/signup'),
  verifySms('/verify-sms'),
  createPin('/create-pin'),
  confirmPin('/confirm-pin'),
  enableBiometric('/enable-biometric'),
  home('/home');

  const AppRoute(this.path);

  final String path;
}
