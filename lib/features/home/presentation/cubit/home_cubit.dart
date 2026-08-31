import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../../domain/entities/dashboard.dart';
import '../../domain/usecases/home_usecases.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

final class HomeLoading extends HomeState {
  const HomeLoading();
}

final class HomeEmpty extends HomeState {
  const HomeEmpty();
}

final class HomeSuccess extends HomeState {
  const HomeSuccess({
    required this.overview,
    required this.watchlist,
    required this.alerts,
    required this.promos,
    required this.news,
  });

  final DashboardOverview overview;
  final List<WatchlistItem> watchlist;
  final List<DashboardAlert> alerts;
  final List<DashboardPromo> promos;
  final List<NewsPreview> news;

  @override
  List<Object?> get props => [overview, watchlist, alerts, promos, news];
}

final class HomeFailure extends HomeState {
  const HomeFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required GetDashboardOverview getOverview,
    required GetWatchlist getWatchlist,
    required GetDashboardAlerts getAlerts,
    required DismissDashboardAlert dismissAlert,
    required GetDashboardPromos getPromos,
    required GetNewsPreview getNews,
  })  : _getOverview = getOverview,
        _getWatchlist = getWatchlist,
        _getAlerts = getAlerts,
        _dismissAlert = dismissAlert,
        _getPromos = getPromos,
        _getNews = getNews,
        super(const HomeLoading());

  final GetDashboardOverview _getOverview;
  final GetWatchlist _getWatchlist;
  final GetDashboardAlerts _getAlerts;
  final DismissDashboardAlert _dismissAlert;
  final GetDashboardPromos _getPromos;
  final GetNewsPreview _getNews;

  DashboardPeriod _period = DashboardPeriod.oneWeek;

  Future<void> load({DashboardPeriod? period}) async {
    if (period != null) {
      _period = period;
    }
    emit(const HomeLoading());
    final overview = await _getOverview(_period);
    await overview.fold((failure) async => emit(HomeFailure(failure)), (o) async {
      final watchlist = await _getWatchlist(const NoParams());
      final alerts = await _getAlerts(const NoParams());
      final promos = await _getPromos(const NoParams());
      final news = await _getNews(const NoParams());
      if ([watchlist, alerts, promos, news].any((e) => e.isLeft())) {
        emit(const HomeFailure(ServerFailure('dashboard_partial_failure')));
        return;
      }
      emit(
        HomeSuccess(
          overview: o,
          watchlist: watchlist.getRight().toNullable()!,
          alerts: alerts.getRight().toNullable()!,
          promos: promos.getRight().toNullable()!,
          news: news.getRight().toNullable()!,
        ),
      );
    });
  }

  Future<void> selectPeriod(DashboardPeriod period) => load(period: period);

  Future<void> dismiss(String id) async {
    final result = await _dismissAlert(id);
    result.fold((_) {}, (_) => load());
  }
}
