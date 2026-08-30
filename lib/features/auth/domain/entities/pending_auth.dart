import 'package:equatable/equatable.dart';

enum AuthIntent { login, signUp }

final class PendingAuth extends Equatable {
  const PendingAuth({
    required this.phone,
    required this.intent,
    required this.smsSentAt,
  });

  final String phone;
  final AuthIntent intent;
  final DateTime smsSentAt;

  @override
  List<Object?> get props => [phone, intent, smsSentAt];
}
