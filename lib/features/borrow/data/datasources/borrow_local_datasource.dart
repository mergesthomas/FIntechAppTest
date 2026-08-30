import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/observe/settlement_breadcrumb.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../domain/entities/borrow.dart';

final class BorrowLocalDataSource {
  final Map<String, BorrowQuote> quotes = {};
  final Set<String> borrowRequests = {};
  final Set<String> repayRequests = {};
  CreditLineOptimization optimization = const CreditLineOptimization(
    automaticCollateralTransfer: true,
    fixedTermUnlock: false,
    lowInterestBorrowing: false,
  );

  LoansOverview overview() {
    return LoansOverview(
      available: Money.zero(Currency.xusd),
      outstanding: Money.parse('14694.96', Currency.xusd),
    );
  }

  List<LoanProduct> products() {
    return [
      LoanProduct(
        id: 'classic',
        label: 'Classic Credit Line',
        status: 'Available',
        outstanding: Money.parse('14625.44', Currency.xusd),
      ),
      LoanProduct(
        id: 'card',
        label: 'Nexo Card',
        status: 'Active',
        outstanding: Money.parse('69.52', Currency.xusd),
      ),
      LoanProduct(
        id: 'zero',
        label: 'Zero-interest Credit',
        status: 'Active',
        outstanding: Money.zero(Currency.xusd),
      ),
      LoanProduct(
        id: 'booster',
        label: 'Booster',
        status: 'Available',
        outstanding: Money.zero(Currency.xusd),
      ),
    ];
  }

  CreditLineOverview creditLine(String productId) {
    final product = products().firstWhere(
      (p) => p.id == productId,
      orElse: () => products().first,
    );
    return CreditLineOverview(
      productId: product.id,
      available: Money.zero(Currency.xusd),
      outstanding: product.outstanding,
      health: LoanHealth.good,
    );
  }

  BorrowQuote quote({required String productId, required Money amount}) {
    final q = BorrowQuote(
      quoteId: 'borrow-$productId-${amount.amount}',
      productId: productId,
      amount: amount,
      ltvTeaser: '50% LTV placeholder',
      freshness: QuoteFreshness.stale,
    );
    quotes[q.quoteId] = q;
    return q;
  }

  List<CollateralAsset> collateral() {
    return const [
      CollateralAsset(currency: Currency.btc, ltvTeaser: '50% LTV'),
      CollateralAsset(currency: Currency.eth, ltvTeaser: '50% LTV'),
      CollateralAsset(currency: Currency.sol, ltvTeaser: '50% LTV'),
      CollateralAsset(currency: Currency.xrp, ltvTeaser: '50% LTV'),
    ];
  }

  BorrowSubmit borrow({required String requestId, required String quoteId}) {
    if (borrowRequests.contains(requestId)) {
      return BorrowSubmit(
        requestId: requestId,
        settlement: SettlementStatus.inFlight,
      );
    }
    borrowRequests.add(requestId);
    logSettlementBreadcrumb(
      requestId: requestId,
      status: SettlementStatus.inFlight,
    );
    return BorrowSubmit(
      requestId: requestId,
      settlement: SettlementStatus.inFlight,
    );
  }

  BorrowSubmit repay({
    required String requestId,
    required String loanId,
    required Money amount,
  }) {
    if (repayRequests.contains(requestId)) {
      return BorrowSubmit(
        requestId: requestId,
        settlement: SettlementStatus.inFlight,
      );
    }
    repayRequests.add(requestId);
    logSettlementBreadcrumb(
      requestId: requestId,
      status: SettlementStatus.inFlight,
    );
    return BorrowSubmit(
      requestId: requestId,
      settlement: SettlementStatus.inFlight,
    );
  }

  SettlementStatus updateOptimization({
    required String requestId,
    required CreditLineOptimization flags,
  }) {
    optimization = flags;
    logSettlementBreadcrumb(
      requestId: requestId,
      status: SettlementStatus.inFlight,
    );
    return SettlementStatus.inFlight;
  }
}
