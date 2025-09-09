import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static const _kToken = 'porto_token';
  static const _kUser  = 'porto_user';

  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  /// Guarda token y usuario (ambos como String).
  static Future<void> saveAuth({
    required String token,
    required String userJson,
  }) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kToken, token);
      await prefs.setString(_kUser, userJson);
    } else {
      await _secure.write(key: _kToken, value: token);
      await _secure.write(key: _kUser, value: userJson);
    }
  }

  static Future<String?> getToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kToken);
    } else {
      return await _secure.read(key: _kToken);
    }
  }

  static Future<String?> getUserJson() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kUser);
    } else {
      return await _secure.read(key: _kUser);
    }
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final raw = await getUserJson();
    if (raw == null) return null;
    try {
      final parsed = jsonDecode(raw);
      return parsed is Map<String, dynamic> ? parsed : {'value': parsed};
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kToken);
      await prefs.remove(_kUser);
    } else {
      await _secure.delete(key: _kToken);
      await _secure.delete(key: _kUser);
    }
  }
}
