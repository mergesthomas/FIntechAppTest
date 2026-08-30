import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../../domain/entities/news_item.dart';
import '../../domain/usecases/get_news_feed.dart';

sealed class NewsState extends Equatable {
  const NewsState();

  @override
  List<Object?> get props => [];
}

final class NewsLoading extends NewsState {
  const NewsLoading();
}

final class NewsEmpty extends NewsState {
  const NewsEmpty();
}

final class NewsFailure extends NewsState {
  const NewsFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class NewsSuccess extends NewsState {
  const NewsSuccess(this.items);

  final List<NewsItem> items;

  @override
  List<Object?> get props => [items];
}

class NewsCubit extends Cubit<NewsState> {
  NewsCubit(this._getFeed) : super(const NewsLoading());

  final GetNewsFeed _getFeed;

  Future<void> load() async {
    emit(const NewsLoading());
    final result = await _getFeed(const NoParams());
    result.fold(
      (failure) => emit(NewsFailure(failure)),
      (items) => emit(items.isEmpty ? const NewsEmpty() : NewsSuccess(items)),
    );
  }
}
