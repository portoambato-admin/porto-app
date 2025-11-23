import 'package:flutter/material.dart';
import 'package:app_porto/ui/components/breadcrumbs.dart';
import '../../presentation/admin_shell.dart';
import '_hub_guard.dart';
import 'package:app_porto/features/admin/sections/reportes_pagos_screen.dart';

/// Hub exclusivo para REPORTES
class ReportesHubScreen extends StatelessWidget {
  const ReportesHubScreen({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return HubGuard(
      access: HubAccess.adminOnly,
      builder: () => AdminShell(
        // 👈 MUY IMPORTANTE: aquí debe ir `reportes`, no `sistema`
        current: AdminHub.reportes,
        crumbs: const [Crumb('Admin'), Crumb('Reportes')],
        // Si no se pasa child, mostramos por defecto la pantalla de reportes
        child: child ?? const ReportesPagosScreen(),
      ),
    );
  }
}
