/// Flavor values. No production keys. Remote URLs stay empty until a feed exists.
final class FlavorConfig {
  const FlavorConfig({
    required this.name,
    required this.emulatorSmsCode,
    required this.smsResendCooldown,
    required this.marketRestUrl,
    required this.marketWsUrl,
  });

  final String name;
  final String emulatorSmsCode;
  final Duration smsResendCooldown;
  final String marketRestUrl;
  final String marketWsUrl;

  static const dev = FlavorConfig(
    name: 'dev',
    emulatorSmsCode: '123456',
    smsResendCooldown: Duration(seconds: 30),
    marketRestUrl: 'https://api.binance.com',
    marketWsUrl: 'wss://stream.binance.com:9443',
  );
}
