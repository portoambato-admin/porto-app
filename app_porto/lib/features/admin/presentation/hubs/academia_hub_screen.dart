import 'package:flutter/material.dart';
import 'package:app_porto/ui/components/breadcrumbs.dart';
import '../../presentation/admin_shell.dart';
import '_hub_guard.dart';
import 'package:app_porto/core/constants/route_names.dart';

class AcademiaHubScreen extends StatelessWidget {
  const AcademiaHubScreen({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return HubGuard(
      access: HubAccess.adminAndTeacher,
      builder: () => AdminShell(
        current: AdminHub.academia,
        crumbs: const [Crumb('Admin'), Crumb('Academia')],
        child: child ?? _AcademiaLanding(),
      ),
    );
  }
}

class _AcademiaLanding extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.category_outlined),
          title: const Text('Categorías'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, RouteNames.adminAcademiaCategorias),
        ),
        ListTile(
          leading: const Icon(Icons.folder_copy_outlined),
          title: const Text('Subcategorías'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, RouteNames.adminAcademiaSubcategorias),
        ),
        ListTile(
          leading: const Icon(Icons.group_outlined),
          title: const Text('Estudiantes'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, RouteNames.adminAcademiaEstudiantes),
        ),
        ListTile(
          leading: const Icon(Icons.fact_check_outlined),
          title: const Text('Asistencias'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, RouteNames.adminAcademiaAsistencias),
        ),
        ListTile(
          leading: const Icon(Icons.checklist_rtl_outlined),
          title: const Text('Evaluaciones'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, RouteNames.adminAcademiaEvaluaciones),
        ),
      ],
    );
  }
}
