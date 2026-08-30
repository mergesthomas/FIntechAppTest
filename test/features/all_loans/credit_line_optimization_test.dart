import 'package:fintech_app_test/core/auth/access_guards.dart';
import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/settlement/settlement_status.dart';
import 'package:fintech_app_test/features/all_loans/domain/entities/credit_line_optimization.dart';
import 'package:fintech_app_test/features/all_loans/domain/entities/loan_product.dart';
import 'package:fintech_app_test/features/all_loans/domain/repositories/credit_line_settings_repository.dart';
import 'package:fintech_app_test/features/all_loans/domain/usecases/settings/credit_line_optimization_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_auth.dart';

class MockCreditLineSettingsRepository extends Mock
    implements CreditLineSettingsRepository {}

void main() {
  late MockAuthPort auth;
  late MockCreditLineSettingsRepository settings;
  late UpdateCreditLineOptimization update;

  setUpAll(registerAuthFallbacks);

  setUp(() {
    auth = MockAuthPort();
    settings = MockCreditLineSettingsRepository();
    update = UpdateCreditLineOptimization(AccessGuards(auth), settings);
    stubSignedIn(auth);
  });

  test('refuses dependent flags when automatic transfer is off', () async {
    final result = await update(
      const UpdateCreditLineOptimizationParams(
        requestId: 'req-1',
        stepUpVerified: true,
        settings: CreditLineOptimization(
          product: LoanProductKind.classic,
          automaticCollateralTransfer: false,
          fixedTermSavingsUnlock: true,
          lowInterestBorrowing: false,
        ),
      ),
    );

    expect(
      result,
      Either<Failure, LoanSettlement>.left(
        const ValidationFailure('requires_automatic_collateral_transfer'),
      ),
    );
  });

  test('submits a legal combination as inFlight', () async {
    const legal = CreditLineOptimization(
      product: LoanProductKind.classic,
      automaticCollateralTransfer: true,
      fixedTermSavingsUnlock: true,
      lowInterestBorrowing: false,
    );
    when(
      () => settings.updateSettings(requestId: 'req-1', settings: legal),
    ).thenAnswer(
      (_) async => Either.right(
        const LoanSettlement(
          requestId: 'req-1',
          status: SettlementStatus.inFlight,
        ),
      ),
    );

    final result = await update(
      const UpdateCreditLineOptimizationParams(
        requestId: 'req-1',
        stepUpVerified: true,
        settings: legal,
      ),
    );

    expect(result.getRight().toNullable()?.status, SettlementStatus.inFlight);
  });
}
