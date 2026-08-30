import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../../domain/entities/explore_asset.dart';
import '../../domain/usecases/get_explore_feed.dart';

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
  const ExploreSuccess(this.assets);

  final List<ExploreAsset> assets;

  @override
  List<Object?> get props => [assets];
}

class ExploreCubit extends Cubit<ExploreState> {
  ExploreCubit(this._getFeed) : super(const ExploreLoading());

  final GetExploreFeed _getFeed;

  Future<void> load() async {
    emit(const ExploreLoading());
    final result = await _getFeed(const NoParams());
    result.fold(
      (failure) => emit(ExploreFailure(failure)),
      (assets) => emit(
        assets.isEmpty ? const ExploreEmpty() : ExploreSuccess(assets),
      ),
    );
  }
}
