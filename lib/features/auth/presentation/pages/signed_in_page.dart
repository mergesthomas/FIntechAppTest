import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../cubit/session_cubit.dart';

class SignedInPage extends StatelessWidget {
  const SignedInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('You are signed in.', style: AppTextStyles.headline),
              const SizedBox(height: 8),
              Text(
                'Dashboard is the next feature. Session is local-only.',
                style: AppTextStyles.secondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                key: const Key('lock_session'),
                onPressed: () => context.read<SessionCubit>().lock(),
                child: const Text('Lock session'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
