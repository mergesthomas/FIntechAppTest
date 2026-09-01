import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/market/candle_interval.dart';
import '../../../../core/market/candle_series.dart';
import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/money_format.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/notice/user_notice.dart';
import '../../../../core/notice/user_notice_cubit.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_failure_view.dart';
import '../../../../core/widgets/freshness_chip.dart';
import '../../../../core/widgets/trade_actions.dart';
import '../../../orders/presentation/widgets/asset_open_orders.dart';
import '../../domain/entities/market_asset.dart';
import '../../domain/entities/order_book.dart';
import '../copy/market_copy.dart';
import '../cubit/market_cubit.dart';
import '../market_swap_link.dart';
import '../widgets/market_candlestick_chart.dart';
import '../widgets/market_interval_chips.dart';
import '../widgets/market_ohlc_bar.dart';
import '../widgets/market_order_book.dart';

class MarketPage extends ConsumerStatefulWidget {
  const MarketPage({super.key, required this.code});

  final String code;

  @override
  ConsumerState<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends ConsumerState<MarketPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(marketCubitProvider(widget.code)).load();
        ref.read(openOrdersCubitProvider(widget.code)).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cubit = ref.watch(marketCubitProvider(widget.code));
    final openOrders = ref.watch(openOrdersCubitProvider(widget.code));
    return BlocProvider.value(
      value: cubit,
      child: BlocProvider.value(
        value: openOrders,
        child: Scaffold(
          appBar: AppBar(title: Text(widget.code)),
          body: BlocBuilder<MarketCubit, MarketState>(
            buildWhen:
                (previous, current) =>
                    previous.runtimeType != current.runtimeType,
            builder: (context, state) {
              return switch (state) {
                MarketLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                MarketEmpty() => const AppEmptyState(message: 'No market data'),
                MarketFailure(:final failure) => AppFailureView(
                  failure: failure,
                  onRetry: () => cubit.load(),
                ),
                MarketSuccess() => _Body(code: widget.code),
              };
            },
          ),
          bottomNavigationBar: Material(
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: AppSpacing.xxs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Divider(
                    height: 1,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  TradeActions(
                    onExchange: () => context.push(
                      MarketSwapLink.instantFor(widget.code),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.code});

  final String code;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _chartKey = GlobalKey<MarketCandlestickChartState>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<MarketCubit, MarketState>(
      listenWhen: (previous, current) {
        final prev =
            previous is MarketSuccess ? previous.selectionFailure : null;
        final next = current is MarketSuccess ? current.selectionFailure : null;
        return next != null && next != prev;
      },
      listener: (context, state) {
        if (state is! MarketSuccess || state.selectionFailure == null) {
          return;
        }
        context.showUserNotice(
          UserNotice.error(MarketCopy.bookFailure(state.selectionFailure!)),
        );
        context.read<MarketCubit>().clearSelectionFailure();
      },
      child: CustomScrollView(
        key: const Key('market_scroll'),
        slivers: [
          const SliverToBoxAdapter(child: _Header()),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.sm,
                AppSpacing.pageHorizontal,
                0,
              ),
              child: AssetOpenOrders(),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: BlocSelector<
                  MarketCubit,
                  MarketState,
                  ({CandleSeries? candles, bool showVolume})
                >(
                  selector: (state) {
                    if (state is! MarketSuccess) {
                      return (candles: null, showVolume: true);
                    }
                    return (
                      candles: state.candles,
                      showVolume: state.showVolume,
                    );
                  },
                  builder: (context, view) {
                    final series = view.candles;
                    if (series == null) {
                      return const SizedBox.shrink();
                    }
                    return KeyedSubtree(
                      key: const Key('market_candlestick_chart'),
                      child: MarketCandlestickChart(
                        key: _chartKey,
                        series: series,
                        showVolume: view.showVolume,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.xs,
                AppSpacing.pageHorizontal,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  BlocSelector<MarketCubit, MarketState, CandleInterval>(
                    selector: (state) => state is MarketSuccess
                        ? state.candles.interval
                        : CandleInterval.m15,
                    builder: (context, interval) {
                      return MarketIntervalChips(
                        selected: interval,
                        onSelected: context.read<MarketCubit>().selectInterval,
                      );
                    },
                  ),
                  BlocSelector<MarketCubit, MarketState, bool>(
                    selector: (state) =>
                        state is MarketSuccess ? state.showVolume : true,
                    builder: (context, showVolume) {
                      return _ChartToolbar(
                        showVolume: showVolume,
                        onReset: () => _chartKey.currentState?.resetZoom(),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  BlocSelector<MarketCubit, MarketState, OrderBook?>(
                    selector: (state) =>
                        state is MarketSuccess ? state.orderBook : null,
                    builder: (context, book) {
                      return MarketOrderBook(
                        book: book,
                        onLevelSelected:
                            book?.freshness == QuoteFreshness.disconnected
                                ? null
                                : (level) => _selectLevel(context, level),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectLevel(BuildContext context, OrderBookLevel level) async {
    final draft = await context.read<MarketCubit>().selectLevel(
      side: level.side,
      price: level.price,
    );
    if (draft == null || !context.mounted) {
      return;
    }
    context.push(MarketSwapLink.limitFromDraft(draft));
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.md,
        AppSpacing.pageHorizontal,
        0,
      ),
      child: BlocSelector<MarketCubit, MarketState, MarketAsset?>(
        selector: (state) => state is MarketSuccess ? state.asset : null,
        builder: (context, asset) {
          if (asset == null) {
            return const SizedBox.shrink();
          }
          final up = asset.change24h >= Decimal.zero;
          final scheme = Theme.of(context).colorScheme;
          return BlocSelector<MarketCubit, MarketState, OhlcvCandle?>(
            selector:
                (state) => state is MarketSuccess ? state.candles.latest : null,
            builder: (context, latest) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    style: AppTextStyles.secondary.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatMoney(asset.price, withCode: true),
                          key: const Key('market_price'),
                          style: AppTextStyles.balance,
                        ),
                      ),
                      FreshnessChip(freshness: asset.freshness),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    formatPercent(asset.change24h),
                    style: AppTextStyles.secondary.copyWith(
                      color: AppSemanticColors.change(scheme, up: up),
                    ),
                  ),
                  if (latest != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    MarketOhlcBar(
                      key: const Key('market_ohlc_stats'),
                      candle: latest,
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ChartToolbar extends StatelessWidget {
  const _ChartToolbar({required this.showVolume, required this.onReset});

  final bool showVolume;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        TextButton(
          key: const Key('market_volume_toggle'),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: context.read<MarketCubit>().toggleVolume,
          child: Text(
            MarketCopy.volume,
            style: AppTextStyles.meta.copyWith(
              color: showVolume ? scheme.onSurface : scheme.onSurfaceVariant,
              fontWeight: showVolume ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        const Spacer(),
        TextButton(
          key: const Key('market_zoom_reset'),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: onReset,
          child: Text(
            MarketCopy.resetZoom,
            style: AppTextStyles.meta.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
