import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/inbox_item.dart';

abstract class InboxRepository {
  Future<Either<Failure, List<InboxItem>>> getItems();
}
