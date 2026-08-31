import 'package:flutter/material.dart';

import '../market/quote_freshness.dart';
import '../theme/app_text_styles.dart';

class FreshnessChip extends StatelessWidget {
  const FreshnessChip({super.key, required this.freshness});

  final QuoteFreshness freshness;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (freshness) {
      QuoteFreshness.live => scheme.tertiary,
      QuoteFreshness.stale => scheme.onSurfaceVariant,
      QuoteFreshness.disconnected => scheme.error,
    };
    return Text(
      freshness.name,
      style: AppTextStyles.meta.copyWith(color: color),
    );
  }
}
