import 'package:fpdart/fpdart.dart';

import '../../../../../core/auth/access_guards.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/usecase/use_case.dart';
import '../../entities/loan_product.dart';
import '../../repositories/loans_catalog_repository.dart';

final class GetAllLoansOverview
    implements UseCase<AllLoansOverview, NoParams> {
  GetAllLoansOverview(this._guards, this._catalog);

  final AccessGuards _guards;
  final LoansCatalogRepository _catalog;

  @override
  Future<Either<Failure, AllLoansOverview>> call(NoParams params) async {
    final session = await _guards.requireSession();
    if (session.isLeft()) {
      return session.hideRight();
    }
    return _catalog.getOverview();
  }
}

final class GetLoanProducts implements UseCase<List<LoanProduct>, NoParams> {
  GetLoanProducts(this._guards, this._catalog);

  final AccessGuards _guards;
  final LoansCatalogRepository _catalog;

  @override
  Future<Either<Failure, List<LoanProduct>>> call(NoParams params) async {
    final session = await _guards.requireSession();
    if (session.isLeft()) {
      return session.hideRight();
    }
    return _catalog.getProducts();
  }
}
