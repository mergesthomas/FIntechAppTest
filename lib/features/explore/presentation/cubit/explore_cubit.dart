import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../../domain/entities/explore_asset.dart';
import '../../domain/usecases/explore_usecases.dart';

sealed class ExploreState extends Equatable {
  const ExploreState();

  @override
  List<Object?> get props => [];
}

final class ExploreLoading extends ExploreState {
  const ExploreLoading();
}

final class ExploreEmpty extends ExploreState {
  const ExploreEmpty();
}

final class ExploreFailure extends ExploreState {
  const ExploreFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class ExploreSuccess extends ExploreState {
  const ExploreSuccess({
    required this.feed,
    required this.assets,
    required this.filter,
    this.query = '',
  });

  final ExploreFeed feed;
  final List<ExploreAsset> assets;
  final ExploreAssetFilter filter;
  final String query;

  ExploreSuccess copyWith({
    ExploreFeed? feed,
    List<ExploreAsset>? assets,
    ExploreAssetFilter? filter,
    String? query,
  }) {
    return ExploreSuccess(
      feed: feed ?? this.feed,
      assets: assets ?? this.assets,
      filter: filter ?? this.filter,
      query: query ?? this.query,
    );
  }

  @override
  List<Object?> get props => [feed, assets, filter, query];
}

class ExploreCubit extends Cubit<ExploreState> {
  ExploreCubit({
    required GetExploreFeed getFeed,
    required GetMarketAssets getAssets,
    required SearchExploreAssets searchAssets,
  })  : _getFeed = getFeed,
        _getAssets = getAssets,
        _searchAssets = searchAssets,
        super(const ExploreLoading());

  final GetExploreFeed _getFeed;
  final GetMarketAssets _getAssets;
  final SearchExploreAssets _searchAssets;

  ExploreSuccess? get _ready =>
      state is ExploreSuccess ? state as ExploreSuccess : null;

  Future<void> load() async {
    emit(const ExploreLoading());
    final result = await _getFeed(const NoParams());
    result.fold(
      (failure) => emit(ExploreFailure(failure)),
      (feed) => emit(
        feed.assets.isEmpty
            ? const ExploreEmpty()
            : ExploreSuccess(
                feed: feed,
                assets: feed.assets,
                filter: ExploreAssetFilter.all,
              ),
      ),
    );
  }

  Future<void> applyFilter(ExploreAssetFilter filter) async {
    final current = _ready;
    if (current == null) {
      return;
    }
    final result = await _getAssets(filter);
    result.fold(
      (failure) => emit(ExploreFailure(failure)),
      (assets) => emit(current.copyWith(filter: filter, assets: assets, query: '')),
    );
  }

  Future<void> search(String query) async {
    final current = _ready;
    if (current == null) {
      return;
    }
    if (query.trim().isEmpty) {
      await applyFilter(current.filter);
      return;
    }
    final result = await _searchAssets(query);
    result.fold(
      (failure) => emit(ExploreFailure(failure)),
      (assets) => emit(current.copyWith(query: query, assets: assets)),
    );
  }
}
