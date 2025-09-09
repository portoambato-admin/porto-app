import 'package:flutter/material.dart';
import '../services/session.dart';
import '../services/api_service.dart';

class AuthState extends ChangeNotifier {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _user != null;

  Future<void> load() async {
    _user = await Session.getUser(); // lee de storage
    notifyListeners();
  }

  Future<void> signIn({required String token, required String userJson}) async {
    await Session.saveAuth(token: token, userJson: userJson);
    await load(); // refresca user
  }

  Future<void> signOut() async {
    final t = await Session.getToken();
    if (t != null) { try { await ApiService.logout(t); } catch (_) {} }
    await Session.clear();
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
