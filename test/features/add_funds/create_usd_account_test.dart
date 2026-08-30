import 'package:fintech_app_test/core/auth/access_guards.dart';
import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/settlement/settlement_status.dart';
import 'package:fintech_app_test/features/add_funds/domain/entities/bank_transfer.dart';
import 'package:fintech_app_test/features/add_funds/domain/repositories/bank_transfer_repository.dart';
import 'package:fintech_app_test/features/add_funds/domain/usecases/bank/bank_submit_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_auth.dart';

class MockBankTransferRepository extends Mock
    implements BankTransferRepository {}

void main() {
  late MockAuthPort auth;
  late MockBankTransferRepository bank;
  late CreatePersonalUsdAccount createAccount;

  setUpAll(registerAuthFallbacks);

  setUp(() {
    auth = MockAuthPort();
    bank = MockBankTransferRepository();
    createAccount = CreatePersonalUsdAccount(AccessGuards(auth), bank);
    stubSignedIn(auth);
  });

  test('refuses when terms are not accepted', () async {
    final result = await createAccount(
      const CreatePersonalUsdAccountParams(
        requestId: 'req-1',
        termsAccepted: false,
        stepUpVerified: true,
      ),
    );

    expect(
      result,
      Either<Failure, FundingSettlement>.left(
        const ValidationFailure('terms_not_accepted'),
      ),
    );
  });

  test('creates account as inFlight when gates pass', () async {
    when(() => bank.createPersonalUsdAccount(requestId: 'req-1')).thenAnswer(
      (_) async => Either.right(
        const FundingSettlement(
          requestId: 'req-1',
          status: SettlementStatus.inFlight,
        ),
      ),
    );

    final result = await createAccount(
      const CreatePersonalUsdAccountParams(
        requestId: 'req-1',
        termsAccepted: true,
        stepUpVerified: true,
      ),
    );

    expect(
      result.getRight().toNullable()?.status,
      SettlementStatus.inFlight,
    );
  });
}
