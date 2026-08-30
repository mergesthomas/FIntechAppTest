import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/settlement/settlement_status.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/funding/data/datasources/funding_local_datasource.dart';
import 'package:fintech_app_test/features/funding/data/repositories/funding_repository_impl.dart';
import 'package:fintech_app_test/features/funding/domain/usecases/funding_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/paper_harness.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late FundingRepositoryImpl repo;
  late CreatePersonalUsdAccount create;

  setUp(() {
    auth = MockAuthRepository();
    final paper = PaperHarness();
    repo = FundingRepositoryImpl(
      FundingLocalDataSource(),
      feed: paper.feed,
      ledger: paper.ledger,
    );
    create = CreatePersonalUsdAccount(
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

  test('refuses without step-up', () async {
    final result = await create((requestId: 'usd-1', stepUp: false));
    expect(result.getLeft().toNullable(), isA<StepUpFailure>());
  });

  test('requires terms then returns inFlight and is idempotent', () async {
    await repo.acceptFiatAccountTerms();
    final first = await create((requestId: 'usd-1', stepUp: true));
    final retry = await create((requestId: 'usd-1', stepUp: true));
    expect(first.getRight().toNullable(), SettlementStatus.inFlight);
    expect(retry.getRight().toNullable(), SettlementStatus.inFlight);
  });

  test('refuses without terms', () async {
    final result = await create((requestId: 'usd-1', stepUp: true));
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
  });
}
