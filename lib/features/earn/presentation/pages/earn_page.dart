import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/money/money_format.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/step_up_pin_dialog.dart';
import '../cubit/earn_cubit.dart';

class EarnPage extends StatefulWidget {
  const EarnPage({super.key});

  @override
  State<EarnPage> createState() => _EarnPageState();
}

class _EarnPageState extends State<EarnPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<EarnCubit>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Savings Hub')),
      body: BlocBuilder<EarnCubit, EarnState>(
        builder: (context, state) {
          return switch (state) {
            EarnLoading() => const Center(child: CircularProgressIndicator()),
            EarnEmpty() => const Center(child: Text('No earn products')),
            EarnFailure(:final failure) => Center(child: Text('$failure')),
            EarnSuccess() => ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    formatMoney(state.overview.interestEarned),
                    style: AppTextStyles.title,
                  ),
                  Text('Interest earned', style: AppTextStyles.secondary),
                  const SizedBox(height: 16),
                  for (final product in state.products)
                    ListTile(
                      title: Text(product.label),
                      subtitle: Text(product.teaser),
                    ),
                  SwitchListTile(
                    key: const Key('earn_in_nexo'),
                    title: const Text('Earn in NEXO'),
                    subtitle: const Text('+2% placeholder'),
                    value: state.preference.earnInNexo,
                    onChanged: (value) async {
                      final stepped = await confirmStepUpPin(context);
                      if (!context.mounted) {
                        return;
                      }
                      await context.read<EarnCubit>().toggleEarnInNexo(
                            enabled: value,
                            requestId: 'earn-nexo-1',
                            stepUp: stepped,
                          );
                    },
                  ),
                  ElevatedButton(
                    key: const Key('stop_earning'),
                    onPressed: () async {
                      final stepped = await confirmStepUpPin(context);
                      if (!context.mounted) {
                        return;
                      }
                      await context.read<EarnCubit>().stop(
                            requestId: 'stop-earn-1',
                            stepUp: stepped,
                          );
                    },
                    child: const Text('Stop earning'),
                  ),
                ],
              ),
          };
        },
      ),
    );
  }
}
