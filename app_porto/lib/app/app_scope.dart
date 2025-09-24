import 'package:flutter/widgets.dart';
import '../core/network/http_client.dart';
import '../core/services/session_token_provider.dart';
import '../features/auth/data/auth_repository.dart';

class AppScope extends InheritedWidget {
  final HttpClient http;
  final AuthRepository auth;

  AppScope._({required this.http, required this.auth, required super.child});

  factory AppScope({required Widget child}) {
    final http = HttpClient(tokenProvider: SessionTokenProvider());
    final auth = AuthRepository(http);
    return AppScope._(http: http, auth: auth, child: child);
  }

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}
