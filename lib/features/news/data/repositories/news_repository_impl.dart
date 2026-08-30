import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/news_item.dart';
import '../../domain/repositories/news_repository.dart';
import '../datasources/news_local_datasource.dart';

final class NewsRepositoryImpl implements NewsRepository {
  NewsRepositoryImpl(this._local);

  final NewsLocalDataSource _local;

  @override
  Future<Either<Failure, List<NewsItem>>> getFeed() async {
    return Either.right(_local.feed());
  }
}
