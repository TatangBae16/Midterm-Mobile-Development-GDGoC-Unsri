import 'package:shared_preferences/shared_preferences.dart';

class ThemeHelper {
  static const String key = 'is_dark_mode';

  static Future<void> saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, isDark);
  }

  static Future<bool> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false; // Default: Light Mode
  }
}