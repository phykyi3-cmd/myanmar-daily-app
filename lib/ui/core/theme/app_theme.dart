import 'package:flutter/material.dart';

/// NBK-inspired Dark + Electric Neon Lime Green (`#B5F12E` on `#0D0D0D`) Design System
/// tailored for crisp Myanmar Unicode readability.
class AppTheme {
  const AppTheme._();

  // NBK Design System Swatches (100 - 1000)
  static const Color white100 = Color(0xFFFFFFFF);
  static const Color gray200 = Color(0xFFB4B4B4);
  static const Color gray300 = Color(0xFF7F8185);
  static const Color gray400 = Color(0xFF2C2F36);
  static const Color neonLime500 = Color(0xFFDAFA49);
  static const Color neonLime600 = Color(0xFFB5F12E);
  static const Color lime700 = Color(0xFF86B81B);
  static const Color olive800 = Color(0xFF4A6317);
  static const Color olive900 = Color(0xFF232F10);
  static const Color obsidian1000 = Color(0xFF0D0D0D);

  static const Color cardSurface = Color(0xFF16181C);
  static const Color cardSurfaceElevated = Color(0xFF1E2026);
  static const Color cardBorder = Color(0xFF2A2D35);

  static ThemeData light() => darkNbk();

  static ThemeData darkNbk() {
    const scheme = ColorScheme.dark(
      primary: neonLime600,
      onPrimary: obsidian1000,
      primaryContainer: olive900,
      onPrimaryContainer: neonLime500,
      secondary: neonLime500,
      onSecondary: obsidian1000,
      secondaryContainer: Color(0xFF263311),
      onSecondaryContainer: neonLime500,
      tertiary: Color(0xFF38BDF8),
      onTertiary: obsidian1000,
      surface: cardSurface,
      onSurface: white100,
      onSurfaceVariant: gray200,
      outline: cardBorder,
      outlineVariant: Color(0xFF22252B),
      error: Color(0xFFFF6B6B),
      onError: obsidian1000,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: obsidian1000,
      dividerColor: cardBorder,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: obsidian1000,
        foregroundColor: white100,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: white100,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: cardBorder, width: 1.2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF181A20),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFF323640), width: 1.2),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF16181D),
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: neonLime600,
          foregroundColor: obsidian1000,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: neonLime500,
          side: const BorderSide(color: olive800, width: 1.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: neonLime600,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: neonLime600,
        foregroundColor: obsidian1000,
        extendedTextStyle: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardSurfaceElevated,
        selectedColor: neonLime600,
        secondarySelectedColor: neonLime600,
        side: const BorderSide(color: Color(0xFF2E323B)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: const TextStyle(
          color: white100,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: obsidian1000,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
        checkmarkColor: obsidian1000,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return neonLime600;
            }
            return cardSurface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return obsidian1000;
            }
            return gray200;
          }),
          side: WidgetStateProperty.all(
            const BorderSide(color: Color(0xFF2E323B), width: 1.2),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF121317),
        surfaceTintColor: Colors.transparent,
        indicatorColor: neonLime600,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: obsidian1000, size: 22);
          }
          return const IconThemeData(color: gray300, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: neonLime600,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            );
          }
          return const TextStyle(
            color: gray300,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111317),
        labelStyle: const TextStyle(color: gray200),
        hintStyle: const TextStyle(color: gray300),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2E323B)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2E323B)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: neonLime600, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1E2229),
        contentTextStyle: const TextStyle(
          color: white100,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: neonLime600, width: 1.2),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
