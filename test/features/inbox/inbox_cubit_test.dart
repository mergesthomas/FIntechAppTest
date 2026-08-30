import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/inbox/data/datasources/inbox_local_datasource.dart';
import 'package:fintech_app_test/features/inbox/data/repositories/inbox_repository_impl.dart';
import 'package:fintech_app_test/features/inbox/domain/usecases/get_inbox_items.dart';
import 'package:fintech_app_test/features/inbox/presentation/cubit/inbox_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late InboxCubit cubit;

  setUp(() {
    auth = MockAuthRepository();
    cubit = InboxCubit(
      GetInboxItems(
        RequireSession(auth),
        InboxRepositoryImpl(const InboxLocalDataSource()),
      ),
    );
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  tearDown(() => cubit.close());

  test('load emits success', () async {
    await cubit.load();
    expect(cubit.state, isA<InboxSuccess>());
  });

  test('load emits failure without session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    await cubit.load();
    expect(cubit.state, isA<InboxFailure>());
  });
}
