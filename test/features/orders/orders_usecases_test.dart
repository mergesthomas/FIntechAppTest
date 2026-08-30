import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/settlement/settlement_status.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/core/ledger/paper_order.dart';
import 'package:fintech_app_test/features/orders/data/datasources/orders_local_datasource.dart';
import 'package:fintech_app_test/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:fintech_app_test/features/orders/domain/entities/order.dart';
import 'package:fintech_app_test/features/orders/domain/usecases/orders_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late OrdersRepositoryImpl repo;

  setUp(() {
    auth = MockAuthRepository();
    repo = OrdersRepositoryImpl(
      OrdersLocalDataSource(store: PaperOrderStore()),
    );
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  test('history requires session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    final result = await GetOrderHistory(RequireSession(auth), repo)(
      OrderTab.trigger,
    );
    expect(result.getLeft().toNullable(), isA<SessionFailure>());
  });

  test('cancel is inFlight and idempotent', () async {
    final cancel = CancelOrder(RequireSession(auth), repo);
    final first = await cancel((requestId: 'c1', orderId: 'ord-1'));
    final retry = await cancel((requestId: 'c1', orderId: 'ord-1'));
    expect(first.getRight().toNullable(), SettlementStatus.inFlight);
    expect(retry.getRight().toNullable(), SettlementStatus.inFlight);
  });
}
