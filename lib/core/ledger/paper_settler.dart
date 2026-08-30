abstract class PaperSettler {
  Future<void> schedule(String requestId, void Function() apply);
}

final class ImmediatePaperSettler implements PaperSettler {
  const ImmediatePaperSettler();

  @override
  Future<void> schedule(String requestId, void Function() apply) async {
    apply();
  }
}

final class DelayedPaperSettler implements PaperSettler {
  const DelayedPaperSettler({
    this.delay = const Duration(milliseconds: 400),
  });

  final Duration delay;

  @override
  Future<void> schedule(String requestId, void Function() apply) async {
    await Future<void>.delayed(delay);
    apply();
  }
}
