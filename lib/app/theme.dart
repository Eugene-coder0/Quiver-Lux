import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuiverLuxTheme {
  // Brand Colors
  static const Color warmWhite = Color(0xFFF9F8F6);
  static const Color softGray = Color(0xFFECE9E4);
  static const Color matteBlack = Color(0xFF181716);
  static const Color champagneGold = Color(0xFFC6A15B);
  static const Color forest = Color(0xFF183B32);
  static const Color darkBackground = Color(0xFF121212);

  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.manropeTextTheme();
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: warmWhite,
      colorScheme: const ColorScheme.light(primary: matteBlack, secondary: champagneGold, surface: Colors.white, onSurface: matteBlack),
      textTheme: textTheme.copyWith(
        displaySmall: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        headlineSmall: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(backgroundColor: warmWhite, foregroundColor: matteBlack, surfaceTintColor: Colors.transparent, elevation: 0),
      cardTheme: CardThemeData(color: Colors.white, surfaceTintColor: Colors.transparent, elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: softGray)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: softGray)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: champagneGold, width: 1.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: matteBlack, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: .6))),
      chipTheme: ChipThemeData(backgroundColor: Colors.white, side: const BorderSide(color: softGray), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      dividerTheme: const DividerThemeData(color: softGray),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
