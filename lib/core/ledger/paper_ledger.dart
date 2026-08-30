import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';

import '../error/failure.dart';
import '../money/currency.dart';
import '../money/money.dart';
import '../observe/settlement_breadcrumb.dart';
import '../settlement/settlement_status.dart';
import 'paper_order.dart';
import 'paper_settler.dart';

enum LedgerBook { savings, credit, futures }

final class LedgerLine {
  const LedgerLine({
    required this.book,
    required this.delta,
  });

  final LedgerBook book;
  final Money delta;
}

final class PaperLedger {
  PaperLedger({
    required PaperOrderStore orders,
    required PaperSettler settler,
  })  : _orders = orders,
        _settler = settler {
    seed();
  }

  final PaperOrderStore _orders;
  final PaperSettler _settler;
  final Map<String, Decimal> _balances = {};
  final Map<String, SettlementStatus> _posts = {};

  PaperOrderStore get orders => _orders;

  void seed() {
    _set(LedgerBook.savings, Money.parse('120.00', Currency.nexo));
    _set(LedgerBook.savings, Money.parse('0.15', Currency.btc));
    _set(LedgerBook.savings, Money.parse('-1.16', Currency.eurx));
    _set(LedgerBook.savings, Money.parse('10000.00', Currency.usd));
    _set(LedgerBook.futures, Money.parse('186.25', Currency.usdt));
  }

  Money balance(LedgerBook book, Currency currency) {
    return Money.fromDecimal(
      _balances[_key(book, currency)] ?? Decimal.zero,
      currency,
    );
  }

  Future<Either<Failure, SettlementStatus>> post({
    required String requestId,
    required List<LedgerLine> lines,
    required PaperOrder order,
  }) async {
    if (requestId.isEmpty) {
      return Either.left(const ValidationFailure('request_id_required'));
    }
    final existing = _posts[requestId];
    if (existing != null) {
      return Either.right(existing);
    }
    for (final line in lines) {
      if (line.delta.isNegative) {
        final next = balance(line.book, line.delta.currency) + line.delta;
        if (next.isNegative &&
            line.delta.currency != Currency.eurx) {
          return Either.left(const ValidationFailure('insufficient_balance'));
        }
      }
    }
    _posts[requestId] = SettlementStatus.inFlight;
    _orders.add(order.copyWith(status: PaperOrderStatus.open));
    logSettlementBreadcrumb(
      requestId: requestId,
      status: SettlementStatus.inFlight,
    );
    await _settler.schedule(requestId, () {
      for (final line in lines) {
        _set(line.book, balance(line.book, line.delta.currency) + line.delta);
      }
      _posts[requestId] = SettlementStatus.confirmed;
      _orders.setStatus(order.id, PaperOrderStatus.filled);
      logSettlementBreadcrumb(
        requestId: requestId,
        status: SettlementStatus.confirmed,
      );
    });
    return Either.right(
      _posts[requestId] ?? SettlementStatus.unknown,
    );
  }

  String _key(LedgerBook book, Currency currency) =>
      '${book.name}:${currency.code}';

  void _set(LedgerBook book, Money money) {
    _balances[_key(book, money.currency)] = money.amount;
  }
}
