import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/notice/user_notice_cubit.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_failure_view.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../domain/entities/security_settings.dart';
import '../cubit/security_cubit.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SecurityCubit>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Security'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Security'),
              Tab(text: 'Settings'),
              Tab(text: 'Documents'),
            ],
          ),
        ),
        body: BlocBuilder<SecurityCubit, SecurityState>(
          builder: (context, state) {
            return switch (state) {
              SecurityLoading() =>
                const Center(child: CircularProgressIndicator()),
              SecurityEmpty() => const AppEmptyState(message: 'No security data'),
              SecurityFailure(:final failure) => AppFailureView(
                failure: failure,
                onRetry: context.read<SecurityCubit>().load,
              ),
              SecuritySuccess() => TabBarView(
                  children: [
                    _SecurityTab(state: state),
                    _SettingsTab(state: state),
                    _DocumentsTab(state: state),
                  ],
                ),
            };
          },
        ),
      ),
    );
  }
}

class _SecurityTab extends StatelessWidget {
  const _SecurityTab({required this.state});

  final SecuritySuccess state;

  @override
  Widget build(BuildContext context) {
    final snapshot = state.snapshot;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.xs,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      children: [
        const AppSectionHeader('Protection'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Biometric'),
          value: snapshot.biometricEnabled,
          onChanged: (value) async {
            final failure = await context.read<SecurityCubit>().toggleBiometric(
              value,
            );
            if (failure != null && context.mounted) {
              context.showFailureNotice(failure);
            }
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Two-factor authentication'),
          trailing: Text(
            snapshot.twoFactorEnabled ? 'On' : 'Off',
            style: AppTextStyles.secondary.copyWith(color: muted),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Anti-phishing'),
          trailing: Text(
            snapshot.antiPhishingEnabled ? 'On' : 'Off',
            style: AppTextStyles.secondary.copyWith(color: muted),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Address book whitelisting'),
          value: snapshot.whitelistingOn,
          onChanged: (value) async {
            final failure =
                await context.read<SecurityCubit>().toggleWhitelisting(value);
            if (failure != null && context.mounted) {
              context.showFailureNotice(failure);
            }
          },
        ),
        const AppSectionHeader('Session'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Last login'),
          trailing: Text(
            snapshot.lastLogin,
            style: AppTextStyles.secondary.copyWith(color: muted),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Log out'),
          onTap: () async {
            await context.read<SecurityCubit>().logout();
            if (context.mounted) {
              await context.read<SessionCubit>().lock();
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Text(
            'Close account requires step-up — not completed in this emulator tap.',
            style: AppTextStyles.meta.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.state});

  final SecuritySuccess state;

  @override
  Widget build(BuildContext context) {
    final prefs = state.preferences;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.xs,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      children: [
        const AppSectionHeader('Preferences'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Display currency'),
          trailing: Text(
            prefs.displayCurrency,
            style: AppTextStyles.secondary.copyWith(color: muted),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Language'),
          trailing: Text(
            prefs.language,
            style: AppTextStyles.secondary.copyWith(color: muted),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Appearance'),
          trailing: Text(
            prefs.appearance,
            style: AppTextStyles.secondary.copyWith(color: muted),
          ),
        ),
        const AppSectionHeader('Products'),
        const ListTile(contentPadding: EdgeInsets.zero, title: Text('Identity')),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Payment methods'),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Notifications'),
        ),
      ],
    );
  }
}

class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab({required this.state});

  final SecuritySuccess state;

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
        const AppSectionHeader('Documents'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Account confirmation'),
          subtitle: Text(
            state.documentJob == null
                ? 'Generate'
                : 'Job ${state.documentJob!.name}',
          ),
          onTap: () async {
            final failure = await context.read<SecurityCubit>().requestDoc(
                  AccountDocumentKind.accountConfirmation,
                  'doc-account-confirmation',
                );
            if (failure != null && context.mounted) {
              context.showFailureNotice(failure);
            }
          },
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Tax report — Koinly (placeholder link)'),
        ),
      ],
    );
  }
}
