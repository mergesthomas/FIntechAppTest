import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money_format.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/step_up_pin_dialog.dart';
import '../../domain/entities/borrow.dart';
import '../cubit/borrow_cubit.dart';

class BorrowPage extends StatefulWidget {
  const BorrowPage({super.key});

  @override
  State<BorrowPage> createState() => _BorrowPageState();
}

class _BorrowPageState extends State<BorrowPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BorrowCubit>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Hub'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final state = context.read<BorrowCubit>().state;
            if (state is BorrowReady && state.surface != BorrowSurface.loans) {
              context.read<BorrowCubit>().backToLoans();
              return;
            }
            Navigator.of(context).maybePop();
          },
        ),
      ),
      body: BlocBuilder<BorrowCubit, BorrowState>(
        builder: (context, state) {
          return switch (state) {
            BorrowLoading() => const Center(child: CircularProgressIndicator()),
            BorrowEmpty() => const Center(child: Text('No loan products')),
            BorrowFailure(:final failure) => Center(child: Text('$failure')),
            BorrowReady() => switch (state.surface) {
                BorrowSurface.loans => _Loans(state: state),
                BorrowSurface.collateral => _Collateral(state: state),
                BorrowSurface.optimization => _Optimization(state: state),
                BorrowSurface.preview => _Preview(state: state),
                BorrowSurface.repay => _Repay(state: state),
                BorrowSurface.result => _Result(state: state),
              },
          };
        },
      ),
    );
  }
}

class _Loans extends StatelessWidget {
  const _Loans({required this.state});

  final BorrowReady state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: Text('Available ${formatMoney(state.overview.available, withCode: true)}'),
          subtitle: Text(
            'Outstanding ${formatMoney(state.overview.outstanding, withCode: true)}',
          ),
        ),
        ListTile(
          title: const Text('Collateral'),
          onTap: () => context.read<BorrowCubit>().openCollateral(),
        ),
        ListTile(
          title: const Text('Credit line settings'),
          onTap: () => context.read<BorrowCubit>().openOptimization(),
        ),
        ListTile(
          title: const Text('Repay'),
          onTap: () => context.read<BorrowCubit>().openRepay(),
        ),
        for (final product in state.products)
          ListTile(
            key: Key('loan_${product.id}'),
            title: Text(product.label),
            subtitle: Text('${product.status} · ${formatMoney(product.outstanding, withCode: true)}'),
            onTap: () => context.read<BorrowCubit>().previewBorrow(product.id),
          ),
      ],
    );
  }
}

class _Collateral extends StatelessWidget {
  const _Collateral({required this.state});

  final BorrowReady state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final asset in state.collateral)
          ListTile(
            title: Text(asset.currency.code),
            subtitle: Text(asset.ltvTeaser, style: AppTextStyles.secondary),
          ),
      ],
    );
  }
}

class _Optimization extends StatelessWidget {
  const _Optimization({required this.state});

  final BorrowReady state;

  @override
  Widget build(BuildContext context) {
    final flags = state.optimization!;
    return ListView(
      children: [
        SwitchListTile(
          title: const Text('Automatic collateral transfer'),
          value: flags.automaticCollateralTransfer,
          onChanged: (value) => _save(
            context,
            flags.copyWith(
              automaticCollateralTransfer: value,
              fixedTermUnlock: value ? flags.fixedTermUnlock : false,
              lowInterestBorrowing: value ? flags.lowInterestBorrowing : false,
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('Fixed-term unlock'),
          value: flags.fixedTermUnlock,
          onChanged: flags.automaticCollateralTransfer
              ? (value) => _save(context, flags.copyWith(fixedTermUnlock: value))
              : null,
        ),
        SwitchListTile(
          title: const Text('Low-interest borrowing'),
          value: flags.lowInterestBorrowing,
          onChanged: flags.automaticCollateralTransfer
              ? (value) =>
                  _save(context, flags.copyWith(lowInterestBorrowing: value))
              : null,
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context, CreditLineOptimization flags) async {
    final stepped = await confirmStepUpPin(context);
    if (!context.mounted) {
      return;
    }
    await context.read<BorrowCubit>().saveOptimization(
          flags: flags,
          requestId: 'opt-1',
          stepUp: stepped,
        );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.state});

  final BorrowReady state;

  @override
  Widget build(BuildContext context) {
    final quote = state.quote!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Borrow ${formatMoney(quote.amount, withCode: true)}'),
        Text(quote.ltvTeaser, style: AppTextStyles.secondary),
        Text('Freshness ${quote.freshness.name}'),
        ElevatedButton(
          key: const Key('borrow_confirm'),
          onPressed: () async {
            final stepped = await confirmStepUpPin(context);
            if (!context.mounted) {
              return;
            }
            await context.read<BorrowCubit>().confirmBorrow(
                  requestId: 'borrow-1',
                  stepUp: stepped,
                );
          },
          child: const Text('Confirm borrow'),
        ),
      ],
    );
  }
}

class _Repay extends StatelessWidget {
  const _Repay({required this.state});

  final BorrowReady state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          key: const Key('repay_amount'),
          decoration: const InputDecoration(labelText: 'Repay xUSD'),
          onChanged: context.read<BorrowCubit>().typeRepay,
        ),
        ElevatedButton(
          key: const Key('repay_confirm'),
          onPressed: () async {
            final stepped = await confirmStepUpPin(context);
            if (!context.mounted) {
              return;
            }
            await context.read<BorrowCubit>().confirmRepay(
                  requestId: 'repay-1',
                  stepUp: stepped,
                );
          },
          child: const Text('Confirm repay'),
        ),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.state});

  final BorrowReady state;

  @override
  Widget build(BuildContext context) {
    final result = state.result;
    final label = switch (result) {
      StaleQuoteFailure() => 'Quote is stale — borrow rejected',
      StepUpFailure() => 'Step-up required',
      ValidationFailure(:final reason) => reason,
      BorrowSubmit(:final settlement) => 'Settlement ${settlement.name}',
      SettlementStatus() => 'Settlement ${result.name}',
      Failure() => '$result',
      _ => 'Unknown result',
    };
    return Center(child: Text(label, key: const Key('borrow_result')));
  }
}
