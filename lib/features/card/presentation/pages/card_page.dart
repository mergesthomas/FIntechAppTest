import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/money/money_format.dart';
import '../../../../core/notice/user_notice.dart';
import '../../../../core/notice/user_notice_cubit.dart';
import '../../../../core/router/app_route.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_failure_view.dart';
import '../../../../core/widgets/app_header_action.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../auth/presentation/widgets/step_up_pin_dialog.dart';
import '../../domain/entities/card.dart';
import '../cubit/card_cubit.dart';

class CardPage extends StatefulWidget {
  const CardPage({super.key});

  @override
  State<CardPage> createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CardCubit>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AppHeaderAction(
            tooltip: 'Profile',
            onPressed: () => context.push(AppRoute.profile.path),
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: scheme.surfaceContainerHighest,
              foregroundColor: scheme.onSurface,
              child: Text(
                _initials(context),
                style: AppTextStyles.meta.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        title: const Text('Card'),
        actionsPadding: const EdgeInsets.only(right: 8),
        actions: [
          AppHeaderAction(
            key: const Key('card_inbox'),
            tooltip: 'Inbox',
            onPressed: () => context.push(AppRoute.inbox.path),
            icon: Icon(Icons.notifications_none, color: scheme.onSurface),
          ),
        ],
      ),
      body: BlocBuilder<CardCubit, CardUiState>(
        builder: (context, state) {
          return switch (state) {
            CardLoading() => const Center(child: CircularProgressIndicator()),
            CardEmpty() => const AppEmptyState(message: 'No card'),
            CardFailure(:final failure) => AppFailureView(
                failure: failure,
                key: const Key('card_failure'),
                onRetry: context.read<CardCubit>().load,
              ),
            CardSuccess(:final snapshot) => _Body(snapshot: snapshot),
          };
        },
      ),
    );
  }

  String _initials(BuildContext context) {
    final session = context.read<SessionCubit>().state;
    if (session is! SessionSuccess) {
      return 'NA';
    }
    final digits = session.session.phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 2) {
      return digits.substring(digits.length - 2);
    }
    return 'NA';
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.snapshot});

  final CardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final frozen = snapshot.status == CardStatus.frozen;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.md,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      children: [
        _CardVisual(snapshot: snapshot),
        const SizedBox(height: AppSpacing.sm),
        if (snapshot.applePayAdded)
          Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: scheme.tertiary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Added to Apple Pay',
                style: AppTextStyles.meta.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.lg),
        if (snapshot.cashbackEarned != null) ...[
          Text(
            'Cashback earned',
            style: AppTextStyles.meta.copyWith(color: scheme.onSurfaceVariant),
          ),
          Text(
            formatMoney(snapshot.cashbackEarned!),
            style: AppTextStyles.headline.copyWith(color: scheme.tertiary),
          ),
          Text(
            '[placeholder — compliance review]',
            style: AppTextStyles.meta.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(
          frozen ? 'Card frozen' : 'Card ${snapshot.status.name}',
          key: const Key('card_status'),
          style: AppTextStyles.secondary.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          formatMoney(snapshot.balances.eurx, withCode: true),
          style: AppTextStyles.balance,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '≈ ${formatMoney(snapshot.balances.usdApprox)}',
          style: AppTextStyles.secondary.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        if (frozen) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Swap to restore. Frozen is a first-class state.',
            style: AppTextStyles.secondary.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            key: const Key('restore_swap'),
            onPressed: () => _restore(context, RestoreRail.swap),
            child: const Text('Restore balance'),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _Option(
          icon: Icons.credit_card_outlined,
          title: 'Card details',
          subtitle: '${snapshot.network} *${snapshot.last4}',
          onTap: () => context.showUserNotice(UserNotice.info('Card details — last4 only')),
        ),
        _Option(
          icon: Icons.swap_horiz,
          title: 'Card mode',
          trailing: snapshot.modeLabel,
          onTap: () => context.showUserNotice(UserNotice.info('Debit only. Credit / borrow is out of scope.')),
        ),
        _Option(
          icon: frozen ? Icons.lock_open_outlined : Icons.ac_unit,
          title: frozen ? 'Unfreeze' : 'Freeze card',
          keyName: frozen ? 'unfreeze_card' : 'freeze_card',
          onTap: () async {
            final cubit = context.read<CardCubit>();
            final failure = frozen ? await cubit.unfreeze() : await cubit.freeze();
            if (failure != null && context.mounted) {
              context.showFailureNotice(failure);
            }
          },
        ),
        _Option(
          icon: Icons.visibility_outlined,
          title: 'Reveal PIN',
          onTap: () => _revealPin(context),
        ),
        _Option(
          icon: Icons.receipt_long_outlined,
          title: 'Transactions',
          onTap: () => context.showUserNotice(UserNotice.info('Transactions — screens missing')),
        ),
        _Option(
          icon: Icons.settings_outlined,
          title: 'Card settings',
          onTap: () => context.showUserNotice(UserNotice.info('Card settings — screens missing')),
        ),
      ],
    );
  }

  Future<void> _restore(BuildContext context, RestoreRail rail) async {
    final result = await context.read<CardCubit>().restore(rail);
    if (!context.mounted) {
      return;
    }
    result.fold((failure) {
      context.showFailureNotice(failure);
    }, (chosen) {
      final route = switch (chosen) {
        RestoreRail.swap => AppRoute.swap,
      };
      context.push(route.path);
    });
  }

  Future<void> _revealPin(BuildContext context) async {
    final stepped = await confirmStepUpPin(context);
    if (!context.mounted) {
      return;
    }
    final result = await context.read<CardCubit>().revealPin(stepUp: stepped);
    if (!context.mounted) {
      return;
    }
    result.fold(
      (failure) => context.showFailureNotice(failure),
      (pin) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Card PIN'),
          content: Text(pin, key: const Key('card_pin_value')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

}

class _CardVisual extends StatelessWidget {
  const _CardVisual({required this.snapshot});

  final CardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1.58,
      child: AppSurface(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('VIRTUAL', style: AppTextStyles.meta),
                const Spacer(),
                Text(snapshot.modeLabel.toUpperCase(), style: AppTextStyles.meta),
              ],
            ),
            const Spacer(),
            Text(
              '•••• ${snapshot.last4}',
              style: AppTextStyles.headline.copyWith(
                color: scheme.onSurface,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(snapshot.network, style: AppTextStyles.secondary),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.keyName,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;
  final String? trailing;
  final String? keyName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      key: keyName == null ? null : Key(keyName!),
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: scheme.onSurface),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing!,
              style: AppTextStyles.meta.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
      onTap: onTap,
    );
  }
}
