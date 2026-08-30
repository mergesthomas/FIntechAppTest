import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/pending_auth.dart';
import '../../features/auth/presentation/cubit/session_cubit.dart';
import '../../features/auth/presentation/pages/biometric_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/phone_auth_page.dart';
import '../../features/auth/presentation/pages/pin_page.dart';
import '../../features/auth/presentation/pages/sms_page.dart';
import '../../features/explore/presentation/pages/explore_page.dart';
import '../../features/card/presentation/pages/card_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/futures/presentation/pages/futures_page.dart';
import '../../features/swap/presentation/pages/swap_page.dart';
import '../../features/borrow/presentation/pages/borrow_page.dart';
import '../../features/earn/presentation/pages/earn_page.dart';
import '../../features/funding/presentation/pages/funding_page.dart';
import '../../features/home/presentation/pages/home_shell_page.dart';
import '../../features/inbox/presentation/pages/inbox_page.dart';
import '../../features/news/presentation/pages/news_page.dart';
import '../../features/products/presentation/pages/products_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/security_settings/presentation/pages/security_page.dart';
import '../../features/market/presentation/pages/market_page.dart';
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
      final path = state.uri.path;
      const authPaths = {
        '/onboarding',
        '/login',
        '/signup',
        '/verify-sms',
        '/create-pin',
        '/confirm-pin',
        '/enable-biometric',
      };
      if (session is SessionLoading) {
        return null;
      }
      if (session is SessionSuccess && authPaths.contains(path)) {
        return AppRoute.home.path;
      }
      if (session is SessionEmpty && !authPaths.contains(path)) {
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
        builder: (context, state) => const HomeShellPage(),
      ),
      GoRoute(
        path: AppRoute.profile.path,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoute.products.path,
        builder: (context, state) => const ProductsPage(),
      ),
      GoRoute(
        path: AppRoute.security.path,
        builder: (context, state) => const SecurityPage(),
      ),
      GoRoute(
        path: AppRoute.inbox.path,
        builder: (context, state) => const InboxPage(),
      ),
      GoRoute(
        path: AppRoute.news.path,
        builder: (context, state) => const NewsPage(),
      ),
      GoRoute(
        path: AppRoute.explore.path,
        builder: (context, state) => const ExplorePage(),
      ),
      GoRoute(
        path: AppRoute.funding.path,
        builder: (context, state) => const FundingPage(),
      ),
      GoRoute(
        path: AppRoute.borrow.path,
        builder: (context, state) => const BorrowPage(),
      ),
      GoRoute(
        path: AppRoute.earn.path,
        builder: (context, state) => const EarnPage(),
      ),
      GoRoute(
        path: AppRoute.card.path,
        builder: (context, state) => const CardPage(),
      ),
      GoRoute(
        path: AppRoute.swap.path,
        builder: (context, state) => const SwapPage(),
      ),
      GoRoute(
        path: AppRoute.orders.path,
        builder: (context, state) => const OrdersPage(),
      ),
      GoRoute(
        path: AppRoute.futures.path,
        builder: (context, state) => const FuturesPage(),
      ),
      GoRoute(
        path: '${AppRoute.market.path}/:code',
        builder: (context, state) => MarketPage(
          code: state.pathParameters['code'] ?? '',
        ),
      ),
    ],
  );
}
