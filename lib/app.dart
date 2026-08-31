import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/di/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class FintechApp extends ConsumerStatefulWidget {
  const FintechApp({super.key});

  @override
  ConsumerState<FintechApp> createState() => _FintechAppState();
}

class _FintechAppState extends ConsumerState<FintechApp> {
  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    final sessionCubit = ref.watch(sessionCubitProvider);
    _router ??= createRouter(sessionCubit);
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sessionCubit),
        BlocProvider.value(value: ref.watch(onboardingCubitProvider)),
        BlocProvider.value(value: ref.watch(phoneAuthCubitProvider)),
        BlocProvider.value(value: ref.watch(smsCubitProvider)),
        BlocProvider.value(value: ref.watch(pinCubitProvider)),
        BlocProvider.value(value: ref.watch(biometricCubitProvider)),
        BlocProvider.value(value: ref.watch(homeCubitProvider)),
        BlocProvider.value(value: ref.watch(profileCubitProvider)),
        BlocProvider.value(value: ref.watch(productsCubitProvider)),
        BlocProvider.value(value: ref.watch(securityCubitProvider)),
        BlocProvider.value(value: ref.watch(inboxCubitProvider)),
        BlocProvider.value(value: ref.watch(newsCubitProvider)),
        BlocProvider.value(value: ref.watch(exploreCubitProvider)),
        BlocProvider.value(value: ref.watch(fundingCubitProvider)),
        BlocProvider.value(value: ref.watch(cardCubitProvider)),
        BlocProvider.value(value: ref.watch(swapCubitProvider)),
        BlocProvider.value(value: ref.watch(ordersCubitProvider)),
      ],
      child: MaterialApp.router(
        title: 'Wallet',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        routerConfig: _router,
      ),
    );
  }
}
