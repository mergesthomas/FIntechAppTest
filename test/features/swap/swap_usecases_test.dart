import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/swap/data/datasources/swap_local_datasource.dart';
import 'package:fintech_app_test/features/swap/data/repositories/swap_repository_impl.dart';
import 'package:fintech_app_test/features/swap/domain/entities/swap.dart';
import 'package:fintech_app_test/features/swap/domain/usecases/swap_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/paper_harness.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late GetSwapQuote getQuote;

  setUp(() {
    auth = MockAuthRepository();
    final paper = PaperHarness(freshness: QuoteFreshness.live);
    final repo = SwapRepositoryImpl(
      SwapLocalDataSource(),
      feed: paper.feed,
      ledger: paper.ledger,
    );
    getQuote = GetSwapQuote(RequireSession(auth), GetEligibility(auth), repo);
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  test('instant quote is live', () async {
    final result = await getQuote(
      SwapQuoteRequest(
        from: Currency.usdc,
        to: Currency.doge,
        amount: Money.parse('10', Currency.usdc),
        type: SwapOrderType.instant,
      ),
    );
    expect(result.getRight().toNullable()?.freshness, QuoteFreshness.live);
    expect(result.getRight().toNullable()?.type, SwapOrderType.instant);
  });

  test('limit requires a better price than live', () async {
    final live = await getQuote(
      SwapQuoteRequest(
        from: Currency.usdc,
        to: Currency.doge,
        amount: Money.parse('10', Currency.usdc),
        type: SwapOrderType.instant,
      ),
    );
    final rate = live.getRight().toNullable()!.rateFromPerTo;
    final worse = await getQuote(
      SwapQuoteRequest(
        from: Currency.usdc,
        to: Currency.doge,
        amount: Money.parse('10', Currency.usdc),
        type: SwapOrderType.limit,
        limitPrice: Money.fromDecimal(
          rate.amount + Money.parse('1', Currency.usdc).amount,
          Currency.usdc,
        ),
      ),
    );
    expect(
      worse.getLeft().toNullable(),
      const ValidationFailure('limit_not_better'),
    );
  });

  test('trigger refuses when neither TP nor SL is set', () async {
    final result = await getQuote(
      SwapQuoteRequest(
        from: Currency.usdc,
        to: Currency.doge,
        amount: Money.parse('10', Currency.usdc),
        type: SwapOrderType.trigger,
      ),
    );
    expect(
      result.getLeft().toNullable(),
      const ValidationFailure('trigger_price_required'),
    );
  });

  test('same asset pair is invalid', () async {
    final result = await getQuote(
      SwapQuoteRequest(
        from: Currency.usdc,
        to: Currency.usdc,
        amount: Money.parse('10', Currency.usdc),
        type: SwapOrderType.instant,
      ),
    );
    expect(
      result.getLeft().toNullable(),
      const ValidationFailure('pair_invalid'),
    );
  });
}
