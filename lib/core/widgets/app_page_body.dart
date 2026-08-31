import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class AppPageBody extends StatelessWidget {
  const AppPageBody({
    super.key,
    required this.child,
    this.padding = AppSpacing.page,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, AppSpacing.maxContentWidth);
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            height: constraints.hasBoundedHeight ? constraints.maxHeight : null,
            child: Padding(padding: padding, child: child),
          ),
        );
      },
    );
  }
}
