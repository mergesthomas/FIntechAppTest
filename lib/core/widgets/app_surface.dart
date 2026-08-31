import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.selected = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadii.card,
        border: Border.all(
          color: selected ? scheme.primary : scheme.outline,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
