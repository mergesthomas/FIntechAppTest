import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../../domain/entities/product_tile.dart';
import '../../domain/usecases/get_product_catalog.dart';

sealed class ProductsState extends Equatable {
  const ProductsState();

  @override
  List<Object?> get props => [];
}

final class ProductsLoading extends ProductsState {
  const ProductsLoading();
}

final class ProductsEmpty extends ProductsState {
  const ProductsEmpty();
}

final class ProductsFailure extends ProductsState {
  const ProductsFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class ProductsSuccess extends ProductsState {
  const ProductsSuccess(this.tiles);

  final List<ProductTile> tiles;

  @override
  List<Object?> get props => [tiles];
}

class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit(this._getCatalog) : super(const ProductsLoading());

  final GetProductCatalog _getCatalog;

  Future<void> load() async {
    emit(const ProductsLoading());
    final result = await _getCatalog(const NoParams());
    result.fold(
      (failure) => emit(ProductsFailure(failure)),
      (tiles) => emit(
        tiles.isEmpty ? const ProductsEmpty() : ProductsSuccess(tiles),
      ),
    );
  }
}
