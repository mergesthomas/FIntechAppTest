import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money_format.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/detail_row.dart';
import '../../../auth/presentation/widgets/pin_keypad.dart';
import '../../domain/entities/funding.dart';
import '../cubit/funding_cubit.dart';

class FundingPage extends StatefulWidget {
  const FundingPage({super.key});

  @override
  State<FundingPage> createState() => _FundingPageState();
}

class _FundingPageState extends State<FundingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await context.read<FundingCubit>().load();
      if (!mounted) {
        return;
      }
      final params = GoRouterState.of(context).uri.queryParameters;
      if (params['action'] != 'buy') {
        return;
      }
      final currency = Currency.tryParse(params['asset']);
      if (currency != null) {
        await context.read<FundingCubit>().openBuyAsset(currency);
        return;
      }
      await context.read<FundingCubit>().openBuy();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add funds'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final state = context.read<FundingCubit>().state;
            if (state is FundingReady && state.surface != FundingSurface.hub) {
              context.read<FundingCubit>().backToHub();
              return;
            }
            Navigator.of(context).maybePop();
          },
        ),
      ),
      body: BlocBuilder<FundingCubit, FundingState>(
        builder: (context, state) {
          return switch (state) {
            FundingLoading() => const Center(child: CircularProgressIndicator()),
            FundingEmpty() => const AppEmptyState(message: 'No funding methods'),
            FundingFailure(:final failure) => AppEmptyState(message: '$failure'),
            FundingReady() => _FundingBody(state: state),
          };
        },
      ),
    );
  }
}

class _FundingBody extends StatelessWidget {
  const _FundingBody({required this.state});

  final FundingReady state;

  @override
  Widget build(BuildContext context) {
    return switch (state.surface) {
      FundingSurface.hub => _Hub(state: state),
      FundingSurface.fiatx => _Fiatx(state: state),
      FundingSurface.bankRails => _Rails(state: state),
      FundingSurface.openUsd => _OpenUsd(state: state),
      FundingSurface.receiveFiat => _ReceiveFiat(state: state),
      FundingSurface.receiveAssets => _ReceiveAssets(state: state),
      FundingSurface.receiveCrypto => _ReceiveCrypto(state: state),
      FundingSurface.buyAssets => _BuyAssets(state: state),
      FundingSurface.buyAmount => _BuyAmount(state: state),
      FundingSurface.buyPreview => _BuyPreview(state: state),
      FundingSurface.buyResult => _BuyResult(state: state),
    };
  }
}

class _Hub extends StatelessWidget {
  const _Hub({required this.state});

  final FundingReady state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.md,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      children: [
        for (final method in state.methods)
          ListTile(
            key: Key('funding_${method.rail.name}'),
            contentPadding: EdgeInsets.zero,
            title: Text(method.label),
            subtitle: Text(method.subtitle),
            trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            onTap: () => switch (method.rail) {
              FundingRail.bank => context.read<FundingCubit>().openBank(),
              FundingRail.receiveCrypto =>
                context.read<FundingCubit>().openReceiveCrypto(),
              FundingRail.buyCrypto =>
                context.read<FundingCubit>().openBuy(),
            },
          ),
      ],
    );
  }
}

class _Fiatx extends StatelessWidget {
  const _Fiatx({required this.state});

  final FundingReady state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.xs,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      children: [
        for (final asset in state.fiatx)
          ListTile(
            title: Text(asset.currency.code),
            subtitle: Text(asset.feeTeaser, style: AppTextStyles.secondary),
            onTap: () => context.read<FundingCubit>().openRails(asset.currency),
          ),
      ],
    );
  }
}

class _Rails extends StatelessWidget {
  const _Rails({required this.state});

  final FundingReady state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.xs,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      children: [
        if (state.feeSchedule != null)
          ListTile(title: Text(state.feeSchedule!, style: AppTextStyles.secondary)),
        for (final rail in state.rails)
          ListTile(
            title: Text(rail.label),
            onTap: () {
              if (rail.id == 'open_usd') {
                context.read<FundingCubit>().openUsdAccount();
              } else {
                context.read<FundingCubit>().openReceiveFiat(rail.asset, rail.id);
              }
            },
          ),
      ],
    );
  }
}

class _OpenUsd extends StatelessWidget {
  const _OpenUsd({required this.state});

  final FundingReady state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      children: [
        Text('Account status: ${state.accountStatus.name}'),
        if (state.usdJob != null) Text('Job: ${state.usdJob!.name}'),
        const SizedBox(height: 16),
        ElevatedButton(
          key: const Key('create_usd_account'),
          onPressed: () async {
            final stepped = await _confirmStepUp(context);
            if (!context.mounted) {
              return;
            }
            await context.read<FundingCubit>().createUsd(
                  requestId: 'usd-account-1',
                  stepUp: stepped,
                );
          },
          child: const Text('Accept terms & open account'),
        ),
      ],
    );
  }
}

class _ReceiveFiat extends StatelessWidget {
  const _ReceiveFiat({required this.state});

  final FundingReady state;

  @override
  Widget build(BuildContext context) {
    final details = state.receiveDetails!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.xs,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      children: [
        ListTile(title: Text('${details.asset.code} ${details.rail}')),
        ListTile(title: Text('Beneficiary ${details.beneficiary}')),
        ListTile(title: Text('Account ${details.ibanOrAccount}')),
        ListTile(title: Text('Reference ${details.reference}')),
        const ListTile(
          title: Text('Showing details is not a credit. Deposit stays in flight.'),
        ),
      ],
    );
  }
}

class _ReceiveAssets extends StatelessWidget {
  const _ReceiveAssets({required this.state});

  final FundingReady state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.xs,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      children: [
        for (final asset in state.receivable)
          ListTile(
            title: Text(asset.currency.code),
            subtitle: Text(asset.network),
            onTap: () =>
                context.read<FundingCubit>().showReceiveAddress(asset.currency),
          ),
      ],
    );
  }
}

class _ReceiveCrypto extends StatelessWidget {
  const _ReceiveCrypto({required this.state});

  final FundingReady state;

  @override
  Widget build(BuildContext context) {
    final address = state.receiveAddress!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.xs,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      children: [
        ListTile(title: Text('${address.currency.code} · ${address.network}')),
        ListTile(title: Text(address.address)),
        const ListTile(title: Text('QR placeholder')),
      ],
    );
  }
}

class _BuyAssets extends StatelessWidget {
  const _BuyAssets({required this.state});

  final FundingReady state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.xs,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      children: [
        const ListTile(title: Text('Prices are stale fixtures')),
        for (final asset in state.purchasable)
          ListTile(
            key: Key('buy_asset_${asset.currency.code}'),
            title: Text(asset.currency.code),
            subtitle: Text('${asset.displayName} · ${asset.freshness.name}'),
            trailing: Text(formatMoney(asset.price)),
            onTap: () => context.read<FundingCubit>().selectBuyAsset(asset),
          ),
      ],
    );
  }
}

class _BuyAmount extends StatelessWidget {
  const _BuyAmount({required this.state});

  final FundingReady state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      children: [
        Text(
          'Buy ${state.selectedBuyAsset?.currency.code}',
          style: AppTextStyles.headline,
        ),
        TextField(
          key: const Key('buy_amount'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Spend USD'),
          onChanged: context.read<FundingCubit>().typeSpend,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final method in state.paymentMethods)
          RadioListTile<String>(
            title: Text(method.label),
            value: method.id,
            groupValue: state.selectedPaymentMethodId,
            onChanged: (id) {
              if (id != null) {
                context.read<FundingCubit>().selectPaymentMethod(id);
              }
            },
          ),
        TextButton(
          onPressed: () => context.read<FundingCubit>().loadPaymentMethods(),
          child: const Text('Load payment methods'),
        ),
        ElevatedButton(
          key: const Key('buy_preview'),
          onPressed: () => context.read<FundingCubit>().previewBuy(),
          child: const Text('Preview'),
        ),
      ],
    );
  }
}

class _BuyPreview extends StatelessWidget {
  const _BuyPreview({required this.state});

  final FundingReady state;

  @override
  Widget build(BuildContext context) {
    final quote = state.quote!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      children: [
        DetailRow(label: 'Spend', value: formatMoney(quote.spend)),
        DetailRow(
          label: 'Receive',
          value: formatMoney(quote.receive, withCode: true),
        ),
        DetailRow(label: 'Freshness', value: quote.freshness.name),
        const SizedBox(height: AppSpacing.xs),
        Text(quote.cashbackTeaser, style: AppTextStyles.secondary),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton(
          key: const Key('buy_confirm'),
          onPressed: () async {
            final stepped = await _confirmStepUp(context);
            if (!context.mounted) {
              return;
            }
            await context.read<FundingCubit>().confirmBuy(
                  requestId: 'buy-1',
                  stepUp: stepped,
                );
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class _BuyResult extends StatelessWidget {
  const _BuyResult({required this.state});

  final FundingReady state;

  @override
  Widget build(BuildContext context) {
    final result = state.buyResult;
    final label = switch (result) {
      StaleQuoteFailure() => 'Quote is stale — buy rejected',
      StepUpFailure() => 'Step-up required',
      EligibilityFailure() => 'Eligibility denied',
      BuySubmit(:final settlement) => 'Settlement ${settlement.name}',
      Failure() => '$result',
      _ => 'Unknown result',
    };
    return Center(
      child: Text(label, key: const Key('buy_result')),
    );
  }
}

Future<bool> _confirmStepUp(BuildContext context) async {
  var pin = '';
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Confirm with PIN'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('•' * pin.length, key: const Key('step_up_dots')),
                PinKeypad(
                  onDigit: (d) {
                    if (pin.length >= 4) {
                      return;
                    }
                    setState(() => pin += d);
                    if (pin.length == 4) {
                      Navigator.of(dialogContext).pop(true);
                    }
                  },
                  onBackspace: () {
                    if (pin.isEmpty) {
                      return;
                    }
                    setState(() => pin = pin.substring(0, pin.length - 1));
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
  return result ?? false;
}
