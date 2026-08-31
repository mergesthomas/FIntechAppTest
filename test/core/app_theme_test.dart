import 'package:fintech_app_test/core/theme/app_colors.dart';
import 'package:fintech_app_test/core/theme/app_spacing.dart';
import 'package:fintech_app_test/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light theme uses a near-white canvas and no elevation', () {
    final theme = AppTheme.light();
    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.colorScheme.surface, AppColors.surface);
    expect(theme.colorScheme.primary, AppColors.accent);
    expect(theme.colorScheme.tertiary, AppColors.positive);
    expect(theme.appBarTheme.elevation, 0);
    expect(theme.elevatedButtonTheme.style?.elevation?.resolve({}), 0);
    expect(theme.navigationBarTheme.elevation, 0);
  });

  test('dark theme stays near-black with the same accent', () {
    final theme = AppTheme.dark();
    expect(theme.scaffoldBackgroundColor, AppColors.darkBackground);
    expect(theme.colorScheme.surface, AppColors.darkSurface);
    expect(theme.colorScheme.primary, AppColors.accent);
    expect(theme.colorScheme.onSurface, AppColors.darkTextPrimary);
    expect(theme.appBarTheme.elevation, 0);
  });

  test('spacing and radii follow the 4px scale', () {
    expect(AppSpacing.xxs, 4);
    expect(AppSpacing.xs, 8);
    expect(AppSpacing.md, 16);
    expect(AppSpacing.lg, 24);
    expect(AppSpacing.xl, 32);
    expect(AppSpacing.xxl, 48);
    expect(AppRadii.md, 10);
    expect(AppRadii.lg, 12);
  });

  test('change color uses tertiary for up and error for down', () {
    final scheme = AppTheme.light().colorScheme;
    expect(AppSemanticColors.change(scheme, up: true), scheme.tertiary);
    expect(AppSemanticColors.change(scheme, up: false), scheme.error);
  });
}
