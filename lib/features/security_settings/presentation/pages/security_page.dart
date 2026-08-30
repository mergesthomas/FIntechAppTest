import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_text_styles.dart';
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
          title: const Text('Security & Settings'),
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
              SecurityEmpty() => const Center(child: Text('No security data')),
              SecurityFailure(:final failure) => Center(child: Text('$failure')),
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
    return ListView(
      children: [
        SwitchListTile(
          title: const Text('Biometric'),
          value: snapshot.biometricEnabled,
          onChanged: (value) =>
              context.read<SecurityCubit>().toggleBiometric(value),
        ),
        ListTile(
          title: Text('2FA ${snapshot.twoFactorEnabled ? 'Enabled' : 'Off'}'),
        ),
        ListTile(
          title: Text(
            'Anti-phishing ${snapshot.antiPhishingEnabled ? 'Enabled' : 'Off'}',
          ),
        ),
        SwitchListTile(
          title: const Text('Address book whitelisting'),
          value: snapshot.whitelistingOn,
          onChanged: (value) =>
              context.read<SecurityCubit>().toggleWhitelisting(value),
        ),
        ListTile(title: Text('Last login: ${snapshot.lastLogin}')),
        ListTile(
          title: const Text('Log out'),
          onTap: () async {
            await context.read<SecurityCubit>().logout();
            if (context.mounted) {
              await context.read<SessionCubit>().lock();
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Close account requires step-up — not completed in this emulator tap.',
            style: AppTextStyles.secondary,
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
    return ListView(
      children: [
        ListTile(title: Text('Display currency ${prefs.displayCurrency}')),
        ListTile(title: Text('Language ${prefs.language}')),
        ListTile(title: Text('Appearance ${prefs.appearance}')),
        const ListTile(title: Text('Identity')),
        const ListTile(title: Text('Savings settings')),
        const ListTile(title: Text('Credit Line settings')),
        const ListTile(title: Text('Futures settings')),
        const ListTile(title: Text('Payment methods')),
        const ListTile(title: Text('Notifications')),
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
      children: [
        ListTile(
          title: const Text('Account confirmation'),
          subtitle: Text(
            state.documentJob == null
                ? 'Generate'
                : 'Job ${state.documentJob!.name}',
          ),
          onTap: () => context.read<SecurityCubit>().requestDoc(
                AccountDocumentKind.accountConfirmation,
                'doc-account-confirmation',
              ),
        ),
        const ListTile(
          title: Text('Tax report — Koinly (placeholder link)'),
        ),
      ],
    );
  }
}
