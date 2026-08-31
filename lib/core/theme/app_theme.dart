import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      tertiary: AppColors.positive,
      onTertiary: Color(0xFFFFFFFF),
      error: AppColors.danger,
      onError: Color(0xFFFFFFFF),
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      surfaceContainerHighest: AppColors.surfaceMuted,
      surfaceContainerHigh: AppColors.surfaceMuted,
      surfaceContainer: AppColors.surface,
      surfaceContainerLow: AppColors.background,
    );
    return _base(
      scheme: scheme,
      background: AppColors.background,
      brightness: Brightness.light,
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      tertiary: AppColors.darkPositive,
      onTertiary: AppColors.darkBackground,
      error: AppColors.danger,
      onError: Color(0xFFFFFFFF),
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      onSurfaceVariant: AppColors.darkTextSecondary,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkBorder,
      surfaceContainerHighest: AppColors.darkSurfaceMuted,
      surfaceContainerHigh: AppColors.darkSurfaceMuted,
      surfaceContainer: AppColors.darkSurface,
      surfaceContainerLow: AppColors.darkBackground,
    );
    return _base(
      scheme: scheme,
      background: AppColors.darkBackground,
      brightness: Brightness.dark,
    );
  }

  static ThemeData _base({
    required ColorScheme scheme,
    required Color background,
    required Brightness brightness,
  }) {
    final onSurface = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;
    final textTheme = TextTheme(
      displaySmall: AppTextStyles.balance.copyWith(color: onSurface),
      headlineMedium: AppTextStyles.title.copyWith(color: onSurface),
      titleLarge: AppTextStyles.headline.copyWith(color: onSurface),
      titleMedium: AppTextStyles.body.copyWith(
        color: onSurface,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: AppTextStyles.body.copyWith(color: onSurface),
      bodyMedium: AppTextStyles.secondary.copyWith(color: muted),
      bodySmall: AppTextStyles.meta.copyWith(color: muted),
      labelLarge: AppTextStyles.button.copyWith(color: onSurface),
    );

    final shape = RoundedRectangleBorder(borderRadius: AppRadii.card);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      applyElevationOverlayColor: false,
      splashFactory: InkRipple.splashFactory,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: onSurface, size: 22),
      dividerColor: scheme.outline,
      dividerTheme: DividerThemeData(
        color: scheme.outline,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headline.copyWith(color: onSurface),
        iconTheme: IconThemeData(color: onSurface, size: 22),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.surfaceContainerHighest,
          disabledForegroundColor: muted,
          textStyle: AppTextStyles.button,
          minimumSize: const Size.fromHeight(48),
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: onSurface,
          side: BorderSide(color: scheme.outline),
          textStyle: AppTextStyles.button,
          minimumSize: const Size.fromHeight(48),
          shape: shape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: muted,
          textStyle: AppTextStyles.button.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        hintStyle: AppTextStyles.body.copyWith(color: muted),
        labelStyle: AppTextStyles.secondary.copyWith(color: muted),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: UnderlineInputBorder(borderSide: BorderSide(color: scheme.outline)),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: background,
        selectedColor: scheme.surfaceContainerHighest,
        disabledColor: scheme.surfaceContainerHighest,
        side: BorderSide(color: scheme.outline),
        labelStyle: AppTextStyles.meta.copyWith(color: onSurface),
        secondaryLabelStyle: AppTextStyles.meta.copyWith(color: onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        showCheckmark: false,
        elevation: 0,
        pressElevation: 0,
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: scheme.outline,
        indicatorColor: onSurface,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: onSurface,
        unselectedLabelColor: muted,
        labelStyle: AppTextStyles.meta.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTextStyles.meta,
        overlayColor: WidgetStatePropertyAll(
          scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        height: 64,
        indicatorColor: scheme.surfaceContainerHighest,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? onSurface : muted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTextStyles.meta.copyWith(
            color: selected ? onSurface : muted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        shape: shape,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: onSurface,
        contentTextStyle: AppTextStyles.secondary.copyWith(
          color: scheme.surface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        titleTextStyle: AppTextStyles.body.copyWith(color: onSurface),
        subtitleTextStyle: AppTextStyles.meta.copyWith(color: muted),
        minVerticalPadding: 12,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
