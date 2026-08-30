import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/pending_auth.dart';
import '../../features/auth/presentation/cubit/session_cubit.dart';
import '../../features/auth/presentation/pages/biometric_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/phone_auth_page.dart';
import '../../features/auth/presentation/pages/pin_page.dart';
import '../../features/auth/presentation/pages/signed_in_page.dart';
import '../../features/auth/presentation/pages/sms_page.dart';
import 'app_route.dart';

class SessionRouterRefresh extends ChangeNotifier {
  SessionRouterRefresh(this._cubit) {
    _cubit.stream.listen((_) => notifyListeners());
  }

  final SessionCubit _cubit;
}

GoRouter createRouter(SessionCubit sessionCubit) {
  return GoRouter(
    initialLocation: AppRoute.onboarding.path,
    refreshListenable: SessionRouterRefresh(sessionCubit),
    redirect: (context, state) {
      final session = sessionCubit.state;
      final loggingIn = state.uri.path != AppRoute.home.path;
      if (session is SessionLoading) {
        return null;
      }
      if (session is SessionSuccess && loggingIn) {
        return AppRoute.home.path;
      }
      if (session is SessionEmpty && state.uri.path == AppRoute.home.path) {
        return AppRoute.onboarding.path;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoute.onboarding.path,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoute.login.path,
        builder: (context, state) => const PhoneAuthPage(
          intent: AuthIntent.login,
        ),
      ),
      GoRoute(
        path: AppRoute.signUp.path,
        builder: (context, state) => const PhoneAuthPage(
          intent: AuthIntent.signUp,
        ),
      ),
      GoRoute(
        path: AppRoute.verifySms.path,
        builder: (context, state) => const SmsPage(),
      ),
      GoRoute(
        path: AppRoute.createPin.path,
        builder: (context, state) => const PinPage(confirm: false),
      ),
      GoRoute(
        path: AppRoute.confirmPin.path,
        builder: (context, state) => const PinPage(confirm: true),
      ),
      GoRoute(
        path: AppRoute.enableBiometric.path,
        builder: (context, state) => const BiometricPage(),
      ),
      GoRoute(
        path: AppRoute.home.path,
        builder: (context, state) => const SignedInPage(),
      ),
    ],
  );
}
