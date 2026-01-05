import 'package:flutter/material.dart';
import '../../../../core/state/auth_state.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../ui/components/panel_hub_card.dart';

import '../widgets/admin_dashboard_widget.dart';

class PanelScreen extends StatelessWidget {
  const PanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final isAdmin = auth.isAdmin;
    final isTeacher = auth.isTeacher;

    // Solo “Academia” para teacher; Admin ve todo
    final showPersonas = isAdmin;
    final showFinanzas = isAdmin;
    final showSistema  = isAdmin;

    // Dashboard (siempre arriba)
    final List<Widget> items = [const AdminDashboardWidget()];

    if (showPersonas) {
      items.add(
        PanelHubCard(
          icon: Icons.groups_2_outlined,
          title: 'Personas',
          options: [
            HubOption(
              icon: Icons.person_outline,
              label: 'Usuarios',
              onTap: () => Navigator.pushNamed(context, RouteNames.adminUsuarios),
            ),
            HubOption(
              icon: Icons.school_outlined,
              label: 'Profesores',
              onTap: () => Navigator.pushNamed(context, RouteNames.adminProfesores),
            ),
            HubOption(
              icon: Icons.shield_outlined,
              label: 'Roles',
              onTap: () => Navigator.pushNamed(context, RouteNames.adminRoles),
            ),
            // Roles/Permisos lo integramos cuando exista la ruta real (evitar opciones muertas)
          ],
        ),
      );
    }

    // Academia: Categorías, Subcategorías, Estudiantes, Asistencias,
    items.add(
      PanelHubCard(
        icon: Icons.school_outlined,
        title: 'Academia',
        initiallyExpanded: isTeacher, // cómodo para teacher
        options: [
          HubOption(
            icon: Icons.category_outlined,
            label: 'Categorías',
            onTap: () => Navigator.pushNamed(context, RouteNames.adminCategorias),
          ),
          HubOption(
            icon: Icons.folder_copy_outlined,
            label: 'Subcategorías',
            onTap: () => Navigator.pushNamed(context, RouteNames.adminSubcategorias),
          ),
          HubOption(
            icon: Icons.group_outlined,
            label: 'Estudiantes',
            onTap: () => Navigator.pushNamed(context, RouteNames.adminEstudiantes),
          ),
          HubOption(
            icon: Icons.fact_check_outlined,
            label: 'Asistencias',
            onTap: () => Navigator.pushNamed(context, RouteNames.adminAsistencias),
          ),
         
        ],
      ),
    );

    if (showFinanzas) {
      items.add(
        PanelHubCard(
          icon: Icons.payments_outlined,
          title: 'Finanzas',
          options: [
            HubOption(
              icon: Icons.receipt_long_outlined,
              label: 'Pagos',
              onTap: () => Navigator.pushNamed(context, RouteNames.adminPagos),
            ),
            // Agregamos Mensualidades/Ventas/Reportes cuando definamos rutas reales
          ],
        ),
      );
    }

    if (showSistema) {
      items.add(
        PanelHubCard(
          icon: Icons.data_thresholding_outlined,
          title: 'Reportes',
          options: [
            HubOption(
              icon: Icons.desktop_mac_sharp,
              label: 'Reportes',
              onTap: () => Navigator.pushNamed(context, RouteNames.adminReportes),
            ),
            // Auditoría/Multimedia cuando exista ruta real
          ],
        ),
      );
    }

     if (showSistema) {
      items.add(
        PanelHubCard(
          icon: Icons.settings_suggest_outlined,
          title: 'Sistema',
          options: [
            HubOption(
              icon: Icons.settings_outlined,
              label: 'Config',
              onTap: () => Navigator.pushNamed(context, RouteNames.adminConfig),
            ),
            // Auditoría/Multimedia cuando exista ruta real
          ],
        ),
      );
    }

    // —— Layout centrado del panel —— //
    // No usamos AdminShell aquí a propósito: quieres SOLO el panel centralizado.
    return Scaffold(
      appBar: AppBar(title: const Text('Panel')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              itemBuilder: (_, i) => items[i],
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: items.length,
            ),
          ),
        ),
      ),
    );
  }
}
