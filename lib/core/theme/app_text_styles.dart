import 'package:flutter/material.dart';

/// Size and weight only. Color comes from [ThemeData.textTheme] / inherited style.
abstract final class AppTextStyles {
  static const balance = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    height: 1.15,
    letterSpacing: -0.8,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const title = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.4,
  );

  static const headline = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const secondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const meta = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const numeric = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.3,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
