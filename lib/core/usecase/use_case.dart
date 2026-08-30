import 'package:fpdart/fpdart.dart';

import '../error/failure.dart';

abstract class UseCase<T, P> {
  Future<Either<Failure, T>> call(P params);
}

final class NoParams {
  const NoParams();
}
