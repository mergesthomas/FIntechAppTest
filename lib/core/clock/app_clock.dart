abstract class AppClock {
  DateTime now();
}

final class SystemClock implements AppClock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

final class MutableClock implements AppClock {
  MutableClock([DateTime? seed]) : _now = seed ?? DateTime.utc(2026, 1, 1);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration delta) => _now = _now.add(delta);
}
