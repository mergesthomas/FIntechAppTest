import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../../core/auth/access_guards.dart';
import '../../../../../core/auth/product_area.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/money/currency.dart';
import '../../../../../core/usecase/use_case.dart';
import '../../entities/bank_transfer.dart';
import '../../repositories/bank_transfer_repository.dart';

final class GetFiatxAssets implements UseCase<List<FiatxAsset>, NoParams> {
  GetFiatxAssets(this._guards, this._bank);

  final AccessGuards _guards;
  final BankTransferRepository _bank;

  @override
  Future<Either<Failure, List<FiatxAsset>>> call(NoParams params) async {
    final session = await _guards.requireSession();
    if (session.isLeft()) {
      return session.map((_) => const <FiatxAsset>[]);
    }
    return _bank.getFiatxAssets();
  }
}

final class GetBankRailsParams extends Equatable {
  const GetBankRailsParams({required this.asset});

  final Currency asset;

  @override
  List<Object?> get props => [asset];
}

final class GetBankRails implements UseCase<List<BankRail>, GetBankRailsParams> {
  GetBankRails(this._guards, this._bank);

  final AccessGuards _guards;
  final BankTransferRepository _bank;

  @override
  Future<Either<Failure, List<BankRail>>> call(GetBankRailsParams params) async {
    final gate = await _guards.requireApproved(ProductArea.funding);
    if (gate.isLeft()) {
      return gate.map((_) => const <BankRail>[]);
    }
    return _bank.getRails(params.asset);
  }
}

final class GetFiatAccountStatus
    implements UseCase<FiatAccountStatus, GetBankRailsParams> {
  GetFiatAccountStatus(this._guards, this._bank);

  final AccessGuards _guards;
  final BankTransferRepository _bank;

  @override
  Future<Either<Failure, FiatAccountStatus>> call(
    GetBankRailsParams params,
  ) async {
    final gate = await _guards.requireApproved(ProductArea.funding);
    if (gate.isLeft()) {
      return gate.map(
        (_) => const FiatAccountStatus(kind: FiatAccountStatusKind.none),
      );
    }
    return _bank.getAccountStatus(params.asset);
  }
}

final class GetFiatReceiveDetailsParams extends Equatable {
  const GetFiatReceiveDetailsParams({
    required this.asset,
    required this.rail,
  });

  final Currency asset;
  final BankRail rail;

  @override
  List<Object?> get props => [asset, rail];
}

final class GetFiatReceiveDetails
    implements UseCase<FiatReceiveDetails, GetFiatReceiveDetailsParams> {
  GetFiatReceiveDetails(this._guards, this._bank);

  final AccessGuards _guards;
  final BankTransferRepository _bank;

  @override
  Future<Either<Failure, FiatReceiveDetails>> call(
    GetFiatReceiveDetailsParams params,
  ) async {
    final gate = await _guards.requireApproved(ProductArea.funding);
    if (gate.isLeft()) {
      return gate.map(
        (_) => FiatReceiveDetails(
          asset: params.asset,
          rail: params.rail,
          fields: const {},
        ),
      );
    }
    return _bank.getReceiveDetails(asset: params.asset, rail: params.rail);
  }
}

final class GetBankTransferFeeSchedule
    implements UseCase<BankFeeSchedule, GetFiatReceiveDetailsParams> {
  GetBankTransferFeeSchedule(this._guards, this._bank);

  final AccessGuards _guards;
  final BankTransferRepository _bank;

  @override
  Future<Either<Failure, BankFeeSchedule>> call(
    GetFiatReceiveDetailsParams params,
  ) async {
    final gate = await _guards.requireApproved(ProductArea.funding);
    if (gate.isLeft()) {
      return gate.map(
        (_) => BankFeeSchedule(
          asset: params.asset,
          rail: params.rail,
          tiers: const [],
        ),
      );
    }
    return _bank.getFeeSchedule(asset: params.asset, rail: params.rail);
  }
}
