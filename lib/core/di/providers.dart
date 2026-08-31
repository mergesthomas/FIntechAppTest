import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../clock/app_clock.dart';
import '../config/flavor_config.dart';
import '../ledger/paper_fill_watcher.dart';
import '../ledger/paper_ledger.dart';
import '../ledger/paper_order.dart';
import '../ledger/paper_settler.dart';
import '../market/in_memory_market_feed.dart';
import '../market/market_feed.dart';
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
import '../../features/home/data/datasources/home_local_datasource.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/home_usecases.dart';
import '../../features/explore/data/datasources/explore_local_datasource.dart';
import '../../features/explore/data/repositories/explore_repository_impl.dart';
import '../../features/explore/domain/repositories/explore_repository.dart';
import '../../features/explore/domain/usecases/explore_usecases.dart';
import '../../features/explore/presentation/cubit/explore_cubit.dart';
import '../../features/funding/data/datasources/funding_local_datasource.dart';
import '../../features/funding/data/repositories/funding_repository_impl.dart';
import '../../features/funding/domain/repositories/funding_repository.dart';
import '../../features/funding/domain/usecases/funding_usecases.dart';
import '../../features/card/data/datasources/card_local_datasource.dart';
import '../../features/card/data/repositories/card_repository_impl.dart';
import '../../features/card/domain/repositories/card_repository.dart';
import '../../features/card/domain/usecases/card_usecases.dart';
import '../../features/card/presentation/cubit/card_cubit.dart';
import '../../features/swap/data/datasources/swap_local_datasource.dart';
import '../../features/swap/data/repositories/swap_repository_impl.dart';
import '../../features/swap/domain/repositories/swap_repository.dart';
import '../../features/swap/domain/usecases/swap_usecases.dart';
import '../../features/orders/data/datasources/orders_local_datasource.dart';
import '../../features/orders/data/repositories/orders_repository_impl.dart';
import '../../features/orders/domain/repositories/orders_repository.dart';
import '../../features/orders/domain/usecases/orders_usecases.dart';
import '../../features/orders/presentation/cubit/orders_cubit.dart';
import '../../features/market/data/datasources/market_local_datasource.dart';
import '../../features/market/data/repositories/market_repository_impl.dart';
import '../../features/market/domain/repositories/market_repository.dart';
import '../../features/market/domain/usecases/market_usecases.dart';
import '../../features/market/presentation/cubit/market_cubit.dart';
import '../../features/swap/presentation/cubit/swap_cubit.dart';
import '../../features/funding/presentation/cubit/funding_cubit.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/inbox/data/datasources/inbox_local_datasource.dart';
import '../../features/inbox/data/repositories/inbox_repository_impl.dart';
import '../../features/inbox/domain/repositories/inbox_repository.dart';
import '../../features/inbox/domain/usecases/get_inbox_items.dart';
import '../../features/inbox/presentation/cubit/inbox_cubit.dart';
import '../../features/news/data/datasources/news_local_datasource.dart';
import '../../features/news/data/repositories/news_repository_impl.dart';
import '../../features/news/domain/repositories/news_repository.dart';
import '../../features/news/domain/usecases/get_news_feed.dart';
import '../../features/news/presentation/cubit/news_cubit.dart';
import '../../features/products/data/datasources/products_local_datasource.dart';
import '../../features/products/data/repositories/product_catalog_repository_impl.dart';
import '../../features/products/domain/repositories/product_catalog_repository.dart';
import '../../features/products/domain/usecases/get_product_catalog.dart';
import '../../features/products/presentation/cubit/products_cubit.dart';
import '../../features/profile/data/datasources/profile_local_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/profile_usecases.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/security_settings/data/datasources/security_local_datasource.dart';
import '../../features/security_settings/data/repositories/security_repository_impl.dart';
import '../../features/security_settings/domain/repositories/security_repository.dart';
import '../../features/security_settings/domain/usecases/security_usecases.dart';
import '../../features/security_settings/presentation/cubit/security_cubit.dart';

final flavorConfigProvider = Provider<FlavorConfig>((ref) => FlavorConfig.dev);

final appClockProvider = Provider<AppClock>((ref) => const SystemClock());

final marketFeedProvider = Provider<MarketFeed>((ref) {
  return InMemoryMarketFeed(clock: ref.watch(appClockProvider));
});

final paperOrderStoreProvider = Provider<PaperOrderStore>((ref) {
  return PaperOrderStore();
});

final paperSettlerProvider = Provider<PaperSettler>((ref) {
  return const ImmediatePaperSettler();
});

final paperLedgerProvider = Provider<PaperLedger>((ref) {
  return PaperLedger(
    orders: ref.watch(paperOrderStoreProvider),
    settler: ref.watch(paperSettlerProvider),
    clock: ref.watch(appClockProvider),
  );
});

final paperFillWatcherProvider = Provider<PaperFillWatcher>((ref) {
  final watcher = PaperFillWatcher(
    feed: ref.watch(marketFeedProvider),
    ledger: ref.watch(paperLedgerProvider),
  );
  ref.onDispose(watcher.dispose);
  return watcher;
});

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

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl(
    HomeLocalDataSource(ref.watch(secureStoreProvider)),
    feed: ref.watch(marketFeedProvider),
    ledger: ref.watch(paperLedgerProvider),
    clock: ref.watch(appClockProvider),
  );
});

final homeCubitProvider = Provider<HomeCubit>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final home = ref.watch(homeRepositoryProvider);
  final requireSession = RequireSession(auth);
  final cubit = HomeCubit(
    getOverview: GetDashboardOverview(requireSession, home),
    getHoldings: GetHoldings(requireSession, home),
    getWatchlist: GetWatchlist(requireSession, home),
    getWatchlistCandidates: GetWatchlistCandidates(requireSession, home),
    searchWatchlistCandidates: SearchWatchlistCandidates(requireSession, home),
    addWatchlistItem: AddWatchlistItem(requireSession, home),
    getAlerts: GetDashboardAlerts(requireSession, home),
    dismissAlert: DismissDashboardAlert(requireSession, home),
    getPromos: GetDashboardPromos(requireSession, home),
    getNews: GetNewsPreview(requireSession, home),
  );
  ref.onDispose(cubit.close);
  return cubit;
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(const ProfileLocalDataSource());
});

final profileCubitProvider = Provider<ProfileCubit>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final profile = ref.watch(profileRepositoryProvider);
  final requireSession = RequireSession(auth);
  final cubit = ProfileCubit(
    getOverview: GetProfileOverview(requireSession, profile),
    getRewards: GetRewardsTeasers(requireSession, profile),
    getShortcuts: GetProfileProductShortcuts(requireSession, profile),
    getVersion: GetAppVersionInfo(requireSession, profile),
    getLegalLinks: GetLegalLinks(requireSession, profile),
  );
  ref.onDispose(cubit.close);
  return cubit;
});

final productCatalogRepositoryProvider = Provider<ProductCatalogRepository>((
  ref,
) {
  return ProductCatalogRepositoryImpl(const ProductsLocalDataSource());
});

final productsCubitProvider = Provider<ProductsCubit>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final catalog = ref.watch(productCatalogRepositoryProvider);
  final cubit = ProductsCubit(
    GetProductCatalog(RequireSession(auth), GetEligibility(auth), catalog),
  );
  ref.onDispose(cubit.close);
  return cubit;
});

final securityRepositoryProvider = Provider<SecurityRepository>((ref) {
  return SecurityRepositoryImpl(SecurityLocalDataSource());
});

final securityCubitProvider = Provider<SecurityCubit>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final security = ref.watch(securityRepositoryProvider);
  final requireSession = RequireSession(auth);
  final cubit = SecurityCubit(
    getSettings: GetSecuritySettings(requireSession, security),
    getPreferences: GetAppPreferences(requireSession, security),
    setBiometric: SetBiometricEnabled(requireSession, security),
    setWhitelisting: SetAddressWhitelisting(requireSession, security),
    logout: Logout(LockSession(auth)),
    requestDocument: RequestAccountDocument(requireSession, security),
  );
  ref.onDispose(cubit.close);
  return cubit;
});

final inboxRepositoryProvider = Provider<InboxRepository>((ref) {
  return InboxRepositoryImpl(const InboxLocalDataSource());
});

final inboxCubitProvider = Provider<InboxCubit>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final inbox = ref.watch(inboxRepositoryProvider);
  final cubit = InboxCubit(GetInboxItems(RequireSession(auth), inbox));
  ref.onDispose(cubit.close);
  return cubit;
});

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return NewsRepositoryImpl(const NewsLocalDataSource());
});

final newsCubitProvider = Provider<NewsCubit>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final news = ref.watch(newsRepositoryProvider);
  final cubit = NewsCubit(GetNewsFeed(RequireSession(auth), news));
  ref.onDispose(cubit.close);
  return cubit;
});

final exploreRepositoryProvider = Provider<ExploreRepository>((ref) {
  return ExploreRepositoryImpl(
    const ExploreLocalDataSource(),
    feed: ref.watch(marketFeedProvider),
  );
});

final exploreCubitProvider = Provider<ExploreCubit>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final explore = ref.watch(exploreRepositoryProvider);
  final session = RequireSession(auth);
  final cubit = ExploreCubit(
    getFeed: GetExploreFeed(session, explore),
    getAssets: GetMarketAssets(session, explore),
    searchAssets: SearchExploreAssets(session, explore),
  );
  ref.onDispose(cubit.close);
  return cubit;
});

final fundingRepositoryProvider = Provider<FundingRepository>((ref) {
  return FundingRepositoryImpl(
    FundingLocalDataSource(),
    feed: ref.watch(marketFeedProvider),
    ledger: ref.watch(paperLedgerProvider),
  );
});

final fundingCubitProvider = Provider<FundingCubit>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final funding = ref.watch(fundingRepositoryProvider);
  final session = RequireSession(auth);
  final eligibility = GetEligibility(auth);
  final cubit = FundingCubit(
    getMethods: GetFundingMethods(session, funding),
    getFiatx: GetFiatxAssets(session, funding),
    getRails: GetBankRails(session, funding),
    getAccountStatus: GetFiatAccountStatus(session, funding),
    acceptTerms: AcceptFiatAccountTerms(session, funding),
    createUsd: CreatePersonalUsdAccount(session, eligibility, funding),
    getReceiveDetails: GetFiatReceiveDetails(session, funding),
    getFees: GetBankTransferFeeSchedule(session, funding),
    getReceivable: GetReceivableAssets(session, funding),
    getReceiveAddress: GetReceiveAddress(session, funding),
    getPurchasable: GetPurchasableAssets(session, funding),
    getBuyQuote: GetBuyQuote(session, eligibility, funding),
    getPaymentMethods: GetPaymentMethods(session, funding),
    submitBuy: SubmitBuyCrypto(session, eligibility, funding),
  );
  ref.onDispose(cubit.close);
  return cubit;
});

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepositoryImpl(CardLocalDataSource());
});

final cardCubitProvider = Provider<CardCubit>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final card = ref.watch(cardRepositoryProvider);
  final session = RequireSession(auth);
  final cubit = CardCubit(
    getStatus: GetCardStatus(session, card),
    restore: RestoreCardBalance(session),
    unfreeze: UnfreezeCard(session, card),
  );
  ref.onDispose(cubit.close);
  return cubit;
});

final swapRepositoryProvider = Provider<SwapRepository>((ref) {
  ref.watch(paperFillWatcherProvider);
  return SwapRepositoryImpl(
    SwapLocalDataSource(),
    feed: ref.watch(marketFeedProvider),
    ledger: ref.watch(paperLedgerProvider),
  );
});

final swapCubitProvider = Provider<SwapCubit>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final swap = ref.watch(swapRepositoryProvider);
  final session = RequireSession(auth);
  final eligibility = GetEligibility(auth);
  final cubit = SwapCubit(
    searchAssets: SearchSwapAssets(session, swap),
    getOrderTypes: GetSwapOrderTypes(session),
    watchRate: WatchSwapRate(session, swap),
    getQuote: GetSwapQuote(session, eligibility, swap),
    submit: SubmitSwap(session, eligibility, swap),
  );
  ref.onDispose(cubit.close);
  return cubit;
});

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepositoryImpl(
    OrdersLocalDataSource(store: ref.watch(paperOrderStoreProvider)),
    ledger: ref.watch(paperLedgerProvider),
  );
});

final ordersCubitProvider = Provider<OrdersCubit>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final orders = ref.watch(ordersRepositoryProvider);
  final cubit = OrdersCubit(GetOrderHistory(RequireSession(auth), orders));
  ref.onDispose(cubit.close);
  return cubit;
});

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return MarketRepositoryImpl(
    const MarketLocalDataSource(),
    feed: ref.watch(marketFeedProvider),
  );
});

final marketCubitProvider = Provider.autoDispose.family<MarketCubit, String>((
  ref,
  code,
) {
  final auth = ref.watch(authRepositoryProvider);
  final market = ref.watch(marketRepositoryProvider);
  final session = RequireSession(auth);
  final cubit = MarketCubit(
    getAsset: GetMarketAsset(session, market),
    getCandles: GetCandleChart(session, market),
    watchTicks: WatchMarketTicks(session, market),
    code: code,
  );
  ref.onDispose(cubit.close);
  return cubit;
});
