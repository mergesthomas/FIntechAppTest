import 'package:fintech_app_test/core/auth/access_guards.dart';
import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/core/settlement/settlement_status.dart';
import 'package:fintech_app_test/features/all_loans/domain/entities/borrow_quote.dart';
import 'package:fintech_app_test/features/all_loans/domain/entities/credit_line_optimization.dart';
import 'package:fintech_app_test/features/all_loans/domain/entities/loan_product.dart';
import 'package:fintech_app_test/features/all_loans/domain/repositories/borrow_repository.dart';
import 'package:fintech_app_test/features/all_loans/domain/usecases/borrow/borrow_repay_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_auth.dart';

class MockBorrowRepository extends Mock implements BorrowRepository {}

void main() {
  late MockAuthPort auth;
  late MockBorrowRepository borrow;
  late SubmitBorrow submit;

  final amount = Money.parse('100', Currency.xusd);

  setUpAll(registerAuthFallbacks);

  setUp(() {
    auth = MockAuthPort();
    borrow = MockBorrowRepository();
    submit = SubmitBorrow(AccessGuards(auth), borrow);
    stubSignedIn(auth);
  });

  test('refuses a disconnected LTV quote', () async {
    when(() => borrow.getQuoteById('q1')).thenAnswer(
      (_) async => Either.right(
        BorrowQuote(
          quoteId: 'q1',
          product: LoanProductKind.classic,
          amount: amount,
          freshness: QuoteFreshness.disconnected,
        ),
      ),
    );

    final result = await submit(
      SubmitBorrowParams(
        requestId: 'req-1',
        quoteId: 'q1',
        product: LoanProductKind.classic,
        amount: amount,
        stepUpVerified: true,
      ),
    );

    expect(
      result,
      Either<Failure, LoanSettlement>.left(
        const StaleQuoteFailure(QuoteFreshness.disconnected),
      ),
    );
  });

  test('returns inFlight when quote is live', () async {
    when(() => borrow.getQuoteById('q1')).thenAnswer(
      (_) async => Either.right(
        BorrowQuote(
          quoteId: 'q1',
          product: LoanProductKind.classic,
          amount: amount,
          freshness: QuoteFreshness.live,
        ),
      ),
    );
    when(
      () => borrow.submitBorrow(
        requestId: 'req-1',
        quoteId: 'q1',
        product: LoanProductKind.classic,
        amount: amount,
      ),
    ).thenAnswer(
      (_) async => Either.right(
        const LoanSettlement(
          requestId: 'req-1',
          status: SettlementStatus.inFlight,
        ),
      ),
    );

    final result = await submit(
      SubmitBorrowParams(
        requestId: 'req-1',
        quoteId: 'q1',
        product: LoanProductKind.classic,
        amount: amount,
        stepUpVerified: true,
      ),
    );

    expect(result.getRight().toNullable()?.status, SettlementStatus.inFlight);
  });
}
