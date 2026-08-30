import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../clock/app_clock.dart';
import '../config/flavor_config.dart';
import '../secure/secure_store.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/onboarding_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/onboarding_usecases.dart';
import '../../features/auth/domain/usecases/pin_usecases.dart';
import '../../features/auth/domain/usecases/session_usecases.dart';
import '../../features/auth/domain/usecases/sms_usecases.dart';
import '../../features/auth/presentation/cubit/biometric_cubit.dart';
import '../../features/auth/presentation/cubit/onboarding_cubit.dart';
import '../../features/auth/presentation/cubit/phone_auth_cubit.dart';
import '../../features/auth/presentation/cubit/pin_cubit.dart';
import '../../features/auth/presentation/cubit/session_cubit.dart';
import '../../features/auth/presentation/cubit/sms_cubit.dart';

final flavorConfigProvider = Provider<FlavorConfig>((ref) => FlavorConfig.dev);

final appClockProvider = Provider<AppClock>((ref) => const SystemClock());

final secureStoreProvider = Provider<SecureStore>((ref) {
  throw UnimplementedError('Override secureStoreProvider in main');
});

final biometricPortProvider = Provider<BiometricPort>(
  (ref) => const AcceptingBiometricPort(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    local: AuthLocalDataSource(ref.watch(secureStoreProvider)),
    onboarding: const OnboardingLocalDataSource(),
    flavor: ref.watch(flavorConfigProvider),
    clock: ref.watch(appClockProvider),
    biometric: ref.watch(biometricPortProvider),
  );
});

final sessionCubitProvider = Provider<SessionCubit>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final cubit = SessionCubit(
    restoreSession: RestoreSession(repo),
    lockSession: LockSession(repo),
  )..restore();
  ref.onDispose(cubit.close);
  return cubit;
});

final onboardingCubitProvider = Provider<OnboardingCubit>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final cubit = OnboardingCubit(
    getSlides: GetOnboardingSlides(repo),
    getLocale: GetPreferredLocale(repo),
    setLocale: SetPreferredLocale(repo),
  )..load();
  ref.onDispose(cubit.close);
  return cubit;
});

final phoneAuthCubitProvider = Provider<PhoneAuthCubit>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final cubit = PhoneAuthCubit(
    startLogin: StartLogin(repo),
    startSignUp: StartSignUp(repo),
  );
  ref.onDispose(cubit.close);
  return cubit;
});

final smsCubitProvider = Provider<SmsCubit>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final cubit = SmsCubit(
    verifySmsCode: VerifySmsCode(repo),
    resendSms: ResendSms(repo),
  );
  ref.onDispose(cubit.close);
  return cubit;
});

final pinCubitProvider = Provider<PinCubit>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final cubit = PinCubit(
    createPin: CreatePin(repo),
    confirmPin: ConfirmPin(repo),
    resetPinDraft: ResetPinDraft(repo),
  );
  ref.onDispose(cubit.close);
  return cubit;
});

final biometricCubitProvider = Provider<BiometricCubit>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final cubit = BiometricCubit(
    enableBiometric: EnableBiometric(repo),
    skipBiometric: SkipBiometric(repo),
  );
  ref.onDispose(cubit.close);
  return cubit;
});
