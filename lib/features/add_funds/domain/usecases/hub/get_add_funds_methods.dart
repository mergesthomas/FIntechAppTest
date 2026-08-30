import 'package:fpdart/fpdart.dart';

import '../../../../../core/auth/access_guards.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/usecase/use_case.dart';
import '../../entities/add_funds_method.dart';
import '../../repositories/funding_catalog_repository.dart';

final class GetAddFundsMethods
    implements UseCase<List<AddFundsMethod>, NoParams> {
  GetAddFundsMethods(this._guards, this._catalog);

  final AccessGuards _guards;
  final FundingCatalogRepository _catalog;

  @override
  Future<Either<Failure, List<AddFundsMethod>>> call(NoParams params) async {
    final session = await _guards.requireSession();
    if (session.isLeft()) {
      return session.map((_) => const <AddFundsMethod>[]);
    }
    return _catalog.getMethods();
  }
}
