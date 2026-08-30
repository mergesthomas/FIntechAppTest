import 'package:equatable/equatable.dart';

final class Session extends Equatable {
  const Session({
    required this.token,
    required this.phone,
    required this.biometricEnabled,
  });

  final String token;
  final String phone;
  final bool biometricEnabled;

  @override
  List<Object?> get props => [token, phone, biometricEnabled];
}
