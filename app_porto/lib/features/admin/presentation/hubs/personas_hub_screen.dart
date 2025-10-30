// lib/features/admin/presentation/hubs/personas_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:app_porto/ui/components/breadcrumbs.dart';
import '../../presentation/admin_shell.dart';
import '_hub_guard.dart';
import 'package:app_porto/core/constants/route_names.dart';

class PersonasHubScreen extends StatelessWidget {
  const PersonasHubScreen({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return HubGuard(
      access: HubAccess.adminOnly,
      builder: () => AdminShell(
        current: AdminHub.personas,
        crumbs: const [Crumb('Admin'), Crumb('Personas')],
        child: child ?? const _PersonasLanding(),
      ),
    );
  }
}

class _PersonasLanding extends StatelessWidget {
  const _PersonasLanding();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Usuarios'),
          subtitle: const Text('Cuentas, roles asignados y estado'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, RouteNames.adminPersonasUsuarios),
        ),
        ListTile(
          leading: const Icon(Icons.school_outlined),
          title: const Text('Profesores'),
          subtitle: const Text('Altas, bajas y asignaciones'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, RouteNames.adminPersonasProfesores),
        ),
        ListTile(
          leading: const Icon(Icons.security),
          title: const Text('Roles y permisos'),
          subtitle: const Text('Definir permisos por módulo'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, RouteNames.adminPersonasRoles),
        ),
      ],
    );
  }
}
