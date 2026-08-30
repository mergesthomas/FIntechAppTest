import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/funding/domain/entities/funding.dart';
import 'package:fintech_app_test/features/funding/domain/repositories/funding_repository.dart';
import 'package:fintech_app_test/features/funding/domain/usecases/funding_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockFundingRepository extends Mock implements FundingRepository {}

void main() {
  late MockAuthRepository auth;
  late MockFundingRepository funding;
  late SubmitBuyCrypto submit;
  late Money spend;

  setUpAll(() {
    registerFallbackValue(Money.zero(Currency.usd));
    registerFallbackValue('');
  });

  setUp(() {
    auth = MockAuthRepository();
    funding = MockFundingRepository();
    spend = Money.parse('100', Currency.usd);
    submit = SubmitBuyCrypto(
      RequireSession(auth),
      GetEligibility(auth),
      funding,
    );
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  BuyQuote staleQuote() => BuyQuote(
        quoteId: 'q1',
        spend: spend,
        receive: Money.parse('0.001', Currency.btc),
        cashbackTeaser: 'placeholder',
        freshness: QuoteFreshness.stale,
      );

  test('refuses without step-up', () async {
    final result = await submit((
      requestId: 'buy-1',
      quoteId: 'q1',
      paymentMethodId: 'visa',
      amount: spend,
      frequency: 'Instant',
      stepUp: false,
    ));
    expect(result.getLeft().toNullable(), isA<StepUpFailure>());
    verifyNever(
      () => funding.submitBuy(
        requestId: any(named: 'requestId'),
        quoteId: any(named: 'quoteId'),
        paymentMethodId: any(named: 'paymentMethodId'),
        amount: any(named: 'amount'),
        frequency: any(named: 'frequency'),
      ),
    );
  });

  test('refuses a stale quote and never posts the buy', () async {
    when(() => funding.getBuyQuoteById('q1')).thenAnswer(
      (_) async => Either.right(staleQuote()),
    );

    final result = await submit((
      requestId: 'buy-1',
      quoteId: 'q1',
      paymentMethodId: 'visa',
      amount: spend,
      frequency: 'Instant',
      stepUp: true,
    ));

    expect(result.getLeft().toNullable(), isA<StaleQuoteFailure>());
    verifyNever(
      () => funding.submitBuy(
        requestId: any(named: 'requestId'),
        quoteId: any(named: 'quoteId'),
        paymentMethodId: any(named: 'paymentMethodId'),
        amount: any(named: 'amount'),
        frequency: any(named: 'frequency'),
      ),
    );
  });

  test('refuses without a session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    final result = await submit((
      requestId: 'buy-1',
      quoteId: 'q1',
      paymentMethodId: 'visa',
      amount: spend,
      frequency: 'Instant',
      stepUp: true,
    ));
    expect(result.getLeft().toNullable(), isA<SessionFailure>());
  });
}
