import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_route.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../cubit/sms_cubit.dart';
import '../widgets/code_dots.dart';
import '../widgets/pin_keypad.dart';

class SmsPage extends StatefulWidget {
  const SmsPage({super.key});

  @override
  State<SmsPage> createState() => _SmsPageState();
}

class _SmsPageState extends State<SmsPage> {
  String _code = '';

  void _append(String digit) {
    if (_code.length >= 6) {
      return;
    }
    setState(() => _code += digit);
    if (_code.length == 6) {
      context.read<SmsCubit>().verify(_code);
    }
  }

  void _backspace() {
    if (_code.isEmpty) {
      return;
    }
    setState(() => _code = _code.substring(0, _code.length - 1));
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final digits = (data?.text ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 6) {
      setState(() => _code = digits.substring(0, 6));
      if (!mounted) {
        return;
      }
      context.read<SmsCubit>().verify(_code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify with SMS')),
      body: SafeArea(
        child: BlocConsumer<SmsCubit, SmsState>(
          listener: (context, state) {
            if (state is SmsCodeVerified) {
              context.push(AppRoute.createPin.path);
            }
          },
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                    child: Column(
                      children: [
                        Text(
                          'Enter the 6-digit code',
                          style: AppTextStyles.headline,
                        ),
                        const SizedBox(height: 24),
                        CodeDots(length: 6, filled: _code.length),
                        if (state is SmsFailure) ...[
                          const SizedBox(height: 16),
                          Text(state.failure.toString()),
                        ],
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => context.read<SmsCubit>().resend(),
                          child: const Text('Resend'),
                        ),
                        TextButton(
                          onPressed: _paste,
                          child: const Text('Paste'),
                        ),
                        PinKeypad(onDigit: _append, onBackspace: _backspace),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
