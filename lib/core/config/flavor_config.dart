/// Flavor values. No production keys. Remote URLs stay empty until a feed exists.
final class FlavorConfig {
  const FlavorConfig({
    required this.name,
    required this.emulatorSmsCode,
    required this.smsResendCooldown,
  });

  final String name;
  final String emulatorSmsCode;
  final Duration smsResendCooldown;

  static const dev = FlavorConfig(
    name: 'dev',
    emulatorSmsCode: '123456',
    smsResendCooldown: Duration(seconds: 30),
  );
}
