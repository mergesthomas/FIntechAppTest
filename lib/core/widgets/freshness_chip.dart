import 'package:flutter/material.dart';

import '../market/quote_freshness.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class FreshnessChip extends StatelessWidget {
  const FreshnessChip({super.key, required this.freshness});

  final QuoteFreshness freshness;

  @override
  Widget build(BuildContext context) {
    final color = switch (freshness) {
      QuoteFreshness.live => AppColors.accent,
      QuoteFreshness.stale => AppColors.textSecondary,
      QuoteFreshness.disconnected => AppColors.danger,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        freshness.name,
        style: AppTextStyles.secondary.copyWith(color: color, fontSize: 12),
      ),
    );
  }
}
