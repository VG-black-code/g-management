import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData _createTheme(ColorScheme colorScheme, Color scaffoldBg) {
    // Ensure the base typography matches the brightness of the color scheme
    final baseTextTheme = colorScheme.brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(baseTextTheme);
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: textTheme,
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: colorScheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),

      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
        hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
        labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
        prefixIconColor: colorScheme.primary,
        suffixIconColor: colorScheme.primary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      
      dividerTheme: DividerThemeData(
        color: colorScheme.onSurface.withOpacity(0.1),
        thickness: 1,
      ),
    );
  }

  static ThemeData get lavenderTheme {
    return _createTheme(
      ColorScheme.fromSeed(
        seedColor: AppColors.lavenderPrimary,
        primary: AppColors.lavenderPrimary,
        surface: Colors.white,
        onSurface: Colors.black87,
        background: AppColors.lavenderBg,
        brightness: Brightness.light,
      ),
      AppColors.lavenderBg,
    );
  }

  static ThemeData get orangeTheme {
    return _createTheme(
      ColorScheme.fromSeed(
        seedColor: AppColors.orangePrimary,
        primary: AppColors.orangePrimary,
        surface: Colors.white,
        onSurface: Colors.black87,
        background: AppColors.orangeBg,
        brightness: Brightness.light,
      ),
      AppColors.orangeBg,
    );
  }

  static ThemeData get blueTheme {
    return _createTheme(
      ColorScheme.fromSeed(
        seedColor: AppColors.lightbluePrimary,
        primary: AppColors.lightbluePrimary,
        surface: Colors.white,
        onSurface: Colors.black87,
        background: AppColors.lightblueBg,
        brightness: Brightness.light,
      ),
      AppColors.lightblueBg,
    );
  }

  static ThemeData get darkTheme {
    return _createTheme(
      ColorScheme.fromSeed(
        seedColor: AppColors.bluePrimaryDark,
        primary: AppColors.bluePrimaryDark,
        brightness: Brightness.dark,
        surface: AppColors.cardBgDark,
        onSurface: AppColors.textPrimaryDark,
        background: AppColors.bgDark,
      ),
      AppColors.bgDark,
    );
  }

  static ThemeData get defaultTheme => lavenderTheme;
}
