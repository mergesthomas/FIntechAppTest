import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../../../core/usecase/use_case.dart';
import '../../domain/entities/security_settings.dart';
import '../../domain/usecases/security_usecases.dart';

sealed class SecurityState extends Equatable {
  const SecurityState();

  @override
  List<Object?> get props => [];
}

final class SecurityLoading extends SecurityState {
  const SecurityLoading();
}

final class SecurityEmpty extends SecurityState {
  const SecurityEmpty();
}

final class SecurityFailure extends SecurityState {
  const SecurityFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class SecuritySuccess extends SecurityState {
  const SecuritySuccess({
    required this.snapshot,
    required this.preferences,
    this.documentJob,
  });

  final SecuritySnapshot snapshot;
  final AppPreferences preferences;
  final SettlementStatus? documentJob;

  @override
  List<Object?> get props => [snapshot, preferences, documentJob];
}

class SecurityCubit extends Cubit<SecurityState> {
  SecurityCubit({
    required GetSecuritySettings getSettings,
    required GetAppPreferences getPreferences,
    required SetBiometricEnabled setBiometric,
    required SetAddressWhitelisting setWhitelisting,
    required Logout logout,
    required RequestAccountDocument requestDocument,
  })  : _getSettings = getSettings,
        _getPreferences = getPreferences,
        _setBiometric = setBiometric,
        _setWhitelisting = setWhitelisting,
        _logout = logout,
        _requestDocument = requestDocument,
        super(const SecurityLoading());

  final GetSecuritySettings _getSettings;
  final GetAppPreferences _getPreferences;
  final SetBiometricEnabled _setBiometric;
  final SetAddressWhitelisting _setWhitelisting;
  final Logout _logout;
  final RequestAccountDocument _requestDocument;

  Future<void> load() async {
    emit(const SecurityLoading());
    final settings = await _getSettings(const NoParams());
    await settings.fold((failure) async => emit(SecurityFailure(failure)), (
      snapshot,
    ) async {
      final prefs = await _getPreferences(const NoParams());
      prefs.fold(
        (failure) => emit(SecurityFailure(failure)),
        (preferences) => emit(
          SecuritySuccess(snapshot: snapshot, preferences: preferences),
        ),
      );
    });
  }

  Future<Failure?> toggleBiometric(bool enabled) async {
    final result = await _setBiometric(enabled);
    return result.fold((failure) => failure, (snapshot) {
      final current = state;
      if (current is SecuritySuccess) {
        emit(SecuritySuccess(snapshot: snapshot, preferences: current.preferences));
      }
      return null;
    });
  }

  Future<Failure?> toggleWhitelisting(bool enabled) async {
    final result = await _setWhitelisting(enabled);
    return result.fold((failure) => failure, (snapshot) {
      final current = state;
      if (current is SecuritySuccess) {
        emit(SecuritySuccess(snapshot: snapshot, preferences: current.preferences));
      }
      return null;
    });
  }

  Future<Failure?> requestDoc(AccountDocumentKind kind, String requestId) async {
    final result = await _requestDocument((kind: kind, requestId: requestId));
    return result.fold((failure) => failure, (status) {
      final current = state;
      if (current is SecuritySuccess) {
        emit(
          SecuritySuccess(
            snapshot: current.snapshot,
            preferences: current.preferences,
            documentJob: status,
          ),
        );
      }
      return null;
    });
  }

  Future<void> logout() => _logout(const NoParams());
}
