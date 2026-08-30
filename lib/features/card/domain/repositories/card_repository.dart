import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/card.dart';

abstract class CardRepository {
  Future<Either<Failure, CardSnapshot>> getSnapshot();
  Future<Either<Failure, CardSnapshot>> unfreeze();
}
