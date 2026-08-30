import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/funding/data/datasources/funding_local_datasource.dart';
import 'package:fintech_app_test/features/funding/data/repositories/funding_repository_impl.dart';
import 'package:fintech_app_test/features/funding/domain/usecases/funding_usecases.dart';
import 'package:fintech_app_test/features/funding/presentation/cubit/funding_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

FundingCubit _cubit(AuthRepository auth, FundingRepositoryImpl repo) {
  final session = RequireSession(auth);
  final eligibility = GetEligibility(auth);
  return FundingCubit(
    getMethods: GetFundingMethods(session, repo),
    getFiatx: GetFiatxAssets(session, repo),
    getRails: GetBankRails(session, repo),
    getAccountStatus: GetFiatAccountStatus(session, repo),
    acceptTerms: AcceptFiatAccountTerms(session, repo),
    createUsd: CreatePersonalUsdAccount(session, eligibility, repo),
    getReceiveDetails: GetFiatReceiveDetails(session, repo),
    getFees: GetBankTransferFeeSchedule(session, repo),
    getReceivable: GetReceivableAssets(session, repo),
    getReceiveAddress: GetReceiveAddress(session, repo),
    getPurchasable: GetPurchasableAssets(session, repo),
    getBuyQuote: GetBuyQuote(session, eligibility, repo),
    getPaymentMethods: GetPaymentMethods(session, repo),
    submitBuy: SubmitBuyCrypto(session, eligibility, repo),
  );
}

void main() {
  late MockAuthRepository auth;
  late FundingCubit cubit;

  setUp(() {
    auth = MockAuthRepository();
    cubit = _cubit(auth, FundingRepositoryImpl(FundingLocalDataSource()));
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  tearDown(() => cubit.close());

  test('load emits hub methods', () async {
    await cubit.load();
    expect(cubit.state, isA<FundingReady>());
    expect((cubit.state as FundingReady).surface, FundingSurface.hub);
  });

  test('load emits failure without session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    await cubit.load();
    expect(cubit.state, isA<FundingFailure>());
  });
}
