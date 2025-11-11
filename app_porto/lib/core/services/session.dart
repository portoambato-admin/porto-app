import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Import condicional para Web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;

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
      
      // ✅ También actualizar localStorage como respaldo
      try {
        html.window.localStorage[_kToken] = token;
      } catch (e) {
        print('[Session] Error guardando en localStorage: $e');
      }
    } else {
      await _secure.write(key: _kToken, value: token);
      await _secure.write(key: _kUser, value: userJson);
    }
  }

  static Future<String?> getToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_kToken);
      
      // ✅ Fallback: si no está en SharedPreferences, buscar en localStorage
      if (token == null || token.isEmpty) {
        try {
          return html.window.localStorage[_kToken];
        } catch (e) {
          print('[Session] Error leyendo localStorage: $e');
        }
      }
      
      return token;
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
    if (raw == null || raw.isEmpty) return null;
    try {
      final parsed = jsonDecode(raw);
      return parsed is Map<String, dynamic> ? parsed : {'value': parsed};
    } catch (e) {
      print('[Session] Error parseando usuario: $e');
      return null;
    }
  }

  static Future<void> clear() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kToken);
      await prefs.remove(_kUser);
      
      // ✅ También limpiar localStorage
      try {
        html.window.localStorage.remove(_kToken);
        html.window.localStorage.remove(_kUser);
      } catch (e) {
        print('[Session] Error limpiando localStorage: $e');
      }
    } else {
      await _secure.delete(key: _kToken);
      await _secure.delete(key: _kUser);
    }
  }
}