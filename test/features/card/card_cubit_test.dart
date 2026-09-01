import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/card/data/datasources/card_local_datasource.dart';
import 'package:fintech_app_test/features/card/data/repositories/card_repository_impl.dart';
import 'package:fintech_app_test/features/card/domain/entities/card.dart';
import 'package:fintech_app_test/features/card/domain/usecases/card_usecases.dart';
import 'package:fintech_app_test/features/card/presentation/cubit/card_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late CardCubit cubit;

  setUp(() {
    auth = MockAuthRepository();
    final repo = CardRepositoryImpl(CardLocalDataSource());
    final session = RequireSession(auth);
    cubit = CardCubit(
      getStatus: GetCardStatus(session, repo),
      restore: RestoreCardBalance(session),
      unfreeze: UnfreezeCard(session, repo),
      freeze: FreezeCard(session, repo),
      revealPin: RevealCardPin(session, repo),
    );
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  tearDown(() => cubit.close());

  test('load emits frozen success', () async {
    await cubit.load();
    expect(cubit.state, isA<CardSuccess>());
    expect((cubit.state as CardSuccess).snapshot.status, CardStatus.frozen);
  });

  test('load emits failure without session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    await cubit.load();
    expect(cubit.state, isA<CardFailure>());
  });
}
