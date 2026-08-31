import 'package:flutter/material.dart';

import '../../../../core/money/money_format.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/freshness_chip.dart';
import '../../domain/entities/order_book.dart';
import '../copy/market_copy.dart';

class MarketOrderBook extends StatelessWidget {
  const MarketOrderBook({
    super.key,
    required this.book,
    this.onLevelSelected,
  });

  final OrderBook? book;
  final ValueChanged<OrderBookLevel>? onLevelSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final loaded = book;
    return Column(
      key: const Key('market_order_book'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(MarketCopy.orderBook, style: AppTextStyles.secondary),
            const Spacer(),
            if (loaded != null) FreshnessChip(freshness: loaded.freshness),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (loaded == null)
          Text(
            MarketCopy.bookUnavailable,
            style: AppTextStyles.meta.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else ...[
          _Spread(book: loaded),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              Expanded(
                child: Text(
                  MarketCopy.bids,
                  style: AppTextStyles.meta.copyWith(
                    color: scheme.tertiary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  MarketCopy.asks,
                  style: AppTextStyles.meta.copyWith(
                    color: scheme.error,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 160,
            child: _Levels(
              book: loaded,
              onLevelSelected: onLevelSelected,
            ),
          ),
        ],
      ],
    );
  }
}

class _Spread extends StatelessWidget {
  const _Spread({required this.book});

  final OrderBook book;

  @override
  Widget build(BuildContext context) {
    final bid = book.bids.firstOrNull?.price;
    final ask = book.asks.firstOrNull?.price;
    if (bid == null || ask == null || bid.currency != ask.currency) {
      return const SizedBox.shrink();
    }
    final spread = ask - bid;
    return Text(
      key: const Key('market_order_book_spread'),
      '${MarketCopy.spread} ${formatQuantity(spread)}',
      style: AppTextStyles.meta.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _Levels extends StatelessWidget {
  const _Levels({
    required this.book,
    required this.onLevelSelected,
  });

  final OrderBook book;
  final ValueChanged<OrderBookLevel>? onLevelSelected;

  @override
  Widget build(BuildContext context) {
    final count = book.bids.length > book.asks.length
        ? book.bids.length
        : book.asks.length;
    return ListView.builder(
      key: const Key('market_order_book_list'),
      itemCount: count,
      itemBuilder: (context, index) {
        final bid = index < book.bids.length ? book.bids[index] : null;
        final ask = index < book.asks.length ? book.asks[index] : null;
        return Row(
          children: [
            Expanded(
              child: bid == null
                  ? const SizedBox.shrink()
                  : _LevelTile(
                      level: bid,
                      alignEnd: false,
                      onSelected: onLevelSelected,
                    ),
            ),
            Expanded(
              child: ask == null
                  ? const SizedBox.shrink()
                  : _LevelTile(
                      level: ask,
                      alignEnd: true,
                      onSelected: onLevelSelected,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.alignEnd,
    required this.onSelected,
  });

  final OrderBookLevel level;
  final bool alignEnd;
  final ValueChanged<OrderBookLevel>? onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final priceColor = level.side == OrderBookSide.bid
        ? scheme.tertiary
        : scheme.error;
    final enabled = onSelected != null;
    return InkWell(
      key: Key(
        'order_book_${level.side.name}_${level.price.amount}',
      ),
      onTap: enabled ? () => onSelected!(level) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: alignEnd
            ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    formatQuantity(level.price),
                    style: AppTextStyles.meta.copyWith(color: priceColor),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    formatQuantity(level.size),
                    style: AppTextStyles.meta.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Text(
                    formatQuantity(level.size),
                    style: AppTextStyles.meta.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    formatQuantity(level.price),
                    style: AppTextStyles.meta.copyWith(color: priceColor),
                  ),
                ],
              ),
      ),
    );
  }
}
