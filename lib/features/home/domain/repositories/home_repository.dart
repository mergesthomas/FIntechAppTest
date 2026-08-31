import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../entities/dashboard.dart';

abstract class HomeRepository {
  Future<Either<Failure, DashboardOverview>> getOverview({
    required String initials,
    DashboardPeriod period = DashboardPeriod.oneWeek,
  });

  Future<Either<Failure, List<WatchlistItem>>> getWatchlist();

  Future<Either<Failure, List<HoldingItem>>> getHoldings();

  Future<Either<Failure, List<WatchlistItem>>> getWatchlistCandidates();

  Future<Either<Failure, List<WatchlistItem>>> searchWatchlistCandidates(
    String query,
  );

  Future<Either<Failure, List<WatchlistItem>>> addWatchlistItem(
    Currency currency,
  );

  Future<Either<Failure, List<DashboardAlert>>> getAlerts();

  Future<Either<Failure, Unit>> dismissAlert(String id);

  Future<Either<Failure, List<DashboardPromo>>> getPromos();

  Future<Either<Failure, List<NewsPreview>>> getNewsPreview();
}
