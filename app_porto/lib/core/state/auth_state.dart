// lib/core/state/auth_state.dart
import 'dart:convert';
import 'package:flutter/widgets.dart';

import '../services/session.dart';
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

  Future<void> load() async {
    try {
      _token = await Session.getToken();
      if (_token == null || _token!.isEmpty) {
        _user = null;
        notifyListeners();
        return;
      }

      final cached = await Session.getUser();
      if (cached != null) {
        _user = Map<String, dynamic>.from(cached);
        notifyListeners();
        return;
      }

      try {
        final res = await _http.get(Endpoints.me, headers: const {});
        if (res is Map && res['usuario'] is Map) {
          _user = Map<String, dynamic>.from(res['usuario'] as Map);
        } else {
          _user = Map<String, dynamic>.from(res as Map);
        }
        await Session.saveAuth(token: _token!, userJson: jsonEncode(_user));
      } catch (e) {
        await Session.clear();
        _token = null;
        _user = null;
      }
    } catch (_) {
      _token = null;
      _user = null;
    } finally {
      notifyListeners();
    }
  }

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

  Future<void> setUser(Map<String, dynamic> u) async {
    _user = Map<String, dynamic>.from(u);
    final t = _token ?? await Session.getToken();
    if (t != null) {
      await Session.saveAuth(token: t, userJson: jsonEncode(_user));
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      if (_token != null) {
        await _http.post(Endpoints.authLogout, body: const {}, headers: const {});
      }
    } catch (_) {}
    await Session.clear();
    _token = null;
    _user = null;
    notifyListeners();
  }
}

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
