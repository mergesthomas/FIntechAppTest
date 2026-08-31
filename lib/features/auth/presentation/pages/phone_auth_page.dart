import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_route.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/pending_auth.dart';
import '../cubit/phone_auth_cubit.dart';

class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({super.key, required this.intent});

  final AuthIntent intent;

  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.intent == AuthIntent.login ? 'Log in' : 'Sign up';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: BlocConsumer<PhoneAuthCubit, PhoneAuthState>(
            listener: (context, state) {
              if (state is PhoneAuthSuccess) {
                context.push(AppRoute.verifySms.path);
              }
            },
            builder: (context, state) {
              final error = state is PhoneAuthFailure
                  ? state.failure.toString()
                  : null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Enter your mobile number',
                    style: AppTextStyles.headline,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Local emulator. SMS code is 123456.',
                    style: AppTextStyles.secondary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    key: const Key('phone_field'),
                    controller: _controller,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      hintText: '6912345678',
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error, style: AppTextStyles.secondary),
                  ],
                  const Spacer(),
                  ElevatedButton(
                    key: const Key('phone_continue'),
                    onPressed: state is PhoneAuthLoading
                        ? null
                        : () => context.read<PhoneAuthCubit>().submit(
                              phone: _controller.text,
                              intent: widget.intent,
                            ),
                    child: state is PhoneAuthLoading
                        ? const CircularProgressIndicator()
                        : const Text('Continue'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
