import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserStore {
  static const _kUser = 'user_name';
  static const _kSalt = 'user_salt';
  static const _kHash = 'user_hash';
  static const _kLogged = 'logged_in';
  static const _kTheme = 'theme_mode'; // light / dark / system

  // ====== registro / login ======

  static Future<bool> hasUser() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kUser) != null && sp.getString(_kHash) != null && sp.getString(_kSalt) != null;
  }

  static Future<void> saveUser(String username, String password) async {
    final sp = await SharedPreferences.getInstance();
    final salt = _randomSalt();
    final hash = _hash(password, salt);
    await sp.setString(_kUser, username);
    await sp.setString(_kSalt, salt);
    await sp.setString(_kHash, hash);
  }

  static Future<bool> validateLogin(String username, String password) async {
    final sp = await SharedPreferences.getInstance();
    final u = sp.getString(_kUser);
    final salt = sp.getString(_kSalt);
    final hash = sp.getString(_kHash);
    if (u == null || salt == null || hash == null) return false;
    if (username.trim() != u) return false;
    return _hash(password, salt) == hash;
  }

  static Future<void> setLoggedIn(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kLogged, value);
  }

  static Future<bool> isLoggedIn() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kLogged) ?? false;
  }

  static Future<String?> currentUser() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kUser);
  }

  static String _randomSalt() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String _hash(String password, String salt) {
    final bytes = utf8.encode('$salt$password');
    return sha256.convert(bytes).toString();
  }

  // ====== tema ======

  static Future<void> setThemeMode(String mode) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kTheme, mode);
  }

  static Future<String> getThemeMode() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kTheme) ?? 'system';
  }
}
