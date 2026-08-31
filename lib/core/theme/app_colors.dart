import 'package:flutter/material.dart';

/// Semantic color tokens. Light is the product default; dark mirrors the same
/// restraint (near-black canvas, soft surfaces, one accent).
abstract final class AppColors {
  static const background = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF1F3F5);
  static const border = Color(0xFFE6E8EB);
  static const accent = Color(0xFF44D7B6);
  static const onAccent = Color(0xFF111111);
  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF6B7280);
  static const positive = Color(0xFF0F766E);
  static const danger = Color(0xFFC2413B);
  static const warning = Color(0xFFB45309);

  static const darkBackground = Color(0xFF0B0B0C);
  static const darkSurface = Color(0xFF161618);
  static const darkSurfaceMuted = Color(0xFF1F1F22);
  static const darkBorder = Color(0xFF2A2A2E);
  static const darkTextPrimary = Color(0xFFF4F4F5);
  static const darkTextSecondary = Color(0xFF9CA3AF);
  static const darkPositive = Color(0xFF5EEAD4);
}

abstract final class AppSemanticColors {
  static Color change(ColorScheme scheme, {required bool up}) {
    return up ? scheme.tertiary : scheme.error;
  }
}
