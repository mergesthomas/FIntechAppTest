import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../../domain/entities/inbox_item.dart';
import '../../domain/usecases/get_inbox_items.dart';

sealed class InboxState extends Equatable {
  const InboxState();

  @override
  List<Object?> get props => [];
}

final class InboxLoading extends InboxState {
  const InboxLoading();
}

final class InboxEmpty extends InboxState {
  const InboxEmpty();
}

final class InboxFailure extends InboxState {
  const InboxFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class InboxSuccess extends InboxState {
  const InboxSuccess(this.items);

  final List<InboxItem> items;

  @override
  List<Object?> get props => [items];
}

class InboxCubit extends Cubit<InboxState> {
  InboxCubit(this._getItems) : super(const InboxLoading());

  final GetInboxItems _getItems;

  Future<void> load() async {
    emit(const InboxLoading());
    final result = await _getItems(const NoParams());
    result.fold(
      (failure) => emit(InboxFailure(failure)),
      (items) =>
          emit(items.isEmpty ? const InboxEmpty() : InboxSuccess(items)),
    );
  }
}
