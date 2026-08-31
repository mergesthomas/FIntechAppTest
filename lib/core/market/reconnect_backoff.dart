/// Exponential backoff for market sockets. Reset only after a real payload.
final class ReconnectBackoff {
  ReconnectBackoff({
    this.initial = const Duration(seconds: 1),
    this.max = const Duration(seconds: 30),
  }) : _current = initial;

  final Duration initial;
  final Duration max;
  Duration _current;

  Duration get current => _current;

  Duration next() {
    final delay = _current;
    final doubled = _current * 2;
    _current = doubled > max ? max : doubled;
    return delay;
  }

  void reset() {
    _current = initial;
  }
}
