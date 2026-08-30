import 'package:fintech_app_test/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:fintech_app_test/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fixture profile includes platinum loyalty and version', () async {
    final repo = ProfileRepositoryImpl(const ProfileLocalDataSource());

    final overview = await repo.getOverview();
    final version = await repo.getAppVersion();

    expect(overview.getRight().toNullable()?.loyaltyTier, 'Platinum');
    expect(version.getRight().toNullable(), '7.9.1');
  });
}
