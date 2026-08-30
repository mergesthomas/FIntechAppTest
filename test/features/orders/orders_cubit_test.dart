import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/core/ledger/paper_order.dart';
import 'package:fintech_app_test/features/orders/data/datasources/orders_local_datasource.dart';
import 'package:fintech_app_test/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:fintech_app_test/features/orders/domain/usecases/orders_usecases.dart';
import 'package:fintech_app_test/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late OrdersCubit cubit;

  setUp(() {
    auth = MockAuthRepository();
    cubit = OrdersCubit(
      GetOrderHistory(
        RequireSession(auth),
        OrdersRepositoryImpl(
          OrdersLocalDataSource(store: PaperOrderStore()),
        ),
      ),
    );
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  tearDown(() => cubit.close());

  test('load emits trigger orders', () async {
    await cubit.load();
    expect(cubit.state, isA<OrdersSuccess>());
  });

  test('load emits failure without session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    await cubit.load();
    expect(cubit.state, isA<OrdersFailure>());
  });
}
