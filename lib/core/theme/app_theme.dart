import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Warna Utama (Tosca GearShift) - Dipertahankan!
  static const Color primaryColor = Color(0xFF36ADA3);

  // ==========================================
  // ☀️ CONFIGURATION TEMA LIGHT: "Clean Showroom"
  // ==========================================
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      // Latar belakang sedikit dicerahkan agar lebih terasa seperti showroom putih bersih
      scaffoldBackgroundColor: const Color(0xFFEFE9E3),
      cardColor: Colors.white,
      primaryColor: primaryColor,
      iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: Color(0xFFFF9100),                  // Warna aksen oranye (untuk status pending, dll)
        surface: Colors.white,
        onSurface: Color(0xFF1A1A1A),                  // Hitam elegan (tidak terlalu pekat)
      ),
      // 👇 SUNTIKAN FONT PREMIUM MONTSERRAT 👇
      textTheme: GoogleFonts.montserratTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
        titleTextStyle: TextStyle(color: Color(0xFF1A1A1A), fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ==========================================
  // TEMA GELAP (DARK MODE) - GEARSHIFT PREMIUM
  // ==========================================
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,

      // Warna utama (Teal/Cyan dari tombol login)
      primaryColor: const Color(0xFF36ADA3),

      // Warna dasar paling gelap dari gradient background login
      scaffoldBackgroundColor: const Color(0xFF0F2027),

      // Warna Card (sedikit lebih terang dari background agar menonjol)
      cardColor: const Color(0xFF203A43),

      // Warna garis pemisah
      dividerColor: Colors.white24,

      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF36ADA3),
        secondary: Color(0xFF36ADA3),
        surface: Color(0xFF203A43),
        // Latar belakang aplikasi
        background: Color(0xFF0F2027),
      ),

      // Gaya AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F2027), // Menyatu dengan background utama
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),

      // Gaya Bottom Navigation Bar (Menu Bawah)
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0F2027),
        selectedItemColor: Color(0xFF36ADA3), // Menyala terang saat dipilih
        unselectedItemColor: Colors.white54,
        elevation: 15,
        type: BottomNavigationBarType.fixed,
      ),

      // Gaya ElevetaedButton Global
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF36ADA3),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Gaya Input (TextField) jika ada di halaman lain
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF36ADA3), width: 2),
        ),
      ),
    );
  }
}