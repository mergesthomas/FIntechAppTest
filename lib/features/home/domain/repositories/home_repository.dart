import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/dashboard.dart';

abstract class HomeRepository {
  Future<Either<Failure, DashboardOverview>> getOverview({
    required String initials,
  });

  Future<Either<Failure, CreditHubTeaser>> getCreditHub();

  Future<Either<Failure, SavingsHubTeaser>> getSavingsHub();

  Future<Either<Failure, List<WatchlistItem>>> getWatchlist();

  Future<Either<Failure, List<DashboardAlert>>> getAlerts();

  Future<Either<Failure, Unit>> dismissAlert(String id);

  Future<Either<Failure, List<DashboardPromo>>> getPromos();

  Future<Either<Failure, List<NewsPreview>>> getNewsPreview();
}
