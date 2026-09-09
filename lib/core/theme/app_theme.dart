import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  AppTheme._();

  // =========================================================
  // BRAND
  // =========================================================

  static const Color primary = Color(
    0xFF6366F1,
  );

  static const Color secondary = Color(
    0xFF8B5CF6,
  );

  static const Color income = Color(
    0xFF22C55E,
  );

  static const Color expense = Color(
    0xFFEF4444,
  );

  static const Color warning = Color(
    0xFFF59E0B,
  );

  // =========================================================
  // BACKGROUNDS
  // =========================================================

  static const Color lightBackground = Color(
    0xFFF6F7FB,
  );

  static const Color darkBackground = Color(
    0xFF0F1115,
  );

  static const Color darkSurface = Color(
    0xFF181B21,
  );

  static const Color darkSurfaceHigher = Color(
    0xFF22252D,
  );

  // =========================================================
  // LIGHT
  // =========================================================

  static ThemeData get lightTheme {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    );

    final colorScheme = baseScheme.copyWith(
      primary: primary,
      secondary: secondary,
      surface: Colors.white,
      surfaceContainerHighest: const Color(
        0xFFEEF0F5,
      ),
      outlineVariant: const Color(
        0xFFE4E6EC,
      ),
      error: expense,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBackground,

      // =====================================================
      // APP BAR
      // =====================================================

      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(
          0xFF18181B,
        ),
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: lightBackground,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      ),

      // =====================================================
      // CARDS
      // =====================================================

      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            20,
          ),
        ),
      ),

      // =====================================================
      // INPUTS
      // =====================================================

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            16,
          ),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            16,
          ),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            16,
          ),
          borderSide: const BorderSide(
            color: primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            16,
          ),
          borderSide: const BorderSide(
            color: expense,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            16,
          ),
          borderSide: const BorderSide(
            color: expense,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: Color(
          0x336366F1,
        ),
        selectionHandleColor: primary,
      ),

      // =====================================================
      // BUTTONS
      // =====================================================

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(
            0,
            48,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              14,
            ),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            0,
            48,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              14,
            ),
          ),
          side: BorderSide(
            color: colorScheme.outlineVariant,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // =====================================================
      // FAB
      // =====================================================

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        highlightElevation: 3,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            18,
          ),
        ),
      ),

      // =====================================================
      // NAVIGATION
      // =====================================================

      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withValues(
          alpha: 0.12,
        ),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            16,
          ),
        ),
      ),

      // =====================================================
      // DIVIDER
      // =====================================================

      dividerTheme: const DividerThemeData(
        color: Color(
          0xFFE4E6EC,
        ),
        thickness: 1,
        space: 1,
      ),

      // =====================================================
      // PROGRESS
      // =====================================================

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primary.withValues(
          alpha: 0.10,
        ),
        circularTrackColor: primary.withValues(
          alpha: 0.10,
        ),
      ),

      // =====================================================
      // SNACKBAR
      // =====================================================

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(
          0xFF27272A,
        ),
        contentTextStyle: const TextStyle(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            14,
          ),
        ),
        insetPadding: const EdgeInsets.all(
          16,
        ),
      ),

      // =====================================================
      // CHIPS
      // =====================================================

      chipTheme: ChipThemeData(
        side: BorderSide.none,
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            30,
          ),
        ),
      ),

      // =====================================================
      // SWITCH / RADIO
      // =====================================================

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (
            states,
          ) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return Colors.white;
            }

            return null;
          },
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (
            states,
          ) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return primary;
            }

            return null;
          },
        ),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (
            states,
          ) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return primary;
            }

            return null;
          },
        ),
      ),

      // =====================================================
      // BOTTOM SHEET
      // =====================================================

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),

      // =====================================================
      // POPUP MENU
      // =====================================================

      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            16,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // DARK
  // =========================================================

  static ThemeData get darkTheme {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    );

    final colorScheme = baseScheme.copyWith(
      primary: primary,
      secondary: secondary,
      surface: darkSurface,
      surfaceContainerHighest: darkSurfaceHigher,
      outlineVariant: const Color(
        0xFF30333B,
      ),
      error: expense,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,

      // =====================================================
      // APP BAR
      // =====================================================

      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: darkBackground,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      ),

      // =====================================================
      // CARDS
      // =====================================================

      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            20,
          ),
        ),
      ),

      // =====================================================
      // INPUTS
      // =====================================================

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            16,
          ),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            16,
          ),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            16,
          ),
          borderSide: const BorderSide(
            color: primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            16,
          ),
          borderSide: const BorderSide(
            color: expense,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            16,
          ),
          borderSide: const BorderSide(
            color: expense,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: Color(
          0x556366F1,
        ),
        selectionHandleColor: primary,
      ),

      // =====================================================
      // BUTTONS
      // =====================================================

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(
            0,
            48,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              14,
            ),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            0,
            48,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              14,
            ),
          ),
          side: BorderSide(
            color: colorScheme.outlineVariant,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // =====================================================
      // FAB
      // =====================================================

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        highlightElevation: 3,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            18,
          ),
        ),
      ),

      // =====================================================
      // NAVIGATION
      // =====================================================

      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        elevation: 0,
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withValues(
          alpha: 0.22,
        ),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            16,
          ),
        ),
      ),

      // =====================================================
      // DIVIDER
      // =====================================================

      dividerTheme: const DividerThemeData(
        color: Color(
          0xFF30333B,
        ),
        thickness: 1,
        space: 1,
      ),

      // =====================================================
      // PROGRESS
      // =====================================================

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primary.withValues(
          alpha: 0.16,
        ),
        circularTrackColor: primary.withValues(
          alpha: 0.16,
        ),
      ),

      // =====================================================
      // SNACKBAR
      // =====================================================

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(
          0xFF272A31,
        ),
        contentTextStyle: const TextStyle(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            14,
          ),
        ),
        insetPadding: const EdgeInsets.all(
          16,
        ),
      ),

      // =====================================================
      // CHIPS
      // =====================================================

      chipTheme: ChipThemeData(
        side: BorderSide.none,
        backgroundColor: darkSurfaceHigher,
        selectedColor: primary.withValues(
          alpha: 0.22,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            30,
          ),
        ),
      ),

      // =====================================================
      // SWITCH / RADIO
      // =====================================================

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (
            states,
          ) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return Colors.white;
            }

            return null;
          },
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (
            states,
          ) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return primary;
            }

            return null;
          },
        ),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (
            states,
          ) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return primary;
            }

            return null;
          },
        ),
      ),

      // =====================================================
      // BOTTOM SHEET
      // =====================================================

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),

      // =====================================================
      // POPUP MENU
      // =====================================================

      popupMenuTheme: PopupMenuThemeData(
        color: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            16,
          ),
        ),
      ),
    );
  }
}
