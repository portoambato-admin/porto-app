import 'dart:convert';
import 'package:flutter/widgets.dart'; // 👈 IMPORTA Widgets (Widget, BuildContext, InheritedNotifier, ChangeNotifier)

import '../services/session.dart';

// Cliente HTTP central + token provider + endpoints
import '../network/http_client.dart';
import '../services/session_token_provider.dart';
import '../constants/endpoints.dart';

class AuthState extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;

  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _user != null;

  int? get roleId => _user?['id_rol'] as int?;
  bool get isAdmin => roleId == 1;
  bool get isTeacher => roleId == 2;
  bool get isParent => roleId == 3;

  // Cliente HTTP con token automático (lee de Session)
  final HttpClient _http = HttpClient(tokenProvider: SessionTokenProvider());

  /// Carga token y usuario desde Session.
  /// Si no hay usuario cacheado, consulta GET /me y persiste con saveAuth.
  Future<void> load() async {
    try {
      _token = await Session.getToken();

      if (_token == null) {
        _user = null;
        notifyListeners();
        return;
      }

      // 1) Rehidrata desde caché si existe
      final cached = await Session.getUser(); // <- tu API real
      if (cached != null) {
        _user = Map<String, dynamic>.from(cached);
      } else {
        // 2) Si no hay user cacheado, trae /me del backend
        final res = await _http.get(Endpoints.me, headers: {});
        if (res is Map && res['usuario'] is Map) {
          _user = Map<String, dynamic>.from(res['usuario'] as Map);
        } else {
          _user = Map<String, dynamic>.from(res as Map);
        }
        // Persiste user junto con el token existente
        await Session.saveAuth(
          token: _token!,
          userJson: jsonEncode(_user),
        );
      }
    } catch (_) {
      // Si algo falla, limpiamos estado en memoria
      _token = null;
      _user = null;
      // (No borramos storage aquí para no forzar logout agresivo)
    } finally {
      notifyListeners();
    }
  }

  /// Guarda token+usuario y notifica (para el login).
  Future<void> signIn({
    required String token,
    required String userJson,
  }) async {
    _token = token;
    await Session.saveAuth(token: token, userJson: userJson);

    try {
      _user = jsonDecode(userJson) as Map<String, dynamic>;
    } catch (_) {
      _user = null;
    }
    notifyListeners();
  }

  /// Actualiza el usuario en memoria y en Session (manteniendo el token actual).
  Future<void> setUser(Map<String, dynamic> u) async {
    _user = Map<String, dynamic>.from(u);
    final t = _token ?? await Session.getToken();
    if (t != null) {
      await Session.saveAuth(token: t, userJson: jsonEncode(_user));
    }
    notifyListeners();
  }

  /// Cierra sesión y limpia Session en disco.
  Future<void> signOut() async {
    // (Opcional) Puedes llamar a /auth/logout con _http.post si tu backend lo necesita.
    await Session.clear();
    _token = null;
    _user = null;
    notifyListeners();
  }
}

/// Mantiene la API que ya usabas:
/// - AuthScope.of(context).signIn(...)
/// - AuthScope.of(context).setUser(...)
/// - AuthScope.of(context).load()
/// - AuthScope.of(context).signOut()
class AuthScope extends InheritedNotifier<AuthState> {
  const AuthScope({
    super.key,
    required this.controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  final AuthState controller;

  static AuthState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found in widget tree');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(AuthScope oldWidget) => controller != oldWidget.controller;
}
