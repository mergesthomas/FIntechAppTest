import 'package:fintech_app_test/core/auth/access_guards.dart';
import 'package:fintech_app_test/core/auth/eligibility_status.dart';
import 'package:fintech_app_test/core/auth/product_area.dart';
import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/core/settlement/settlement_status.dart';
import 'package:fintech_app_test/features/add_funds/domain/entities/bank_transfer.dart';
import 'package:fintech_app_test/features/add_funds/domain/entities/buy_crypto.dart';
import 'package:fintech_app_test/features/add_funds/domain/repositories/buy_crypto_repository.dart';
import 'package:fintech_app_test/features/add_funds/domain/usecases/buy/buy_submit_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_auth.dart';

class MockBuyCryptoRepository extends Mock implements BuyCryptoRepository {}

void main() {
  late MockAuthPort auth;
  late MockBuyCryptoRepository buy;
  late SubmitBuyCrypto submit;

  final amount = Money.parse('500', Currency.eur);
  final liveQuote = BuyQuote(
    quoteId: 'q1',
    fiatIn: amount,
    cryptoOut: Money.parse('6446.97955203', Currency.doge),
    cashbackCopyKey: 'buy.cashback.placeholder',
    freshness: QuoteFreshness.live,
  );

  SubmitBuyCryptoParams params({
    bool stepUp = true,
    Money? fiat,
    String quoteId = 'q1',
  }) {
    return SubmitBuyCryptoParams(
      requestId: 'req-1',
      quoteId: quoteId,
      paymentMethodId: 'card-8766',
      amount: fiat ?? amount,
      frequency: PurchaseFrequency.oneTime,
      stepUpVerified: stepUp,
    );
  }

  setUpAll(registerAuthFallbacks);

  setUp(() {
    auth = MockAuthPort();
    buy = MockBuyCryptoRepository();
    submit = SubmitBuyCrypto(AccessGuards(auth), buy);
    stubSignedIn(auth);
  });

  test('refuses without a session', () async {
    stubSignedOut(auth);

    final result = await submit(params());

    expect(result, Either<Failure, FundingSettlement>.left(const SessionFailure()));
    verifyNever(() => buy.submitBuy(
          requestId: any(named: 'requestId'),
          quoteId: any(named: 'quoteId'),
          paymentMethodId: any(named: 'paymentMethodId'),
          amount: any(named: 'amount'),
          frequency: any(named: 'frequency'),
        ));
  });

  test('refuses when KYC is not approved', () async {
    stubEligibility(auth, ProductArea.funding, EligibilityStatus.unknown);

    final result = await submit(params());

    expect(
      result,
      Either<Failure, FundingSettlement>.left(
        const EligibilityFailure(EligibilityStatus.unknown),
      ),
    );
  });

  test('refuses without step-up', () async {
    final result = await submit(params(stepUp: false));

    expect(
      result,
      Either<Failure, FundingSettlement>.left(const StepUpRequiredFailure()),
    );
  });

  test('refuses a stale quote', () async {
    when(() => buy.getQuoteById('q1')).thenAnswer(
      (_) async => Either.right(
        BuyQuote(
          quoteId: 'q1',
          fiatIn: amount,
          cryptoOut: Money.parse('1', Currency.doge),
          cashbackCopyKey: 'buy.cashback.placeholder',
          freshness: QuoteFreshness.stale,
        ),
      ),
    );

    final result = await submit(params());

    expect(
      result,
      Either<Failure, FundingSettlement>.left(
        const StaleQuoteFailure(QuoteFreshness.stale),
      ),
    );
  });

  test('returns inFlight settlement on submit', () async {
    when(() => buy.getQuoteById('q1')).thenAnswer(
      (_) async => Either.right(liveQuote),
    );
    when(
      () => buy.submitBuy(
        requestId: 'req-1',
        quoteId: 'q1',
        paymentMethodId: 'card-8766',
        amount: amount,
        frequency: PurchaseFrequency.oneTime,
      ),
    ).thenAnswer(
      (_) async => Either.right(
        const FundingSettlement(
          requestId: 'req-1',
          status: SettlementStatus.inFlight,
        ),
      ),
    );

    final result = await submit(params());

    expect(
      result,
      Either<Failure, FundingSettlement>.right(
        const FundingSettlement(
          requestId: 'req-1',
          status: SettlementStatus.inFlight,
        ),
      ),
    );
  });
}
