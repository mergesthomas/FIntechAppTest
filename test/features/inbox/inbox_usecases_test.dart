import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/core/usecase/use_case.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/inbox/domain/entities/inbox_item.dart';
import 'package:fintech_app_test/features/inbox/domain/repositories/inbox_repository.dart';
import 'package:fintech_app_test/features/inbox/domain/usecases/get_inbox_items.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockInboxRepository extends Mock implements InboxRepository {}

void main() {
  late MockAuthRepository auth;
  late MockInboxRepository inbox;
  late GetInboxItems getItems;

  setUp(() {
    auth = MockAuthRepository();
    inbox = MockInboxRepository();
    getItems = GetInboxItems(RequireSession(auth), inbox);
  });

  test('refuses inbox without a session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    final result = await getItems(const NoParams());
    expect(result.getLeft().toNullable(), isA<SessionFailure>());
    verifyNever(() => inbox.getItems());
  });

  test('loads items when session exists', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
    when(() => inbox.getItems()).thenAnswer(
      (_) async => Either.right([
        InboxItem(
          id: '1',
          title: 'Interest Earned',
          amount: Money.parse('2.40', Currency.usd),
          dateLabel: 'Today',
        ),
      ]),
    );

    final result = await getItems(const NoParams());
    expect(result.getRight().toNullable()?.first.title, 'Interest Earned');
  });
}
