import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/card.dart';
import '../../domain/repositories/card_repository.dart';
import '../datasources/card_local_datasource.dart';

final class CardRepositoryImpl implements CardRepository {
  CardRepositoryImpl(this._local);

  final CardLocalDataSource _local;

  @override
  Future<Either<Failure, CardSnapshot>> getSnapshot() async {
    return Either.right(_local.snapshot);
  }

  @override
  Future<Either<Failure, CardSnapshot>> unfreeze() async {
    return Either.right(_local.unfreeze());
  }

  @override
  Future<Either<Failure, CardSnapshot>> freeze() async {
    return Either.right(_local.freeze());
  }

  @override
  Future<Either<Failure, String>> revealPin() async {
    return Either.right(CardLocalDataSource.fixturePin);
  }
}
