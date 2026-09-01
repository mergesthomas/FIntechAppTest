import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
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
    required this.holdings,
    required this.watchlist,
    required this.watchlistCandidates,
    required this.alerts,
    required this.promos,
    required this.news,
    this.watchlistQuery = '',
  });

  final DashboardOverview overview;
  final List<HoldingItem> holdings;
  final List<WatchlistItem> watchlist;
  final List<WatchlistItem> watchlistCandidates;
  final String watchlistQuery;
  final List<DashboardAlert> alerts;
  final List<DashboardPromo> promos;
  final List<NewsPreview> news;

  HomeSuccess copyWith({
    DashboardOverview? overview,
    List<HoldingItem>? holdings,
    List<WatchlistItem>? watchlist,
    List<WatchlistItem>? watchlistCandidates,
    String? watchlistQuery,
    List<DashboardAlert>? alerts,
    List<DashboardPromo>? promos,
    List<NewsPreview>? news,
  }) {
    return HomeSuccess(
      overview: overview ?? this.overview,
      holdings: holdings ?? this.holdings,
      watchlist: watchlist ?? this.watchlist,
      watchlistCandidates: watchlistCandidates ?? this.watchlistCandidates,
      watchlistQuery: watchlistQuery ?? this.watchlistQuery,
      alerts: alerts ?? this.alerts,
      promos: promos ?? this.promos,
      news: news ?? this.news,
    );
  }

  @override
  List<Object?> get props => [
    overview,
    holdings,
    watchlist,
    watchlistCandidates,
    watchlistQuery,
    alerts,
    promos,
    news,
  ];
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
    required GetHoldings getHoldings,
    required GetWatchlist getWatchlist,
    required GetWatchlistCandidates getWatchlistCandidates,
    required SearchWatchlistCandidates searchWatchlistCandidates,
    required AddWatchlistItem addWatchlistItem,
    required GetDashboardAlerts getAlerts,
    required DismissDashboardAlert dismissAlert,
    required GetDashboardPromos getPromos,
    required GetNewsPreview getNews,
  }) : _getOverview = getOverview,
       _getHoldings = getHoldings,
       _getWatchlist = getWatchlist,
       _getWatchlistCandidates = getWatchlistCandidates,
       _searchWatchlistCandidates = searchWatchlistCandidates,
       _addWatchlistItem = addWatchlistItem,
       _getAlerts = getAlerts,
       _dismissAlert = dismissAlert,
       _getPromos = getPromos,
       _getNews = getNews,
       super(const HomeLoading());

  final GetDashboardOverview _getOverview;
  final GetHoldings _getHoldings;
  final GetWatchlist _getWatchlist;
  final GetWatchlistCandidates _getWatchlistCandidates;
  final SearchWatchlistCandidates _searchWatchlistCandidates;
  final AddWatchlistItem _addWatchlistItem;
  final GetDashboardAlerts _getAlerts;
  final DismissDashboardAlert _dismissAlert;
  final GetDashboardPromos _getPromos;
  final GetNewsPreview _getNews;
  var _addingWatchlist = false;

  DashboardPeriod _period = DashboardPeriod.oneWeek;

  Future<void> load({DashboardPeriod? period}) async {
    if (period != null) {
      _period = period;
    }
    emit(const HomeLoading());
    final overview = await _getOverview(_period);
    await overview.fold((failure) async => emit(HomeFailure(failure)), (
      o,
    ) async {
      final holdings = await _getHoldings(_period);
      final watchlist = await _getWatchlist(const NoParams());
      final candidates = await _getWatchlistCandidates(const NoParams());
      final alerts = await _getAlerts(const NoParams());
      final promos = await _getPromos(const NoParams());
      final news = await _getNews(const NoParams());
      if ([holdings, watchlist, alerts, promos, news].any((e) => e.isLeft())) {
        emit(const HomeFailure(ServerFailure('dashboard_partial_failure')));
        return;
      }
      emit(
        HomeSuccess(
          overview: o,
          holdings: holdings.getRight().toNullable()!,
          watchlist: watchlist.getRight().toNullable()!,
          watchlistCandidates: candidates.getRight().toNullable() ?? const [],
          alerts: alerts.getRight().toNullable()!,
          promos: promos.getRight().toNullable()!,
          news: news.getRight().toNullable()!,
        ),
      );
    });
  }

  Future<void> selectPeriod(DashboardPeriod period) async {
    if (state is! HomeSuccess) {
      await load(period: period);
      return;
    }
    if (_period == period) {
      return;
    }
    _period = period;
    final overview = await _getOverview(_period);
    final holdings = await _getHoldings(_period);
    if (isClosed || _period != period) {
      return;
    }
    final current = state;
    if (current is! HomeSuccess) {
      return;
    }
    overview.fold((_) {}, (o) {
      holdings.fold(
        (_) {},
        (h) => emit(current.copyWith(overview: o, holdings: h)),
      );
    });
  }

  Future<void> searchWatchlistCandidates(String query) async {
    final current = state;
    if (current is! HomeSuccess) {
      return;
    }
    final result = await _searchWatchlistCandidates(query);
    if (isClosed) {
      return;
    }
    final latest = state;
    if (latest is! HomeSuccess) {
      return;
    }
    result.fold(
      (_) {},
      (items) => emit(
        latest.copyWith(watchlistCandidates: items, watchlistQuery: query),
      ),
    );
  }

  Future<Either<Failure, Unit>> addWatchlistItem(Currency currency) async {
    final current = state;
    if (current is! HomeSuccess || _addingWatchlist) {
      return Either<Failure, Unit>.left(
        const ServerFailure('watchlist_add_busy'),
      );
    }
    _addingWatchlist = true;
    try {
      final result = await _addWatchlistItem(currency);
      if (isClosed) {
        return Either<Failure, Unit>.left(
          const ServerFailure('watchlist_add_busy'),
        );
      }
      final latest = state;
      if (latest is! HomeSuccess) {
        return Either<Failure, Unit>.left(
          const ServerFailure('watchlist_add_busy'),
        );
      }
      return await result.fold(
        (failure) async => Either<Failure, Unit>.left(failure),
        (items) async {
          final candidates = await _searchWatchlistCandidates(
            latest.watchlistQuery,
          );
          if (isClosed) {
            return Either<Failure, Unit>.left(
              const ServerFailure('watchlist_add_busy'),
            );
          }
          final after = state;
          if (after is! HomeSuccess) {
            return Either<Failure, Unit>.left(
              const ServerFailure('watchlist_add_busy'),
            );
          }
          emit(
            after.copyWith(
              watchlist: items,
              watchlistCandidates:
                  candidates.getRight().toNullable() ?? const [],
            ),
          );
          return Either<Failure, Unit>.right(unit);
        },
      );
    } finally {
      _addingWatchlist = false;
    }
  }

  Future<Failure?> dismiss(String id) async {
    final result = await _dismissAlert(id);
    return result.fold((failure) => failure, (_) {
      load();
      return null;
    });
  }
}
