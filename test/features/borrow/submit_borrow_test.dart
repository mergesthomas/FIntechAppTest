import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/borrow/domain/entities/borrow.dart';
import 'package:fintech_app_test/features/borrow/domain/repositories/borrow_repository.dart';
import 'package:fintech_app_test/features/borrow/domain/usecases/borrow_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockBorrowRepository extends Mock implements BorrowRepository {}

void main() {
  late MockAuthRepository auth;
  late MockBorrowRepository repo;
  late SubmitBorrow submit;
  late Money amount;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    auth = MockAuthRepository();
    repo = MockBorrowRepository();
    amount = Money.parse('100', Currency.usdc);
    submit = SubmitBorrow(RequireSession(auth), GetEligibility(auth), repo);
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  test('refuses without step-up', () async {
    final result = await submit((
      requestId: 'borrow-1',
      quoteId: 'q1',
      stepUp: false,
    ));
    expect(result.getLeft().toNullable(), isA<StepUpFailure>());
  });

  test('refuses a stale LTV quote', () async {
    when(() => repo.getBorrowQuoteById('q1')).thenAnswer(
      (_) async => Either.right(
        BorrowQuote(
          quoteId: 'q1',
          productId: 'classic',
          amount: amount,
          ltvTeaser: '50%',
          freshness: QuoteFreshness.stale,
        ),
      ),
    );
    final result = await submit((
      requestId: 'borrow-1',
      quoteId: 'q1',
      stepUp: true,
    ));
    expect(result.getLeft().toNullable(), isA<StaleQuoteFailure>());
    verifyNever(
      () => repo.submitBorrow(
        requestId: any(named: 'requestId'),
        quoteId: any(named: 'quoteId'),
      ),
    );
  });
}
