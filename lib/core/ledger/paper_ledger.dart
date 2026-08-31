import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';

import '../clock/app_clock.dart';
import '../error/failure.dart';
import '../money/currency.dart';
import '../money/money.dart';
import '../observe/settlement_breadcrumb.dart';
import '../settlement/settlement_status.dart';
import 'ledger_lot.dart';
import 'paper_order.dart';
import 'paper_settler.dart';

enum LedgerBook { savings, credit }

final class LedgerLine {
  const LedgerLine({
    required this.book,
    required this.delta,
  });

  final LedgerBook book;
  final Money delta;
}

final class _Hold {
  const _Hold({required this.book, required this.amount});

  final LedgerBook book;
  final Money amount;
}

final class PaperLedger {
  PaperLedger({
    required PaperOrderStore orders,
    required PaperSettler settler,
    AppClock clock = const SystemClock(),
  }) : _orders = orders,
       _settler = settler,
       _clock = clock {
    seed();
  }

  final PaperOrderStore _orders;
  final PaperSettler _settler;
  final AppClock _clock;
  final Map<String, Decimal> _balances = {};
  final Map<String, SettlementStatus> _posts = {};
  final Map<String, _Hold> _holds = {};
  final List<LedgerLot> _lots = [];

  PaperOrderStore get orders => _orders;

  List<LedgerLot> get lots => List.unmodifiable(_lots);

  void seed() {
    final now = _clock.now().toUtc();
    _seedBuy(
      id: 'usdc',
      receive: Money.parse('10000.00', Currency.usdc),
      at: now.subtract(const Duration(days: 548)),
    );
    _seedBuy(
      id: 'btc',
      receive: Money.parse('0.15', Currency.btc),
      at: now.subtract(const Duration(days: 487)),
    );
    _seedBuy(
      id: 'doge',
      receive: Money.parse('10000', Currency.doge),
      at: now.subtract(const Duration(days: 243)),
    );
    _seedBuy(
      id: 'pepe',
      receive: Money.parse('80000000', Currency.pepe),
      at: now.subtract(const Duration(days: 77)),
    );
    _set(LedgerBook.savings, Money.parse('-1.16', Currency.eurx));
  }

  List<Money> balances(LedgerBook book) {
    final prefix = '${book.name}:';
    return [
      for (final entry in _balances.entries)
        if (entry.key.startsWith(prefix) && entry.value != Decimal.zero)
          Money.fromDecimal(
            entry.value,
            _currencyOf(entry.key.substring(prefix.length)),
          ),
    ];
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
        if (next.isNegative && line.delta.currency != Currency.eurx) {
          return Either.left(const ValidationFailure('insufficient_balance'));
        }
      }
    }
    _posts[requestId] = SettlementStatus.inFlight;
    _orders.add(
      order.copyWith(
        status: PaperOrderStatus.open,
        createdAt: order.createdAt ?? _clock.now().toUtc(),
      ),
    );
    logSettlementBreadcrumb(
      requestId: requestId,
      status: SettlementStatus.inFlight,
    );
    await _settler.schedule(requestId, () {
      final filledAt = _clock.now().toUtc();
      for (final line in lines) {
        _set(line.book, balance(line.book, line.delta.currency) + line.delta);
        _recordLot(line.delta, filledAt);
      }
      _posts[requestId] = SettlementStatus.confirmed;
      _orders.setStatus(
        order.id,
        PaperOrderStatus.filled,
        filledAt: filledAt,
      );
      logSettlementBreadcrumb(
        requestId: requestId,
        status: SettlementStatus.confirmed,
      );
    });
    return Either.right(
      _posts[requestId] ?? SettlementStatus.unknown,
    );
  }

  Future<Either<Failure, SettlementStatus>> placeHold({
    required String requestId,
    required Money hold,
    required LedgerBook book,
    required PaperOrder order,
  }) async {
    if (requestId.isEmpty) {
      return Either.left(const ValidationFailure('request_id_required'));
    }
    final existing = _posts[requestId];
    if (existing != null) {
      return Either.right(existing);
    }
    if (!hold.isPositive) {
      return Either.left(const ValidationFailure('amount_required'));
    }
    final next = balance(book, hold.currency) - hold;
    if (next.isNegative && hold.currency != Currency.eurx) {
      return Either.left(const ValidationFailure('insufficient_balance'));
    }
    _posts[requestId] = SettlementStatus.inFlight;
    _orders.add(
      order.copyWith(
        status: PaperOrderStatus.open,
        createdAt: order.createdAt ?? _clock.now().toUtc(),
      ),
    );
    _holds[order.id] = _Hold(book: book, amount: hold);
    _set(book, next);
    logSettlementBreadcrumb(
      requestId: requestId,
      status: SettlementStatus.inFlight,
    );
    _posts[requestId] = SettlementStatus.confirmed;
    logSettlementBreadcrumb(
      requestId: requestId,
      status: SettlementStatus.confirmed,
    );
    return Either.right(SettlementStatus.confirmed);
  }

  Future<Either<Failure, SettlementStatus>> fillHold({
    required String orderId,
    required Money credit,
    required LedgerBook book,
  }) async {
    final order = _orders.byId(orderId);
    final hold = _holds[orderId];
    if (order == null || hold == null) {
      return Either.left(const ValidationFailure('order_not_found'));
    }
    if (order.status != PaperOrderStatus.open) {
      return Either.left(const ValidationFailure('order_not_open'));
    }
    if (!credit.isPositive) {
      return Either.left(const ValidationFailure('amount_required'));
    }
    final fillId = 'fill-$orderId';
    final existing = _posts[fillId];
    if (existing != null) {
      return Either.right(existing);
    }
    _posts[fillId] = SettlementStatus.inFlight;
    logSettlementBreadcrumb(
      requestId: fillId,
      status: SettlementStatus.inFlight,
    );
    _set(book, balance(book, credit.currency) + credit);
    _holds.remove(orderId);
    _orders.setStatus(
      orderId,
      PaperOrderStatus.filled,
      filledAt: _clock.now().toUtc(),
    );
    _posts[fillId] = SettlementStatus.confirmed;
    logSettlementBreadcrumb(
      requestId: fillId,
      status: SettlementStatus.confirmed,
    );
    return Either.right(SettlementStatus.confirmed);
  }

  Future<Either<Failure, SettlementStatus>> cancelHold({
    required String requestId,
    required String orderId,
  }) async {
    if (requestId.isEmpty) {
      return Either.left(const ValidationFailure('request_id_required'));
    }
    final existing = _posts[requestId];
    if (existing != null) {
      return Either.right(existing);
    }
    final order = _orders.byId(orderId);
    final hold = _holds[orderId];
    if (order == null || hold == null) {
      return Either.left(const ValidationFailure('order_not_found'));
    }
    if (order.status != PaperOrderStatus.open) {
      return Either.left(const ValidationFailure('order_not_open'));
    }
    _posts[requestId] = SettlementStatus.inFlight;
    logSettlementBreadcrumb(
      requestId: requestId,
      status: SettlementStatus.inFlight,
    );
    _set(hold.book, balance(hold.book, hold.amount.currency) + hold.amount);
    _holds.remove(orderId);
    _orders.setStatus(orderId, PaperOrderStatus.canceled);
    _posts[requestId] = SettlementStatus.confirmed;
    logSettlementBreadcrumb(
      requestId: requestId,
      status: SettlementStatus.confirmed,
    );
    return Either.right(SettlementStatus.confirmed);
  }

  String _key(LedgerBook book, Currency currency) =>
      '${book.name}:${currency.code}';

  void _set(LedgerBook book, Money money) {
    _balances[_key(book, money.currency)] = money.amount;
  }

  void _recordLot(Money delta, DateTime at) {
    if (delta.amount == Decimal.zero) {
      return;
    }
    _lots.add(
      LedgerLot(currency: delta.currency, quantity: delta.amount, at: at),
    );
  }

  void _seedBuy({
    required String id,
    required Money receive,
    required DateTime at,
  }) {
    final requestId = 'seed-buy-$id';
    _set(
      LedgerBook.savings,
      balance(LedgerBook.savings, receive.currency) + receive,
    );
    _recordLot(receive, at);
    _posts[requestId] = SettlementStatus.confirmed;
    _orders.add(
      PaperOrder(
        id: 'ord-$requestId',
        requestId: requestId,
        pair: '${receive.currency.code}/USD',
        side: PaperSide.buy,
        status: PaperOrderStatus.filled,
        amount: receive,
        wallet: 'card',
        venue: PaperVenue.market,
        receive: receive.currency,
        createdAt: at,
        filledAt: at,
      ),
    );
  }

  Currency _currencyOf(String code) {
    return Currency.tryParse(code) ?? Currency(code: code, scale: 8);
  }
}
