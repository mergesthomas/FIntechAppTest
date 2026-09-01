import '../error/failure.dart';
import 'notice_copy.dart';

/// Maps domain [Failure] values to copy. Never returns a type name or reason
/// code — those stay off the UI.
abstract final class FailureMessage {
  static String map(Failure failure) {
    return switch (failure) {
      SessionFailure() => NoticeCopy.sessionExpired,
      EligibilityFailure() => NoticeCopy.notEligible,
      StaleQuoteFailure() => NoticeCopy.staleQuote,
      StepUpFailure() => NoticeCopy.stepUpRequired,
      ValidationFailure(:final reason) => _validation(reason),
      AuthFailure(:final reason) => _auth(reason),
      ServerFailure(:final reason) => _server(reason),
    };
  }

  static String _validation(String reason) {
    return switch (reason) {
      'unknown_asset' => 'This asset isn’t available yet.',
      'watchlist_unknown_asset' => 'That coin can’t be added to the watchlist.',
      'watchlist_already_contains' => 'That coin is already on your watchlist.',
      'watchlist_add_busy' => NoticeCopy.watchlistAddBusy,
      'invalid_phone' => 'Enter a valid mobile number.',
      'sms_code_must_be_6_digits' => 'Enter the 6-digit SMS code.',
      'pin_must_be_4_digits' => 'Enter a 4-digit PIN.',
      'locale_required' => 'Choose a language to continue.',
      'alert_id_required' => NoticeCopy.genericError,
      'request_id_required' => NoticeCopy.genericError,
      'insufficient_balance' => 'Not enough balance for this order.',
      'amount_required' || 'amount_invalid' => 'Enter a valid amount.',
      'order_not_found' => 'That order is no longer available.',
      'order_not_open' => 'That order is no longer open.',
      'order_id_required' => NoticeCopy.genericError,
      'quote_not_found' || 'quote_invalid' =>
        'That quote expired. Request a new one.',
      'order_book_unavailable' => 'The order book is unavailable for this asset.',
      'order_book_depth_invalid' => 'The order book is unavailable for this asset.',
      'book_level_unknown' => 'Could not use that price.',
      'pair_invalid' => 'Choose a valid pair to continue.',
      'limit_required' ||
      'limit_not_better' => 'Enter a valid limit price.',
      'trigger_price_required' => 'Enter a valid trigger price.',
      'price_currency_mismatch' => 'That price does not match this pair.',
      'take_profit_not_better' => 'Enter a valid take-profit price.',
      'stop_loss_not_worse' => 'Enter a valid stop-loss price.',
      'balance_not_eligible' => 'Restore is not available for this card.',
      _ => NoticeCopy.genericError,
    };
  }

  static String _auth(String reason) {
    return switch (reason) {
      'invalid_sms_code' => 'That SMS code is not valid.',
      'sms_resend_cooldown' => 'Wait a moment before resending the code.',
      'no_pending_auth' => 'Start again from the phone number screen.',
      'sms_not_verified' => 'Verify the SMS code to continue.',
      'pin_draft_missing' => 'Create a PIN to continue.',
      'pin_mismatch' => 'Those PINs do not match.',
      'pin_not_confirmed' => 'Confirm your PIN to continue.',
      'biometric_failed' => 'Face ID could not be enabled. Try again or skip.',
      _ => NoticeCopy.genericError,
    };
  }

  static String _server(String? reason) {
    return switch (reason) {
      'dashboard_partial_failure' => 'Could not load your dashboard. Try again.',
      'profile_partial_failure' => 'Could not load your profile. Try again.',
      'watchlist_add_busy' => NoticeCopy.watchlistAddBusy,
      _ => NoticeCopy.genericError,
    };
  }
}
