import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/clock/app_clock.dart';
import '../../../../core/config/flavor_config.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/onboarding_slide.dart';
import '../../domain/entities/pending_auth.dart';
import '../../domain/entities/pin_draft.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/onboarding_local_datasource.dart';

final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthLocalDataSource local,
    required OnboardingLocalDataSource onboarding,
    required FlavorConfig flavor,
    required AppClock clock,
    required BiometricPort biometric,
    Random? random,
  })  : _local = local,
        _onboarding = onboarding,
        _flavor = flavor,
        _clock = clock,
        _biometric = biometric,
        _random = random ?? Random.secure();

  final AuthLocalDataSource _local;
  final OnboardingLocalDataSource _onboarding;
  final FlavorConfig _flavor;
  final AppClock _clock;
  final BiometricPort _biometric;
  final Random _random;

  PendingAuth? _pending;
  bool _smsVerified = false;
  String? _pinDraftId;
  String? _pinDraftHash;
  String? _pinDraftSalt;
  bool _pinConfirmed = false;

  @override
  Future<Either<Failure, List<OnboardingSlide>>> getOnboardingSlides() async {
    return Either.right(_onboarding.slides());
  }

  @override
  Future<Either<Failure, String>> getPreferredLocale() async {
    return Either.right(await _local.readLocale() ?? 'en');
  }

  @override
  Future<Either<Failure, Unit>> setPreferredLocale(String locale) async {
    await _local.writeLocale(locale);
    return Either.right(unit);
  }

  @override
  Future<Either<Failure, PendingAuth>> startLogin(String phone) {
    return _start(phone, AuthIntent.login);
  }

  @override
  Future<Either<Failure, PendingAuth>> startSignUp(String phone) {
    return _start(phone, AuthIntent.signUp);
  }

  Future<Either<Failure, PendingAuth>> _start(
    String phone,
    AuthIntent intent,
  ) async {
    _pending = PendingAuth(
      phone: phone,
      intent: intent,
      smsSentAt: _clock.now(),
    );
    _smsVerified = false;
    _pinConfirmed = false;
    await resetPinDraft();
    return Either.right(_pending!);
  }

  @override
  Future<Either<Failure, PendingAuth>> resendSms() async {
    final pending = _pending;
    if (pending == null) {
      return Either.left(const AuthFailure('no_pending_auth'));
    }
    final elapsed = _clock.now().difference(pending.smsSentAt);
    if (elapsed < _flavor.smsResendCooldown) {
      return Either.left(const AuthFailure('sms_resend_cooldown'));
    }
    _pending = PendingAuth(
      phone: pending.phone,
      intent: pending.intent,
      smsSentAt: _clock.now(),
    );
    return Either.right(_pending!);
  }

  @override
  Future<Either<Failure, Unit>> verifySmsCode(String code) async {
    if (_pending == null) {
      return Either.left(const AuthFailure('no_pending_auth'));
    }
    if (code != _flavor.emulatorSmsCode) {
      return Either.left(const AuthFailure('invalid_sms_code'));
    }
    _smsVerified = true;
    return Either.right(unit);
  }

  @override
  Future<Either<Failure, PinDraft>> createPin(String pin) async {
    if (!_smsVerified) {
      return Either.left(const AuthFailure('sms_not_verified'));
    }
    final salt = _randomBytes();
    _pinDraftId = _randomBytes();
    _pinDraftSalt = salt;
    _pinDraftHash = _hashPin(pin, salt);
    _pinConfirmed = false;
    return Either.right(PinDraft(id: _pinDraftId!));
  }

  @override
  Future<Either<Failure, Unit>> confirmPin({
    required PinDraft draft,
    required String pin,
  }) async {
    if (_pinDraftId == null || draft.id != _pinDraftId) {
      return Either.left(const AuthFailure('pin_draft_missing'));
    }
    final candidate = _hashPin(pin, _pinDraftSalt!);
    if (candidate != _pinDraftHash) {
      return Either.left(const AuthFailure('pin_mismatch'));
    }
    await _local.writePin(hash: _pinDraftHash!, salt: _pinDraftSalt!);
    _pinConfirmed = true;
    return Either.right(unit);
  }

  @override
  Future<Either<Failure, Unit>> resetPinDraft() async {
    _pinDraftId = null;
    _pinDraftHash = null;
    _pinDraftSalt = null;
    _pinConfirmed = false;
    return Either.right(unit);
  }

  @override
  Future<Either<Failure, Session>> enableBiometric() async {
    final gate = _readyForSession();
    if (gate != null) {
      return Either.left(gate);
    }
    final ok = await _biometric.authenticate();
    if (!ok) {
      return Either.left(const AuthFailure('biometric_failed'));
    }
    return _openSession(biometricEnabled: true);
  }

  @override
  Future<Either<Failure, Session>> skipBiometric() async {
    final gate = _readyForSession();
    if (gate != null) {
      return Either.left(gate);
    }
    return _openSession(biometricEnabled: false);
  }

  @override
  Future<Either<Failure, Session>> restoreSession() async {
    final token = await _local.readSessionToken();
    final phone = await _local.readSessionPhone();
    if (token == null || phone == null) {
      return Either.left(const SessionFailure());
    }
    return Either.right(
      Session(
        token: token,
        phone: phone,
        biometricEnabled: await _local.readBiometricEnabled(),
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> lockSession() async {
    await _local.clearSession();
    _pending = null;
    _smsVerified = false;
    await resetPinDraft();
    return Either.right(unit);
  }

  Failure? _readyForSession() {
    if (_pending == null || !_smsVerified) {
      return const AuthFailure('sms_not_verified');
    }
    if (!_pinConfirmed) {
      return const AuthFailure('pin_not_confirmed');
    }
    return null;
  }

  Future<Either<Failure, Session>> _openSession({
    required bool biometricEnabled,
  }) async {
    final token = _randomBytes();
    final phone = _pending!.phone;
    await _local.writeSession(
      token: token,
      phone: phone,
      biometricEnabled: biometricEnabled,
    );
    return Either.right(
      Session(token: token, phone: phone, biometricEnabled: biometricEnabled),
    );
  }

  String _hashPin(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  String _randomBytes() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}

abstract class BiometricPort {
  Future<bool> authenticate();
}

final class AcceptingBiometricPort implements BiometricPort {
  const AcceptingBiometricPort();

  @override
  Future<bool> authenticate() async => true;
}
