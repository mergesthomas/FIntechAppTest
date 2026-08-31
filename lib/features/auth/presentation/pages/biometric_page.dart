import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../cubit/biometric_cubit.dart';
import '../cubit/session_cubit.dart';

class BiometricPage extends StatelessWidget {
  const BiometricPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enable Face ID')),
      body: SafeArea(
        child: BlocConsumer<BiometricCubit, BiometricState>(
          listener: (context, state) {
            if (state is BiometricSuccess) {
              context.read<SessionCubit>().signedIn(state.session);
            }
          },
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  const Spacer(),
                  Icon(
                    Icons.face_outlined,
                    size: 56,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Use Face ID to unlock', style: AppTextStyles.headline),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Local emulator — Enable stores a flag only.',
                    style: AppTextStyles.secondary,
                    textAlign: TextAlign.center,
                  ),
                  if (state is BiometricFailure) ...[
                    const SizedBox(height: 16),
                    Text(state.failure.toString()),
                  ],
                  const Spacer(),
                  ElevatedButton(
                    key: const Key('enable_biometric'),
                    onPressed: state is BiometricLoading
                        ? null
                        : () => context.read<BiometricCubit>().enable(),
                    child: const Text('Enable'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    key: const Key('skip_biometric'),
                    onPressed: state is BiometricLoading
                        ? null
                        : () => context.read<BiometricCubit>().skip(),
                    child: const Text('Skip'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
