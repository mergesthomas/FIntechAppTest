import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/observe/settlement_breadcrumb.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../domain/entities/funding.dart';

final class FundingLocalDataSource {
  bool termsAccepted = false;
  FiatAccountStatus accountStatus = FiatAccountStatus.none;
  final Set<String> usdAccountRequests = {};
  final Set<String> buyRequests = {};
  final Map<String, BuyQuote> quotes = {};

  List<FundingMethod> methods() {
    return const [
      FundingMethod(
        rail: FundingRail.bank,
        label: 'Bank transfers',
        subtitle: 'USDx / EURx / GBPx',
      ),
      FundingMethod(
        rail: FundingRail.receiveCrypto,
        label: 'Add crypto',
        subtitle: 'Receive on-chain',
      ),
      FundingMethod(
        rail: FundingRail.buyCrypto,
        label: 'Buy crypto',
        subtitle: 'Instant / Apple Pay / Visa / Mastercard',
      ),
    ];
  }

  List<FiatxAsset> fiatxAssets() {
    return const [
      FiatxAsset(currency: Currency.usdx, feeTeaser: 'SWIFT free above \$5,000'),
      FiatxAsset(currency: Currency.eurx, feeTeaser: 'SEPA free above €100 else €5'),
      FiatxAsset(currency: Currency.gbpx, feeTeaser: 'Free above £100'),
    ];
  }

  List<BankRail> bankRails(Currency asset) {
    if (asset == Currency.usdx) {
      return [
        BankRail(id: 'open_usd', label: 'Open personal USD account', asset: asset),
        BankRail(id: 'ach', label: 'ACH', asset: asset),
        BankRail(id: 'swift', label: 'SWIFT', asset: asset),
      ];
    }
    return [
      BankRail(id: 'sepa', label: 'SEPA', asset: asset),
      BankRail(id: 'swift', label: 'SWIFT', asset: asset),
    ];
  }

  FiatReceiveDetails receiveDetails(Currency asset, String rail) {
    return FiatReceiveDetails(
      asset: asset,
      rail: rail,
      beneficiary: 'Local emulator beneficiary',
      ibanOrAccount: asset == Currency.usdx ? '00000000' : 'LT000000000000',
      reference: 'LOCAL-REF',
    );
  }

  String feeSchedule(Currency asset) {
    return switch (asset.code) {
      'EURx' => 'SEPA free above €100 else €5; SWIFT EURx €25',
      'USDx' => 'USDx free SWIFT above \$5,000',
      'GBPx' => 'GBPx free above £100',
      _ => 'Fee schedule placeholder',
    };
  }

  List<ReceivableAsset> receivable(String query) {
    final all = const [
      ReceivableAsset(currency: Currency.btc, network: 'Bitcoin'),
      ReceivableAsset(currency: Currency.eth, network: 'Ethereum'),
      ReceivableAsset(currency: Currency.usdc, network: 'Ethereum'),
    ];
    if (query.isEmpty) {
      return all;
    }
    final q = query.toLowerCase();
    return all
        .where(
          (a) =>
              a.currency.code.toLowerCase().contains(q) ||
              a.network.toLowerCase().contains(q),
        )
        .toList();
  }

  ReceiveAddress receiveAddress(Currency currency) {
    return ReceiveAddress(
      currency: currency,
      network: currency == Currency.btc ? 'Bitcoin' : 'Ethereum',
      address: 'local1emulatorreceiveaddress',
      qrUri: 'crypto:${currency.code.toLowerCase()}:local1emulatorreceiveaddress',
    );
  }

  List<PurchasableAsset> purchasable(String query) {
    final all = [
      PurchasableAsset(
        currency: Currency.btc,
        displayName: 'Bitcoin',
        price: Money.parse('78899.13', Currency.usd),
        freshness: QuoteFreshness.stale,
      ),
      PurchasableAsset(
        currency: Currency.eth,
        displayName: 'Ethereum',
        price: Money.parse('2400.00', Currency.usd),
        freshness: QuoteFreshness.stale,
      ),
    ];
    if (query.isEmpty) {
      return all;
    }
    final q = query.toLowerCase();
    return all
        .where(
          (a) =>
              a.currency.code.toLowerCase().contains(q) ||
              a.displayName.toLowerCase().contains(q),
        )
        .toList();
  }

  BuyQuote buyQuote({required Currency asset, required Money spend}) {
    final quote = BuyQuote(
      quoteId: 'quote-${asset.code}-${spend.amount}',
      spend: spend,
      receive: Money.parse('0.001', asset),
      cashbackTeaser: 'Cashback teaser — placeholder',
      freshness: QuoteFreshness.stale,
    );
    quotes[quote.quoteId] = quote;
    return quote;
  }

  List<PaymentMethodOption> paymentMethods() {
    return const [
      PaymentMethodOption(id: 'apple_pay', label: 'Apple Pay'),
      PaymentMethodOption(id: 'visa', label: 'Visa'),
      PaymentMethodOption(id: 'mastercard', label: 'Mastercard'),
    ];
  }

  List<String> frequencies() => const ['Instant'];

  SettlementStatus createUsdAccount(String requestId) {
    if (usdAccountRequests.contains(requestId)) {
      return SettlementStatus.inFlight;
    }
    usdAccountRequests.add(requestId);
    accountStatus = FiatAccountStatus.inFlight;
    logSettlementBreadcrumb(
      requestId: requestId,
      status: SettlementStatus.inFlight,
    );
    return SettlementStatus.inFlight;
  }

  BuySubmit submitBuy({
    required String requestId,
    required String quoteId,
    required String paymentMethodId,
    required Money amount,
    required String frequency,
  }) {
    if (buyRequests.contains(requestId)) {
      return BuySubmit(requestId: requestId, settlement: SettlementStatus.inFlight);
    }
    buyRequests.add(requestId);
    logSettlementBreadcrumb(
      requestId: requestId,
      status: SettlementStatus.inFlight,
    );
    return BuySubmit(requestId: requestId, settlement: SettlementStatus.inFlight);
  }
}
