import 'package:fintech_app_test/core/auth/eligibility_status.dart';
import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/usecase/use_case.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/products/domain/entities/product_tile.dart';
import 'package:fintech_app_test/features/products/domain/repositories/product_catalog_repository.dart';
import 'package:fintech_app_test/features/products/domain/usecases/get_product_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockProductCatalogRepository extends Mock
    implements ProductCatalogRepository {}

void main() {
  late MockAuthRepository auth;
  late MockProductCatalogRepository catalog;
  late GetProductCatalog getCatalog;

  setUpAll(() {
    registerFallbackValue(EligibilityStatus.unknown);
  });

  setUp(() {
    auth = MockAuthRepository();
    catalog = MockProductCatalogRepository();
    getCatalog = GetProductCatalog(
      RequireSession(auth),
      GetEligibility(auth),
      catalog,
    );
  });

  test('refuses catalog without a session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );

    final result = await getCatalog(const NoParams());

    expect(result.getLeft().toNullable(), isA<SessionFailure>());
    verifyNever(
      () => catalog.getCatalog(eligibility: any(named: 'eligibility')),
    );
  });

  test('loads catalog when session exists', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
    when(
      () => catalog.getCatalog(eligibility: EligibilityStatus.approved),
    ).thenAnswer(
      (_) async => Either.right(const [
        ProductTile(
          id: 'explore',
          label: 'Explore',
          group: 'Information',
          enabled: true,
        ),
      ]),
    );

    final result = await getCatalog(const NoParams());

    expect(result.getRight().toNullable()?.first.id, 'explore');
  });
}
