enum QuoteFreshness { live, stale, disconnected }

extension QuoteFreshnessLabel on QuoteFreshness {
  /// Live is the healthy default — do not print it. Stale / disconnected stay visible.
  String? get statusLabel => switch (this) {
        QuoteFreshness.live => null,
        QuoteFreshness.stale || QuoteFreshness.disconnected => name,
      };

  String labeled(String name) {
    final status = statusLabel;
    return status == null ? name : '$name · $status';
  }
}
