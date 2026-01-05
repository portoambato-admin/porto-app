// lib/features/admin/presentation/hubs/dashboard_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:app_porto/ui/components/breadcrumbs.dart';

import '../../presentation/admin_shell.dart';
import '_hub_guard.dart';

// Reutiliza el widget existente del dashboard (ya implementado)
import '../widgets/admin_dashboard_widget.dart';

class DashboardHubScreen extends StatelessWidget {
  const DashboardHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HubGuard(
      access: HubAccess.adminOnly,
      builder: () => AdminShell(
        current: AdminHub.dashboard,
        crumbs: const [Crumb('Admin'), Crumb('Dashboard')],
        child: const _DashboardBody(),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    // AdminShell no incluye scroll por defecto.
    // Envolvemos en ListView para evitar overflow vertical.
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: const [
        AdminDashboardWidget(),
      ],
    );
  }
}
