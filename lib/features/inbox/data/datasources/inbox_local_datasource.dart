import '../../../../core/clock/app_clock.dart';
import '../../../../core/ledger/paper_order.dart';
import '../../../../core/market/market_feed.dart';
import '../../../../core/money/currency.dart';
import '../../domain/entities/inbox_item.dart';
import '../inbox_date_label.dart';
import '../inbox_unit_price.dart';

final class InboxLocalDataSource {
  InboxLocalDataSource({
    required PaperOrderStore store,
    required MarketFeed feed,
    AppClock clock = const SystemClock(),
  }) : _store = store,
       _feed = feed,
       _clock = clock;

  final PaperOrderStore _store;
  final MarketFeed _feed;
  final AppClock _clock;

  List<InboxItem> items() {
    final now = _clock.now().toUtc();
    final activity = [
      for (final order in _store.all)
        if (_isPast(order)) _fromOrder(order, now),
    ];
    activity.sort((a, b) {
      final byTime = b.occurredAt.compareTo(a.occurredAt);
      if (byTime != 0) {
        return byTime;
      }
      return a.title.compareTo(b.title);
    });
    return activity;
  }

  bool _isPast(PaperOrder order) {
    return order.status == PaperOrderStatus.filled ||
        order.status == PaperOrderStatus.canceled;
  }

  InboxItem _fromOrder(PaperOrder order, DateTime now) {
    final occurredAt = order.occurredAt ?? now;
    return InboxItem(
      id: order.id,
      title: _title(order),
      amount: order.amount,
      dateLabel: inboxDateLabel(occurredAt, now),
      kind: _kind(order),
      occurredAt: occurredAt,
      unitPrice: inboxUnitPriceUsd(
        feed: _feed,
        asset: _pricedAsset(order),
        at: occurredAt,
        now: now,
      ),
      requestId: order.requestId,
    );
  }

  InboxItemKind _kind(PaperOrder order) {
    if (order.status == PaperOrderStatus.canceled) {
      return InboxItemKind.canceled;
    }
    return order.side == PaperSide.buy ? InboxItemKind.buy : InboxItemKind.swap;
  }

  String _title(PaperOrder order) {
    final from = order.pay?.code ?? _base(order.pair);
    final to = order.receive?.code ?? _quote(order.pair);
    if (order.status == PaperOrderStatus.canceled) {
      if (order.side == PaperSide.buy) {
        return 'Canceled $to buy';
      }
      return 'Canceled $from to $to swap';
    }
    if (order.side == PaperSide.buy) {
      return 'Bought $to';
    }
    return 'Swapped $from to $to';
  }

  Currency _pricedAsset(PaperOrder order) {
    return order.receive ?? order.amount.currency;
  }

  String _base(String pair) {
    final split = pair.indexOf('/');
    return split < 0 ? pair : pair.substring(0, split);
  }

  String _quote(String pair) {
    final split = pair.indexOf('/');
    return split < 0 ? pair : pair.substring(split + 1);
  }
}
