import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../../core/auth/access_guards.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/usecase/use_case.dart';
import '../../entities/collateral.dart';
import '../../entities/loan_product.dart';
import '../../repositories/collateral_repository.dart';

final class GetCollateralAssetsParams extends Equatable {
  const GetCollateralAssetsParams({required this.creditLine});

  final LoanProductKind creditLine;

  @override
  List<Object?> get props => [creditLine];
}

final class GetCollateralAssets
    implements UseCase<List<CollateralAsset>, GetCollateralAssetsParams> {
  GetCollateralAssets(this._guards, this._collateral);

  final AccessGuards _guards;
  final CollateralRepository _collateral;

  @override
  Future<Either<Failure, List<CollateralAsset>>> call(
    GetCollateralAssetsParams params,
  ) async {
    final session = await _guards.requireSession();
    if (session.isLeft()) {
      return session.hideRight();
    }
    return _collateral.getAssets(params.creditLine);
  }
}

final class GetCollateralFilter
    implements UseCase<List<LoanProductKind>, NoParams> {
  GetCollateralFilter(this._guards, this._collateral);

  final AccessGuards _guards;
  final CollateralRepository _collateral;

  @override
  Future<Either<Failure, List<LoanProductKind>>> call(NoParams params) async {
    final session = await _guards.requireSession();
    if (session.isLeft()) {
      return session.hideRight();
    }
    return _collateral.getFilterOptions();
  }
}

final class GetAssetLtvSchedule
    implements UseCase<List<AssetLtvEntry>, GetCollateralAssetsParams> {
  GetAssetLtvSchedule(this._guards, this._collateral);

  final AccessGuards _guards;
  final CollateralRepository _collateral;

  @override
  Future<Either<Failure, List<AssetLtvEntry>>> call(
    GetCollateralAssetsParams params,
  ) async {
    final session = await _guards.requireSession();
    if (session.isLeft()) {
      return session.hideRight();
    }
    return _collateral.getLtvSchedule(params.creditLine);
  }
}
