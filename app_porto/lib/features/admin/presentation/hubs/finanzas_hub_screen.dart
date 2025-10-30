import 'package:flutter/material.dart';
import 'package:app_porto/ui/components/breadcrumbs.dart';
import '../../presentation/admin_shell.dart';
import '_hub_guard.dart';
import 'package:app_porto/core/constants/route_names.dart';

class FinanzasHubScreen extends StatelessWidget {
  const FinanzasHubScreen({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return HubGuard(
      access: HubAccess.adminOnly,
      builder: () => AdminShell(
        current: AdminHub.finanzas,
        crumbs: const [Crumb('Admin'), Crumb('Finanzas')],
        child: child ?? _FinanzasLanding(),
      ),
    );
  }
}

class _FinanzasLanding extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: const Text('Pagos'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, RouteNames.adminFinanzasPagos),
        ),
      ],
    );
  }
}
