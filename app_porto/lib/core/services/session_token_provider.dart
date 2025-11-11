// lib/core/services/session_token_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../network/http_client.dart';
import 'session.dart';

class SessionTokenProvider implements TokenProvider {
  SessionTokenProvider._();
  static final SessionTokenProvider instance = SessionTokenProvider._();

  String? _cache;

  void clearCache() => _cache = null;

  @override
  Future<String?> getToken() async {
    if (_cache != null && _cache!.isNotEmpty) return _cache;

    final fromSession = await Session.getToken();
    if (fromSession != null && fromSession.isNotEmpty) {
      _cache = fromSession;
      return _cache;
    }

    if (kIsWeb) {
      try {
        final s = html.window.localStorage;
        _cache = s['auth_token'] ??
                 s['porto_token'] ??
                 s['token'] ??
                 s['jwt'] ??
                 s['access_token'];
        if (_cache != null && _cache!.isNotEmpty) return _cache;
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<String?> refreshToken() async {
    // Implementa refresh real si lo necesitas en el futuro
    return null;
  }
}
