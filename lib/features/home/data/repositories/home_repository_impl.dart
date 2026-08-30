import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/dashboard.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_datasource.dart';

final class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._local);

  final HomeLocalDataSource _local;

  @override
  Future<Either<Failure, DashboardOverview>> getOverview({
    required String initials,
  }) async {
    return Either.right(_local.overview(initials: initials));
  }

  @override
  Future<Either<Failure, CreditHubTeaser>> getCreditHub() async {
    return Either.right(_local.creditHub());
  }

  @override
  Future<Either<Failure, SavingsHubTeaser>> getSavingsHub() async {
    return Either.right(_local.savingsHub());
  }

  @override
  Future<Either<Failure, List<WatchlistItem>>> getWatchlist() async {
    return Either.right(_local.watchlist());
  }

  @override
  Future<Either<Failure, List<DashboardAlert>>> getAlerts() async {
    return Either.right(await _local.alerts());
  }

  @override
  Future<Either<Failure, Unit>> dismissAlert(String id) async {
    await _local.dismissAlert(id);
    return Either.right(unit);
  }

  @override
  Future<Either<Failure, List<DashboardPromo>>> getPromos() async {
    return Either.right(_local.promos());
  }

  @override
  Future<Either<Failure, List<NewsPreview>>> getNewsPreview() async {
    return Either.right(_local.news());
  }
}
