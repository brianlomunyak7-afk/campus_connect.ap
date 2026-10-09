import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static String? token;
  static String? username;

  static bool get isLoggedIn => token != null;

  static Future<void> saveToken(String t, String u) async {
    token = t;
    username = u;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', t);
    await prefs.setString('username', u);
  }

  static Future<bool> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    username = prefs.getString('username');
    return token != null;
  }

  static Future<void> clear() async {
    token = null;
    username = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('username');
  }
}