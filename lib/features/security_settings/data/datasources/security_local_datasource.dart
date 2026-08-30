import '../../../../core/settlement/settlement_status.dart';
import '../../domain/entities/security_settings.dart';

final class SecurityLocalDataSource {
  SecuritySnapshot _snapshot = const SecuritySnapshot(
    biometricEnabled: true,
    twoFactorEnabled: true,
    antiPhishingEnabled: true,
    whitelistingOn: false,
    lastLogin: 'Local emulator',
  );

  final Set<String> _closeRequestIds = {};
  final Set<String> _documentRequestIds = {};

  SecuritySnapshot settings() => _snapshot;

  SecuritySnapshot setBiometric(bool enabled) {
    _snapshot = _snapshot.copyWith(biometricEnabled: enabled);
    return _snapshot;
  }

  SecuritySnapshot setWhitelisting(bool enabled) {
    _snapshot = _snapshot.copyWith(whitelistingOn: enabled);
    return _snapshot;
  }

  AppPreferences preferences() {
    return const AppPreferences(
      displayCurrency: 'USD',
      language: 'English',
      appearance: 'System',
    );
  }

  SettlementStatus closeAccount(String requestId) {
    if (_closeRequestIds.contains(requestId)) {
      return SettlementStatus.inFlight;
    }
    _closeRequestIds.add(requestId);
    return SettlementStatus.inFlight;
  }

  SettlementStatus requestDocument(String requestId) {
    if (_documentRequestIds.contains(requestId)) {
      return SettlementStatus.inFlight;
    }
    _documentRequestIds.add(requestId);
    return SettlementStatus.inFlight;
  }
}
