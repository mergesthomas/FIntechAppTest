import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../market/quote_freshness.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'market_connection_cubit.dart';
import 'notice_copy.dart';
import 'user_notice.dart';
import 'user_notice_cubit.dart';

class AppNoticeHost extends StatelessWidget {
  const AppNoticeHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserNoticeCubit, UserNoticeState>(
      listenWhen: (previous, current) {
        return current is UserNoticeQueued &&
            (previous is! UserNoticeQueued ||
                previous.sequence != current.sequence);
      },
      listener: (context, state) {
        if (state is! UserNoticeQueued) {
          return;
        }
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger == null) {
          return;
        }
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(_snackBar(context, state.notice));
      },
      child: BlocBuilder<MarketConnectionCubit, QuoteFreshness>(
        buildWhen: (previous, current) =>
            (previous == QuoteFreshness.disconnected) !=
            (current == QuoteFreshness.disconnected),
        builder: (context, freshness) {
          final offline = freshness == QuoteFreshness.disconnected;
          return Column(
            children: [
              if (offline) const _FeedOfflineBanner(),
              Expanded(child: child),
            ],
          );
        },
      ),
    );
  }

  SnackBar _snackBar(BuildContext context, UserNotice notice) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (notice.kind) {
      UserNoticeKind.error => (scheme.error, scheme.onError),
      UserNoticeKind.success => (scheme.tertiary, scheme.onTertiary),
      UserNoticeKind.warning => (AppColors.warning, Colors.white),
      UserNoticeKind.info => (scheme.onSurface, scheme.surface),
    };
    return SnackBar(
      key: const Key('user_notice_snackbar'),
      duration: const Duration(seconds: 4),
      backgroundColor: background,
      content: Text(
        notice.message,
        key: const Key('user_notice_message'),
        style: AppTextStyles.secondary.copyWith(color: foreground),
      ),
    );
  }
}

class _FeedOfflineBanner extends StatelessWidget {
  const _FeedOfflineBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final top = MediaQuery.paddingOf(context).top;
    return Material(
      color: scheme.error,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          top + AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Text(
          NoticeCopy.feedDisconnected,
          key: const Key('feed_offline_banner'),
          style: AppTextStyles.meta.copyWith(color: scheme.onError),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
