import '../clock/app_clock.dart';

/// Mints one client request id per submit intent.
///
/// The id is created when the intent is formed (preview), not when the user
/// taps confirm, so a retry of the same intent reuses it and the ledger can
/// dedupe. A new intent must mint a new id.
abstract class RequestIdFactory {
  String next(String prefix);
}

final class ClockRequestIdFactory implements RequestIdFactory {
  ClockRequestIdFactory({AppClock clock = const SystemClock()})
    : _clock = clock;

  final AppClock _clock;
  var _sequence = 0;

  @override
  String next(String prefix) {
    _sequence++;
    return '$prefix-${_clock.now().microsecondsSinceEpoch}-$_sequence';
  }
}
