import 'package:equatable/equatable.dart';

enum AddFundsMethodKind { bankTransfer, addCrypto, buyCrypto }

final class AddFundsMethod extends Equatable {
  const AddFundsMethod({
    required this.kind,
    required this.isAvailable,
  });

  final AddFundsMethodKind kind;
  final bool isAvailable;

  @override
  List<Object?> get props => [kind, isAvailable];
}
