import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/borrow/data/datasources/borrow_local_datasource.dart';
import 'package:fintech_app_test/features/borrow/data/repositories/borrow_repository_impl.dart';
import 'package:fintech_app_test/features/borrow/domain/usecases/borrow_usecases.dart';
import 'package:fintech_app_test/features/borrow/presentation/cubit/borrow_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late BorrowCubit cubit;

  setUp(() {
    auth = MockAuthRepository();
    final repo = BorrowRepositoryImpl(BorrowLocalDataSource());
    final session = RequireSession(auth);
    final eligibility = GetEligibility(auth);
    cubit = BorrowCubit(
      getOverview: GetAllLoansOverview(session, repo),
      getProducts: GetLoanProducts(session, repo),
      getCollateral: GetCollateralAssets(session, repo),
      getOptimization: GetCreditLineOptimization(session, repo),
      updateOptimization: UpdateCreditLineOptimization(session, eligibility, repo),
      getQuote: GetBorrowQuote(session, eligibility, repo),
      submitBorrow: SubmitBorrow(session, eligibility, repo),
      submitRepay: SubmitRepay(session, eligibility, repo),
    );
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  tearDown(() => cubit.close());

  test('load emits loans even when available is zero', () async {
    await cubit.load();
    expect(cubit.state, isA<BorrowReady>());
    expect((cubit.state as BorrowReady).overview.available.isPositive, isFalse);
    expect((cubit.state as BorrowReady).products, isNotEmpty);
  });

  test('load emits failure without session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    await cubit.load();
    expect(cubit.state, isA<BorrowFailure>());
  });
}
