import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class SwapKeypad extends StatelessWidget {
  const SwapKeypad({
    super.key,
    required this.onDigit,
    required this.onDot,
    required this.onBackspace,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDot;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      [',', '0', 'back'],
    ];
    return Column(
      children: [
        for (final row in rows)
          Row(
            children: [
              for (final key in row)
                Expanded(
                  child: _Key(
                    label: key,
                    onDigit: onDigit,
                    onDot: onDot,
                    onBackspace: onBackspace,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.label,
    required this.onDigit,
    required this.onDot,
    required this.onBackspace,
  });

  final String label;
  final ValueChanged<String> onDigit;
  final VoidCallback onDot;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final isBack = label == 'back';
    final isDot = label == ',';
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      key: Key(
        isBack
            ? 'swap_key_backspace'
            : isDot
                ? 'swap_key_dot'
                : 'swap_key_$label',
      ),
      onTap: () {
        if (isBack) {
          onBackspace();
        } else if (isDot) {
          onDot();
        } else {
          onDigit(label);
        }
      },
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: SizedBox(
        height: 48,
        child: Center(
          child: isBack
              ? Icon(Icons.backspace_outlined, color: scheme.onSurface, size: 20)
              : Text(label, style: AppTextStyles.headline),
        ),
      ),
    );
  }
}
