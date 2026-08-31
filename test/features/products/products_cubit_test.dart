import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/products/data/datasources/products_local_datasource.dart';
import 'package:fintech_app_test/features/products/data/repositories/product_catalog_repository_impl.dart';
import 'package:fintech_app_test/features/products/domain/usecases/get_product_catalog.dart';
import 'package:fintech_app_test/features/products/presentation/cubit/products_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late ProductsCubit cubit;

  setUp(() {
    auth = MockAuthRepository();
    cubit = ProductsCubit(
      GetProductCatalog(
        RequireSession(auth),
        GetEligibility(auth),
        ProductCatalogRepositoryImpl(const ProductsLocalDataSource()),
      ),
    );
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  tearDown(() => cubit.close());

  test('load emits success with money-moving tiles enabled', () async {
    await cubit.load();
    expect(cubit.state, isA<ProductsSuccess>());
    final tiles = (cubit.state as ProductsSuccess).tiles;
    expect(tiles.any((t) => t.id == 'swap' && t.enabled), isTrue);
    expect(tiles.any((t) => t.id == 'credit'), isFalse);
    expect(tiles.any((t) => t.id == 'savings'), isFalse);
  });

  test('load emits failure without session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    await cubit.load();
    expect(cubit.state, isA<ProductsFailure>());
  });
}
