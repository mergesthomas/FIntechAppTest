import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'back'],
    ];
    return Column(
      children: [
        for (final row in keys)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final key in row)
                _Key(
                  label: key,
                  onDigit: onDigit,
                  onBackspace: onBackspace,
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
    required this.onBackspace,
  });

  final String label;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) {
      return const SizedBox(width: 72, height: 64);
    }
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: InkWell(
        onTap: () {
          if (label == 'back') {
            onBackspace();
          } else {
            onDigit(label);
          }
        },
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 72,
          height: 64,
          child: Center(
            child: label == 'back'
                ? Icon(Icons.backspace_outlined, color: scheme.onSurface)
                : Text(label, style: AppTextStyles.headline),
          ),
        ),
      ),
    );
  }
}
