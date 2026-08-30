import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/futures/domain/entities/futures.dart';
import 'package:fintech_app_test/features/futures/domain/repositories/futures_repository.dart';
import 'package:fintech_app_test/features/futures/domain/usecases/futures_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockFuturesRepository extends Mock implements FuturesRepository {}

void main() {
  late MockAuthRepository auth;
  late MockFuturesRepository repo;
  late SubmitFuturesOrder submit;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    auth = MockAuthRepository();
    repo = MockFuturesRepository();
    submit = SubmitFuturesOrder(
      RequireSession(auth),
      GetEligibility(auth),
      repo,
    );
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  test('refuses a stale quote and never posts the order', () async {
    when(() => repo.getQuoteById('q1')).thenAnswer(
      (_) async => Either.right(
        FuturesQuote(
          quoteId: 'q1',
          side: FuturesSide.long,
          size: Money.parse('0.01', Currency.btc),
          leverageTeaser: '100x',
          freshness: QuoteFreshness.stale,
        ),
      ),
    );
    final result = await submit((
      requestId: 'fut-1',
      quoteId: 'q1',
      stepUp: true,
    ));
    expect(result.getLeft().toNullable(), isA<StaleQuoteFailure>());
    verifyNever(
      () => repo.submit(
        requestId: any(named: 'requestId'),
        quoteId: any(named: 'quoteId'),
      ),
    );
  });

  test('refuses submit without step-up', () async {
    final result = await submit((
      requestId: 'fut-1',
      quoteId: 'q1',
      stepUp: false,
    ));
    expect(result.getLeft().toNullable(), isA<StepUpFailure>());
  });
}
