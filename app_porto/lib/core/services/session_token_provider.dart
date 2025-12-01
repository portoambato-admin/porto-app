// lib/core/services/session_token_provider.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionTokenProvider {
  SessionTokenProvider._();
  static final SessionTokenProvider instance = SessionTokenProvider._();

  final _storage = const FlutterSecureStorage();
  
  static const _keyToken = 'auth_token';
  static const _keyUser  = 'auth_user_data';

  // --- TOKEN ---
  Future<String?> readToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyToken);
    } else {
      return await _storage.read(key: _keyToken);
    }
  }

  Future<void> saveToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
    } else {
      await _storage.write(key: _keyToken, value: token);
    }
  }

  // --- USUARIO (JSON) ---
  Future<String?> readUser() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUser);
    } else {
      return await _storage.read(key: _keyUser);
    }
  }

  Future<void> saveUser(String json) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUser, json);
    } else {
      await _storage.write(key: _keyUser, value: json);
    }
  }

  // --- LIMPIEZA ---
  Future<void> clearCache() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUser);
    } else {
      await _storage.delete(key: _keyToken);
      await _storage.delete(key: _keyUser);
    }
  }
}