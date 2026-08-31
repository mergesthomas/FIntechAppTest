import 'package:fintech_app_test/core/ledger/paper_order.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/core/settlement/settlement_status.dart';
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
  test('live quote swap confirms and logs a market order', () async {
    final auth = MockAuthRepository();
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
    final paper = PaperHarness(freshness: QuoteFreshness.live);
    final repo = SwapRepositoryImpl(
      SwapLocalDataSource(),
      feed: paper.feed,
      ledger: paper.ledger,
    );
    final quoted = await GetSwapQuote(
      RequireSession(auth),
      GetEligibility(auth),
      repo,
    )(
      SwapQuoteRequest(
        from: Currency.usdc,
        to: Currency.eurx,
        amount: Money.parse('10', Currency.usdc),
        type: SwapOrderType.instant,
      ),
    );
    final quote = quoted.getRight().toNullable();
    expect(quote?.freshness, QuoteFreshness.live);
    final submitted = await SubmitSwap(
      RequireSession(auth),
      GetEligibility(auth),
      repo,
    )((
      requestId: 'swap-live-1',
      quoteId: quote!.quoteId,
      wallet: SwapWallet.savings,
      stepUp: true,
    ));
    expect(
      submitted.getRight().toNullable()?.settlement,
      SettlementStatus.confirmed,
    );
    expect(paper.store.all, isNotEmpty);
    expect(paper.store.all.first.venue, PaperVenue.market);
    expect(paper.store.all.first.status, PaperOrderStatus.filled);
  });

  test('live limit swap holds from and stays open', () async {
    final auth = MockAuthRepository();
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
    final paper = PaperHarness(freshness: QuoteFreshness.live);
    final repo = SwapRepositoryImpl(
      SwapLocalDataSource(),
      feed: paper.feed,
      ledger: paper.ledger,
    );
    final instant = await GetSwapQuote(
      RequireSession(auth),
      GetEligibility(auth),
      repo,
    )(
      SwapQuoteRequest(
        from: Currency.usdc,
        to: Currency.doge,
        amount: Money.parse('10', Currency.usdc),
        type: SwapOrderType.instant,
      ),
    );
    final rate = instant.getRight().toNullable()!.rateFromPerTo;
    final quoted = await GetSwapQuote(
      RequireSession(auth),
      GetEligibility(auth),
      repo,
    )(
      SwapQuoteRequest(
        from: Currency.usdc,
        to: Currency.doge,
        amount: Money.parse('10', Currency.usdc),
        type: SwapOrderType.limit,
        limitPrice: Money.fromDecimal(
          rate.amount - Money.parse('0.01', Currency.usdc).amount,
          Currency.usdc,
        ),
      ),
    );
    final quote = quoted.getRight().toNullable();
    expect(quote?.type, SwapOrderType.limit);
    final submitted = await SubmitSwap(
      RequireSession(auth),
      GetEligibility(auth),
      repo,
    )((
      requestId: 'swap-limit-1',
      quoteId: quote!.quoteId,
      wallet: SwapWallet.savings,
      stepUp: true,
    ));
    expect(
      submitted.getRight().toNullable()?.settlement,
      SettlementStatus.confirmed,
    );
    expect(paper.store.all.first.venue, PaperVenue.limit);
    expect(paper.store.all.first.status, PaperOrderStatus.open);
  });
}
