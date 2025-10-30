// lib/features/admin/presentation/hubs/_hub_guard.dart
import 'package:flutter/material.dart';
import 'package:app_porto/core/state/auth_state.dart';
import 'package:app_porto/core/constants/route_names.dart';

typedef HubChildBuilder = Widget Function();

enum HubAccess { adminOnly, adminAndTeacher }

class HubGuard extends StatelessWidget {
  final HubAccess access;
  final HubChildBuilder builder;

  const HubGuard({super.key, required this.access, required this.builder});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final isAdmin = auth.isAdmin;
    final isTeacher = auth.isTeacher;

    final allowed = switch (access) {
      HubAccess.adminOnly       => isAdmin,
      HubAccess.adminAndTeacher => isAdmin || isTeacher,
    };

    if (!allowed) {
      // Redirección suave a /admin/academia (único permitido para Teacher)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, RouteNames.adminAcademia);
      });
      return const Scaffold(body: SizedBox.shrink());
    }
    return builder();
  }
}
