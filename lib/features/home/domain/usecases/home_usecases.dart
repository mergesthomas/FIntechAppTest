import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../auth/domain/entities/session.dart';
import '../../../auth/domain/usecases/session_usecases.dart';
import '../entities/dashboard.dart';
import '../repositories/home_repository.dart';

String _initialsFor(Session session) {
  final digits = session.phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length >= 2) {
    return digits.substring(digits.length - 2);
  }
  return 'NA';
}

final class GetDashboardOverview
    implements UseCase<DashboardOverview, DashboardPeriod> {
  GetDashboardOverview(this._requireSession, this._home);

  final RequireSession _requireSession;
  final HomeRepository _home;

  @override
  Future<Either<Failure, DashboardOverview>> call(
    DashboardPeriod period,
  ) async {
    final session = await _requireSession(const NoParams());
    return session.fold(
      Either.left,
      (value) => _home.getOverview(
        initials: _initialsFor(value),
        period: period,
      ),
    );
  }
}

final class GetCreditHubTeaser implements UseCase<CreditHubTeaser, NoParams> {
  GetCreditHubTeaser(this._requireSession, this._home);

  final RequireSession _requireSession;
  final HomeRepository _home;

  @override
  Future<Either<Failure, CreditHubTeaser>> call(NoParams params) async {
    final session = await _requireSession(params);
    return session.fold(Either.left, (_) => _home.getCreditHub());
  }
}

final class GetSavingsHubTeaser implements UseCase<SavingsHubTeaser, NoParams> {
  GetSavingsHubTeaser(this._requireSession, this._home);

  final RequireSession _requireSession;
  final HomeRepository _home;

  @override
  Future<Either<Failure, SavingsHubTeaser>> call(NoParams params) async {
    final session = await _requireSession(params);
    return session.fold(Either.left, (_) => _home.getSavingsHub());
  }
}

final class GetWatchlist implements UseCase<List<WatchlistItem>, NoParams> {
  GetWatchlist(this._requireSession, this._home);

  final RequireSession _requireSession;
  final HomeRepository _home;

  @override
  Future<Either<Failure, List<WatchlistItem>>> call(NoParams params) async {
    final session = await _requireSession(params);
    return session.fold(Either.left, (_) => _home.getWatchlist());
  }
}

final class GetDashboardAlerts
    implements UseCase<List<DashboardAlert>, NoParams> {
  GetDashboardAlerts(this._requireSession, this._home);

  final RequireSession _requireSession;
  final HomeRepository _home;

  @override
  Future<Either<Failure, List<DashboardAlert>>> call(NoParams params) async {
    final session = await _requireSession(params);
    return session.fold(Either.left, (_) => _home.getAlerts());
  }
}

final class DismissDashboardAlert implements UseCase<Unit, String> {
  DismissDashboardAlert(this._requireSession, this._home);

  final RequireSession _requireSession;
  final HomeRepository _home;

  @override
  Future<Either<Failure, Unit>> call(String id) async {
    if (id.isEmpty) {
      return Either.left(const ValidationFailure('alert_id_required'));
    }
    final session = await _requireSession(const NoParams());
    return session.fold(Either.left, (_) => _home.dismissAlert(id));
  }
}

final class GetDashboardPromos
    implements UseCase<List<DashboardPromo>, NoParams> {
  GetDashboardPromos(this._requireSession, this._home);

  final RequireSession _requireSession;
  final HomeRepository _home;

  @override
  Future<Either<Failure, List<DashboardPromo>>> call(NoParams params) async {
    final session = await _requireSession(params);
    return session.fold(Either.left, (_) => _home.getPromos());
  }
}

final class GetNewsPreview implements UseCase<List<NewsPreview>, NoParams> {
  GetNewsPreview(this._requireSession, this._home);

  final RequireSession _requireSession;
  final HomeRepository _home;

  @override
  Future<Either<Failure, List<NewsPreview>>> call(NoParams params) async {
    final session = await _requireSession(params);
    return session.fold(Either.left, (_) => _home.getNewsPreview());
  }
}
