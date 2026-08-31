import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_route.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../cubit/profile_cubit.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProfileCubit>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          return switch (state) {
            ProfileLoading() => const Center(child: CircularProgressIndicator()),
            ProfileEmpty() => const AppEmptyState(message: 'No profile shortcuts'),
            ProfileFailure(:final failure) => AppEmptyState(message: '$failure'),
            ProfileSuccess() => _ProfileBody(state: state),
          };
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.state});

  final ProfileSuccess state;

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
        Text(state.overview.greeting, style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Loyalty ${state.overview.loyaltyTier}',
          style: AppTextStyles.secondary.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        if (state.overview.isPrivate)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs),
            child: Text('Nexo Private'),
          ),
        if (state.rewards.isNotEmpty) ...[
          const AppSectionHeader('Rewards'),
          for (final reward in state.rewards)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(reward),
            ),
        ],
        const AppSectionHeader('Account'),
        for (final item in state.shortcuts)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item.label),
            trailing: Icon(
              Icons.chevron_right,
              color: scheme.onSurfaceVariant,
            ),
            onTap: () => _open(context, item.id),
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Lock session'),
          onTap: () => context.read<SessionCubit>().lock(),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Version ${state.version}',
          style: AppTextStyles.meta.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Terms / About — placeholder links',
          style: AppTextStyles.meta.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  void _open(BuildContext context, String id) {
    final route = switch (id) {
      'security' => AppRoute.security,
      'products' => AppRoute.products,
      'futures' => AppRoute.futures,
      'card' => AppRoute.card,
      _ => null,
    };
    if (route == null) {
      return;
    }
    if (route == AppRoute.security ||
        route == AppRoute.products ||
        route == AppRoute.explore ||
        route == AppRoute.news ||
        route == AppRoute.funding ||
        route == AppRoute.card ||
        route == AppRoute.swap ||
        route == AppRoute.futures) {
      context.push(route.path);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${route.path} — next feature')),
    );
  }
}
