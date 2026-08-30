import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/inbox_item.dart';
import '../../domain/repositories/inbox_repository.dart';
import '../datasources/inbox_local_datasource.dart';

final class InboxRepositoryImpl implements InboxRepository {
  InboxRepositoryImpl(this._local);

  final InboxLocalDataSource _local;

  @override
  Future<Either<Failure, List<InboxItem>>> getItems() async {
    return Either.right(_local.items());
  }
}
