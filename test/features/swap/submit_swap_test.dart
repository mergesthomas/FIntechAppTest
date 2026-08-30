import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/swap/domain/entities/swap.dart';
import 'package:fintech_app_test/features/swap/domain/repositories/swap_repository.dart';
import 'package:fintech_app_test/features/swap/domain/usecases/swap_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSwapRepository extends Mock implements SwapRepository {}

void main() {
  late MockAuthRepository auth;
  late MockSwapRepository repo;
  late SubmitSwap submit;

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(SwapWallet.savings);
  });

  setUp(() {
    auth = MockAuthRepository();
    repo = MockSwapRepository();
    submit = SubmitSwap(RequireSession(auth), GetEligibility(auth), repo);
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  test('refuses a stale quote and never posts the swap', () async {
    when(() => repo.getQuoteById('q1')).thenAnswer(
      (_) async => Either.right(
        SwapQuote(
          quoteId: 'q1',
          from: Money.parse('10', Currency.nexo),
          to: Money.parse('1', Currency.eurx),
          wallet: SwapWallet.savings,
          freshness: QuoteFreshness.stale,
        ),
      ),
    );
    final result = await submit((
      requestId: 'swap-1',
      quoteId: 'q1',
      wallet: SwapWallet.savings,
      stepUp: true,
    ));
    expect(result.getLeft().toNullable(), isA<StaleQuoteFailure>());
    verifyNever(
      () => repo.submit(
        requestId: any(named: 'requestId'),
        quoteId: any(named: 'quoteId'),
        wallet: any(named: 'wallet'),
      ),
    );
  });
}
