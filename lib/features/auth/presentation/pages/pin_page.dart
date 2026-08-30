import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_route.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../cubit/pin_cubit.dart';
import '../widgets/code_dots.dart';
import '../widgets/pin_keypad.dart';

class PinPage extends StatefulWidget {
  const PinPage({super.key, required this.confirm});

  final bool confirm;

  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  String _pin = '';

  void _append(String digit) {
    if (_pin.length >= 4) {
      return;
    }
    setState(() => _pin += digit);
    if (_pin.length == 4) {
      final cubit = context.read<PinCubit>();
      if (widget.confirm) {
        cubit.confirm(_pin);
      } else {
        cubit.create(_pin);
      }
    }
  }

  void _backspace() {
    if (_pin.isEmpty) {
      return;
    }
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.confirm ? 'Confirm PIN' : 'Create PIN';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: BlocConsumer<PinCubit, PinState>(
          listener: (context, state) {
            if (!widget.confirm && state is PinCreated) {
              context.push(AppRoute.confirmPin.path);
            }
            if (widget.confirm && state is PinConfirmed) {
              context.push(AppRoute.enableBiometric.path);
            }
            if (state is PinFailure) {
              setState(() => _pin = '');
            }
          },
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                    child: Column(
                      children: [
                        Text(
                          widget.confirm
                              ? 'Re-enter your 4-digit PIN'
                              : 'Choose a 4-digit PIN',
                          style: AppTextStyles.headline,
                        ),
                        const SizedBox(height: 24),
                        CodeDots(length: 4, filled: _pin.length),
                        if (state is PinFailure) ...[
                          const SizedBox(height: 16),
                          Text(state.failure.toString()),
                        ],
                        const SizedBox(height: 16),
                        if (widget.confirm)
                          TextButton(
                            onPressed: () async {
                              await context.read<PinCubit>().reset();
                              if (context.mounted) {
                                context.go(AppRoute.createPin.path);
                              }
                            },
                            child: const Text('Reset'),
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
