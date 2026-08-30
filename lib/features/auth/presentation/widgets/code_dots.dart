import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < length; i++)
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled ? AppColors.accent : AppColors.surfaceMuted,
            ),
          ),
      ],
    );
  }
}
