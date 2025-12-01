// lib/core/state/auth_state.dart

import 'dart:convert';
import 'package:flutter/widgets.dart';

import '../services/session_token_provider.dart';
import '../network/http_client.dart';
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

  final HttpClient _http;
  AuthState(this._http);

  /* ============================================================
   *  Carga inicial de sesión
   * ============================================================ */
  Future<void> load() async {
    try {
      debugPrint('[AuthState] 🔄 Iniciando carga de sesión...');
      
      // 1. Leer token guardado
      _token = await SessionTokenProvider.instance.readToken();
      debugPrint('[AuthState] 🔑 Token leído: ${_token?.substring(0, 20)}...');

      if (_token == null || _token!.isEmpty) {
        debugPrint('[AuthState] ❌ No hay token guardado');
        _user = null;
        notifyListeners();
        return;
      }

      // 2. Leer usuario desde caché
      final cached = await SessionTokenProvider.instance.readUser();
      debugPrint('[AuthState] 📦 Usuario en caché: ${cached?.substring(0, 50)}...');
      
      if (cached != null && cached.isNotEmpty) {
        _user = Map<String, dynamic>.from(jsonDecode(cached));
        debugPrint('[AuthState] ✅ Usuario cargado desde caché: ${_user?['nombre']}');
        notifyListeners();
        return;
      }

      // 3. Leer usuario desde API
      try {
        debugPrint('[AuthState] 🌐 Consultando /me...');
        final res = await _http.get(Endpoints.me);

        if (res is Map && res['usuario'] is Map) {
          _user = Map<String, dynamic>.from(res['usuario']);
        } else {
          _user = Map<String, dynamic>.from(res);
        }

        debugPrint('[AuthState] ✅ Usuario obtenido de API: ${_user?['nombre']}');

        // Guardar sesión
        await SessionTokenProvider.instance.saveToken(_token!);
        await SessionTokenProvider.instance.saveUser(jsonEncode(_user));
        debugPrint('[AuthState] 💾 Sesión guardada correctamente');

      } catch (e) {
        debugPrint('[AuthState] ❌ Error obteniendo usuario: $e');
        // Token inválido
        await SessionTokenProvider.instance.clearCache();
        _token = null;
        _user = null;
      }

    } catch (e) {
      debugPrint('[AuthState] ❌ Error en load(): $e');
    } finally {
      notifyListeners();
      debugPrint('[AuthState] 🏁 Carga finalizada. User: ${_user != null ? "✓" : "✗"}');
    }
  }

  /* ============================================================
   *  Guardar sesión al iniciar sesión
   * ============================================================ */
  Future<void> signIn({
    required String token,
    required String userJson,
  }) async {
    debugPrint('[AuthState] 🔐 SignIn iniciado');
    debugPrint('[AuthState] 🔑 Token: ${token.substring(0, 20)}...');
    debugPrint('[AuthState] 👤 User JSON: ${userJson.substring(0, 100)}...');
    
    _token = token;
    _user = Map<String, dynamic>.from(jsonDecode(userJson));

    // Persistir correctamente
    await SessionTokenProvider.instance.saveToken(token);
    await SessionTokenProvider.instance.saveUser(userJson);

    // Pequeña espera para asegurar persistencia en web
    await Future.delayed(const Duration(milliseconds: 50));

    // Verificar que se guardó
    final savedToken = await SessionTokenProvider.instance.readToken();
    final savedUser = await SessionTokenProvider.instance.readUser();
    
    debugPrint('[AuthState] ✅ Token guardado y verificado: ${savedToken?.substring(0, 20)}...');
    debugPrint('[AuthState] ✅ User guardado y verificado: ${savedUser?.substring(0, 50)}...');

    notifyListeners();
  }

  /* ============================================================
   *  Actualizar usuario
   * ============================================================ */
  Future<void> setUser(Map<String, dynamic> u) async {
    debugPrint('[AuthState] 📝 Actualizando usuario: ${u['nombre']}');
    _user = Map<String, dynamic>.from(u);

    if (_token != null) {
      await SessionTokenProvider.instance.saveUser(jsonEncode(_user));
      debugPrint('[AuthState] 💾 Usuario actualizado en storage');
    }

    notifyListeners();
  }

  /* ============================================================
   *  Cerrar sesión
   * ============================================================ */
  Future<void> signOut() async {
    debugPrint('[AuthState] 👋 SignOut iniciado');
    
    try {
      if (_token != null) {
        await _http.post(Endpoints.authLogout, body: const {});
      }
    } catch (e) {
      debugPrint('[AuthState] ⚠️ Error en logout API: $e');
    }

    await SessionTokenProvider.instance.clearCache();
    _token = null;
    _user = null;

    debugPrint('[AuthState] ✅ Sesión limpiada');
    notifyListeners();
  }
}

/* ============================================================
 *  AuthScope
 * ============================================================ */
class AuthScope extends InheritedNotifier<AuthState> {
  const AuthScope({
    super.key,
    required this.controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  final AuthState controller;

  static AuthState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(AuthScope oldWidget) =>
      controller != oldWidget.controller;
}