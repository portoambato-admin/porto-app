import 'package:flutter/material.dart';
import 'package:app_porto/ui/components/breadcrumbs.dart';
import '../../presentation/admin_shell.dart';
import '_hub_guard.dart';
import 'package:app_porto/core/constants/route_names.dart';

class SistemaHubScreen extends StatelessWidget {
  const SistemaHubScreen({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return HubGuard(
      access: HubAccess.adminOnly,
      builder: () => AdminShell(
        current: AdminHub.sistema,
        crumbs: const [Crumb('Admin'), Crumb('Sistema')],
        child: child ?? _SistemaLanding(),
      ),
    );
  }
}

class _SistemaLanding extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('Config'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, RouteNames.adminSistemaConfig),
        ),
      ],
    );
  }
}
