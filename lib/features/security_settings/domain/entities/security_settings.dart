import 'package:equatable/equatable.dart';

enum AccountDocumentKind {
  accountConfirmation,
  cardConfirmation,
  accountBalance,
  loanStatement,
  savingsStatement,
}

final class SecuritySnapshot extends Equatable {
  const SecuritySnapshot({
    required this.biometricEnabled,
    required this.twoFactorEnabled,
    required this.antiPhishingEnabled,
    required this.whitelistingOn,
    required this.lastLogin,
  });

  final bool biometricEnabled;
  final bool twoFactorEnabled;
  final bool antiPhishingEnabled;
  final bool whitelistingOn;
  final String lastLogin;

  SecuritySnapshot copyWith({bool? biometricEnabled, bool? whitelistingOn}) {
    return SecuritySnapshot(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      twoFactorEnabled: twoFactorEnabled,
      antiPhishingEnabled: antiPhishingEnabled,
      whitelistingOn: whitelistingOn ?? this.whitelistingOn,
      lastLogin: lastLogin,
    );
  }

  @override
  List<Object?> get props => [
        biometricEnabled,
        twoFactorEnabled,
        antiPhishingEnabled,
        whitelistingOn,
        lastLogin,
      ];
}

final class AppPreferences extends Equatable {
  const AppPreferences({
    required this.displayCurrency,
    required this.language,
    required this.appearance,
  });

  final String displayCurrency;
  final String language;
  final String appearance;

  @override
  List<Object?> get props => [displayCurrency, language, appearance];
}
