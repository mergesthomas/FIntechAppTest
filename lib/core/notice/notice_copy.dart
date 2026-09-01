/// User-facing notice copy. Not legal, fee, or APY text.
abstract final class NoticeCopy {
  static const retry = 'Retry';
  static const genericError = 'Something went wrong. Try again.';
  static const sessionExpired = 'Sign in to continue.';
  static const notEligible = 'This action is not available on this account.';
  static const staleQuote = 'Prices are outdated. Try again when they are live.';
  static const stepUpRequired = 'Confirm with PIN to continue.';
  static const feedDisconnected =
      'Market data is offline. Prices may be outdated.';
  static const unavailable = 'This isn’t available yet.';
  static const watchlistAddBusy = 'Could not update your watchlist. Try again.';

  static String watchlistAdded(String code) =>
      'Added $code to your watchlist.';
}
