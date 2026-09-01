import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_route.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_failure_view.dart';
import '../../domain/entities/pending_auth.dart';
import '../copy/onboarding_copy.dart';
import '../cubit/onboarding_cubit.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<OnboardingCubit, OnboardingState>(
          builder: (context, state) {
            return switch (state) {
              OnboardingLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
              OnboardingEmpty() => const AppEmptyState(message: 'No slides'),
              OnboardingFailure(:final failure) => AppFailureView(
                  failure: failure,
                  onRetry: context.read<OnboardingCubit>().load,
                ),
              OnboardingSuccess() => _OnboardingBody(state: state),
            };
          },
        ),
      ),
    );
  }
}

class _OnboardingBody extends StatelessWidget {
  const _OnboardingBody({required this.state});

  final OnboardingSuccess state;

  @override
  Widget build(BuildContext context) {
    final slide = state.current;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Language',
              onPressed: () => context.read<OnboardingCubit>().setLocale(
                    state.locale == 'en' ? 'el' : 'en',
                  ),
              icon: Icon(Icons.public, color: scheme.onSurfaceVariant),
            ),
          ),
          const Spacer(flex: 2),
          Text(
            OnboardingCopy.title(slide.titleKey),
            style: AppTextStyles.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            OnboardingCopy.body(slide.bodyKey),
            style: AppTextStyles.secondary.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < state.slides.length; i++)
                Container(
                  width: i == state.index ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: i == state.index
                        ? scheme.onSurface
                        : scheme.outline,
                  ),
                ),
            ],
          ),
          const Spacer(flex: 3),
          if (slide.showAuthActions) ...[
            ElevatedButton(
              onPressed: () => context.push(
                AppRoute.signUp.path,
                extra: AuthIntent.signUp,
              ),
              child: const Text('Sign up'),
            ),
            const SizedBox(height: AppSpacing.xs),
            OutlinedButton(
              onPressed: () => context.push(
                AppRoute.login.path,
                extra: AuthIntent.login,
              ),
              child: const Text('Log in'),
            ),
          ] else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: state.index > 0
                      ? () => context
                          .read<OnboardingCubit>()
                          .pageChanged(state.index - 1)
                      : null,
                  child: const Text('Back'),
                ),
                TextButton(
                  onPressed: state.index < state.slides.length - 1
                      ? () => context
                          .read<OnboardingCubit>()
                          .pageChanged(state.index + 1)
                      : () => context.read<OnboardingCubit>().pageChanged(0),
                  child: const Text('Next'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
