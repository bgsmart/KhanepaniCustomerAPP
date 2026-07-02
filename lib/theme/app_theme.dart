// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors (existing)
  static const Color primary = Color(0xFF0058BC);
  static const Color primaryContainer = Color(0xFF0070EB);
  static const Color primaryFixed = Color(0xFFD8E2FF);
  static const Color primaryFixedDim = Color(0xFFADC6FF);
  
  static const Color secondary = Color(0xFF006E28);
  static const Color secondaryContainer = Color(0xFF6FFB85);
  static const Color secondaryFixed = Color(0xFF72FE88);
  static const Color secondaryFixedDim = Color(0xFF53E16F);
  
  static const Color tertiary = Color(0xFF4C4ACA);
  static const Color tertiaryContainer = Color(0xFF6664E4);
  static const Color tertiaryFixed = Color(0xFFE2DFFF);
  
  static const Color surface = Color(0xFFF5FAFE);
  static const Color surfaceDim = Color(0xFFD5DBDF);
  static const Color surfaceContainer = Color(0xFFE9EEF2);
  static const Color surfaceContainerLow = Color(0xFFEFF4F8);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFE4E9ED);
  static const Color surfaceContainerHighest = Color(0xFFDEE3E7);
  
  static const Color onSurface = Color(0xFF171C1F);
  static const Color onSurfaceVariant = Color(0xFF414755);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFFEFCFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF00732A);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFFFFBFF);
  
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);
  
  static const Color outline = Color(0xFF717786);
  static const Color outlineVariant = Color(0xFFC1C6D7);
  static const Color background = Color(0xFFF5FAFE);
  static const Color onBackground = Color(0xFF171C1F);

  // Spacing & Sizing Constants
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 40.0;
  
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // Border Radius
  static const double borderRadiusXSmall = 4.0;
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 20.0;
  static const double borderRadiusXXLarge = 24.0;
  
  // Elevation
  static const double elevationNone = 0.0;
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;
  
  // Stroke Width
  static const double strokeWidthRegular = 1.0;
  static const double strokeWidthThick = 2.0;
  
  // Icon Sizes
  static const double iconSmall = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 40.0;
  static const double iconXXLarge = 48.0;
  static const double iconXXXLarge = 56.0;
  
  // Button Sizes
  static const double buttonHeightSmall = 40.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;
  
  // Logo Sizes
  static const double logoWidth = 100.0;
  static const double logoHeight = 100.0;
  
  // Font Sizes
  static const double fontSizeXXSmall = 10.0;
  static const double fontSizeXSmall = 11.0;
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 20.0;
  static const double fontSizeXXLarge = 28.0;
  
  // Font Weights
  static const FontWeight fontWeightThin = FontWeight.w100;
  static const FontWeight fontWeightExtraLight = FontWeight.w200;
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtraBold = FontWeight.w800;
  static const FontWeight fontWeightBlack = FontWeight.w900;

  // Company Information
  static const String logoPath = 'assets/Logo.png';
  static const String companyName = 'HWSMBOARD';
  static const String companyAddress = 'Nairobi, Kenya';
  static const String tagline = 'Manage your water supply with ease';
  
  // Text Styles (existing)
  static TextStyle get displayLarge => GoogleFonts.manrope(
    fontSize: fontSizeXXLarge,
    fontWeight: fontWeightBold,
    height: 1.25,
  );
  
  static TextStyle get displayMedium => GoogleFonts.manrope(
    fontSize: fontSizeXLarge,
    fontWeight: fontWeightBold,
    height: 1.21,
  );
  
  static TextStyle get displaySmall => GoogleFonts.manrope(
    fontSize: fontSizeLarge,
    fontWeight: fontWeightSemiBold,
    height: 1.33,
  );
  
  static TextStyle get headlineMedium => GoogleFonts.manrope(
    fontSize: fontSizeXLarge,
    fontWeight: fontWeightSemiBold,
    height: 1.4,
  );
  
  static TextStyle get headlineSmall => GoogleFonts.manrope(
    fontSize: fontSizeLarge,
    fontWeight: fontWeightSemiBold,
    height: 1.5,
  );
  
  static TextStyle get bodyLarge => GoogleFonts.manrope(
    fontSize: fontSizeLarge,
    fontWeight: fontWeightRegular,
    height: 1.5,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.manrope(
    fontSize: fontSizeMedium,
    fontWeight: fontWeightRegular,
    height: 1.43,
  );
  
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: fontSizeSmall,
    fontWeight: fontWeightMedium,
    height: 1.33,
    letterSpacing: 0.02,
  );
  
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: fontSizeSmall,
    fontWeight: fontWeightMedium,
    height: 1.33,
    letterSpacing: 0.02,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceContainerHighest,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainerLowest: surfaceContainerLowest,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      fontFamily: GoogleFonts.manrope().fontFamily,
      textTheme: TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: elevationNone,
        centerTitle: false,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: fontSizeXLarge,
          fontWeight: fontWeightSemiBold,
          height: 1.33,
          color: primary,
        ),
        iconTheme: const IconThemeData(color: primary),
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceContainerLowest,
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceVariant,
        elevation: elevationLarge,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: fontSizeSmall, fontWeight: fontWeightMedium),
        unselectedLabelStyle: TextStyle(fontSize: fontSizeSmall, fontWeight: fontWeightMedium),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: elevationNone,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          side: BorderSide(color: outlineVariant.withOpacity(0.3)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: paddingLarge, vertical: paddingMedium),
          textStyle: GoogleFonts.manrope(
            fontSize: fontSizeLarge,
            fontWeight: fontWeightSemiBold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: primary, width: strokeWidthThick),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: paddingMedium, vertical: paddingMedium),
        labelStyle: GoogleFonts.inter(
          fontSize: fontSizeSmall,
          fontWeight: fontWeightMedium,
          color: onSurfaceVariant,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerLowest,
        selectedColor: primary,
        labelStyle: GoogleFonts.inter(
          fontSize: fontSizeSmall,
          fontWeight: fontWeightMedium,
          color: onSurfaceVariant,
        ),
        padding: const EdgeInsets.symmetric(horizontal: paddingMedium, vertical: spacingXSmall),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        side: const BorderSide(color: outlineVariant),
      ),
    );
  }
}