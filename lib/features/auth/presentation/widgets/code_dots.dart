import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

class CodeDots extends StatelessWidget {
  const CodeDots({
    super.key,
    required this.length,
    required this.filled,
  });

  final int length;
  final int filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < length; i++)
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled ? scheme.onSurface : Colors.transparent,
              border: Border.all(
                color: i < filled ? scheme.onSurface : scheme.outline,
              ),
            ),
          ),
      ],
    );
  }
}
