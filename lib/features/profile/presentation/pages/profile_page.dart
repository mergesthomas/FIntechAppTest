import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_route.dart';
import '../../../../core/theme/app_text_styles.dart';
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
            ProfileEmpty() => const Center(child: Text('No profile shortcuts')),
            ProfileFailure(:final failure) => Center(child: Text('$failure')),
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(state.overview.greeting, style: AppTextStyles.title),
        Text(
          'Loyalty ${state.overview.loyaltyTier}',
          style: AppTextStyles.secondary,
        ),
        if (state.overview.isPrivate)
          const ListTile(title: Text('Nexo Private')),
        const SizedBox(height: 12),
        for (final reward in state.rewards)
          ListTile(title: Text(reward)),
        const SizedBox(height: 8),
        for (final item in state.shortcuts)
          ListTile(
            title: Text(item.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(context, item.id),
          ),
        Text('Version ${state.version}', style: AppTextStyles.secondary),
        Text(
          'Terms / About — placeholder links',
          style: AppTextStyles.secondary,
        ),
      ],
    );
  }

  void _open(BuildContext context, String id) {
    final route = switch (id) {
      'security' => AppRoute.security,
      'products' => AppRoute.products,
      'credit' => AppRoute.borrow,
      'savings' => AppRoute.earn,
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
        route == AppRoute.borrow ||
        route == AppRoute.funding) {
      context.push(route.path);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${route.path} — next feature')),
    );
  }
}
