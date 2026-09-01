import 'package:flutter/material.dart';

import '../../../../core/money/money_format.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/freshness_chip.dart';
import '../../domain/entities/order_book.dart';
import '../copy/market_copy.dart';

class MarketOrderBook extends StatelessWidget {
  const MarketOrderBook({super.key, required this.book, this.onLevelSelected});

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
            if (loaded != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: _Spread(book: loaded)),
              FreshnessChip(freshness: loaded.freshness),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (loaded == null)
          Text(
            MarketCopy.bookUnavailable,
            style: AppTextStyles.meta.copyWith(color: scheme.onSurfaceVariant),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  MarketCopy.bids,
                  style: AppTextStyles.meta.copyWith(
                    color: scheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  MarketCopy.asks,
                  style: AppTextStyles.meta.copyWith(
                    color: scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          _ColumnHeaders(book: loaded),
          SizedBox(
            height: 160,
            child: _Levels(book: loaded, onLevelSelected: onLevelSelected),
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
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ColumnHeaders extends StatelessWidget {
  const _ColumnHeaders({required this.book});

  final OrderBook book;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final style = AppTextStyles.meta.copyWith(color: muted);
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${MarketCopy.size} ${book.currency.code}',
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  '${MarketCopy.price} ${book.quote.code}',
                  style: style,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${MarketCopy.price} ${book.quote.code}',
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  '${MarketCopy.size} ${book.currency.code}',
                  style: style,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Levels extends StatelessWidget {
  const _Levels({required this.book, required this.onLevelSelected});

  final OrderBook book;
  final ValueChanged<OrderBookLevel>? onLevelSelected;

  @override
  Widget build(BuildContext context) {
    final count =
        book.bids.length > book.asks.length
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
              child:
                  bid == null
                      ? const SizedBox.shrink()
                      : _LevelTile(
                        level: bid,
                        alignEnd: false,
                        onSelected: onLevelSelected,
                      ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child:
                  ask == null
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
    final priceColor =
        level.side == OrderBookSide.bid ? scheme.tertiary : scheme.error;
    final sizeStyle = AppTextStyles.meta.copyWith(
      color: scheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final priceStyle = AppTextStyles.meta.copyWith(
      color: priceColor,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final size = formatQuantity(level.size, withCode: false);
    final price = formatQuantity(level.price, withCode: false);
    final enabled = onSelected != null;
    return InkWell(
      key: Key('order_book_${level.side.name}_${level.price.amount}'),
      onTap: enabled ? () => onSelected!(level) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Row(
          children: [
            Expanded(
              child: _FitText(
                text: alignEnd ? price : size,
                style: alignEnd ? priceStyle : sizeStyle,
                align: Alignment.centerLeft,
                textAlign: TextAlign.start,
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Expanded(
              child: _FitText(
                text: alignEnd ? size : price,
                style: alignEnd ? sizeStyle : priceStyle,
                align: Alignment.centerRight,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FitText extends StatelessWidget {
  const _FitText({
    required this.text,
    required this.style,
    required this.align,
    required this.textAlign,
  });

  final String text;
  final TextStyle style;
  final Alignment align;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: align,
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}
