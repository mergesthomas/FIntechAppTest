import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/news_item.dart';

abstract class NewsRepository {
  Future<Either<Failure, List<NewsItem>>> getFeed();
}
