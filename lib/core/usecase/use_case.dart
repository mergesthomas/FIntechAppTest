import 'package:fpdart/fpdart.dart';

import '../error/failure.dart';

abstract class UseCase<T, P> {
  Future<Either<Failure, T>> call(P params);
}

final class NoParams {
  const NoParams();
}

extension FailureGateX on Either<Failure, Unit> {
  Either<Failure, T> hideRight<T>() {
    return fold(
      (failure) => Either<Failure, T>.left(failure),
      (_) => throw StateError('Expected a left Failure'),
    );
  }
}
