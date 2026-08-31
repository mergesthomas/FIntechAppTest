import 'package:flutter/material.dart';

import '../market/quote_freshness.dart';
import '../theme/app_text_styles.dart';

class FreshnessChip extends StatelessWidget {
  const FreshnessChip({super.key, required this.freshness});

  final QuoteFreshness freshness;

  @override
  Widget build(BuildContext context) {
    final label = freshness.statusLabel;
    if (label == null) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final color = switch (freshness) {
      QuoteFreshness.live => scheme.tertiary,
      QuoteFreshness.stale => scheme.onSurfaceVariant,
      QuoteFreshness.disconnected => scheme.error,
    };
    return Text(
      label,
      style: AppTextStyles.meta.copyWith(color: color),
    );
  }
}
