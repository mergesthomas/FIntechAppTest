import 'package:equatable/equatable.dart';

final class NewsItem extends Equatable {
  const NewsItem({
    required this.id,
    required this.source,
    required this.headline,
    required this.age,
  });

  final String id;
  final String source;
  final String headline;
  final String age;

  @override
  List<Object?> get props => [id, source, headline, age];
}
