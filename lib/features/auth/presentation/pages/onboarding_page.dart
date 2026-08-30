import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_route.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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
              OnboardingEmpty() => const Center(child: Text('No slides')),
              OnboardingFailure(:final failure) => Center(
                  child: Text(failure.toString()),
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Language',
              onPressed: () => context.read<OnboardingCubit>().setLocale(
                    state.locale == 'en' ? 'el' : 'en',
                  ),
              icon: const Icon(Icons.public, color: AppColors.textPrimary),
            ),
          ),
          const Spacer(),
          Text(
            OnboardingCopy.title(slide.titleKey),
            style: AppTextStyles.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            OnboardingCopy.body(slide.bodyKey),
            style: AppTextStyles.secondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < state.slides.length; i++)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == state.index
                        ? AppColors.accent
                        : AppColors.surfaceMuted,
                  ),
                ),
            ],
          ),
          const Spacer(),
          if (slide.showAuthActions) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push(
                      AppRoute.login.path,
                      extra: AuthIntent.login,
                    ),
                    child: const Text('Log in'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push(
                      AppRoute.signUp.path,
                      extra: AuthIntent.signUp,
                    ),
                    child: const Text('Sign up'),
                  ),
                ),
              ],
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
                      : () => context
                          .read<OnboardingCubit>()
                          .pageChanged(0),
                  child: const Text('Next'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
