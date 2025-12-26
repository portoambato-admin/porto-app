import 'package:flutter/material.dart';
import '../../../../core/constants/route_names.dart';

class ProfesorAcademiaHubScreen extends StatelessWidget {
  final Widget? child;
  const ProfesorAcademiaHubScreen({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isSmall = mq.size.width < 900;
    final cs = Theme.of(context).colorScheme;

    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    // -------------------------
    // Helpers de estilo (como AdminEstudiantesScreen)
    // -------------------------
    BoxDecoration shellDecoration() => BoxDecoration(
          color: cs.surface,
          border: Border(
            right: BorderSide(color: cs.outlineVariant.withOpacity(0.35)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        );

    ShapeBorder cardShape({bool selected = false}) => RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? cs.primary : cs.outlineVariant.withOpacity(0.45),
            width: selected ? 1.6 : 1,
          ),
        );

    Widget sectionTitle(String text) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      );
    }

    Widget menuItem({
      required IconData icon,
      required String title,
      required String route,
      bool asDrawer = false,
    }) {
      final selected = currentRoute == route;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          selected: selected,
          selectedTileColor: cs.primaryContainer.withOpacity(0.35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onTap: () {
            if (asDrawer) Navigator.of(context).pop();
            if (currentRoute != route) {
              Navigator.of(context).pushNamed(route);
            }
          },
        ),
      );
    }

    Widget menu({bool asDrawer = false}) {
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            sectionTitle('Académico'),
            menuItem(
              icon: Icons.category,
              title: 'Categorías',
              route: RouteNames.profesorAcademiaCategorias,
              asDrawer: asDrawer,
            ),
            menuItem(
              icon: Icons.account_tree,
              title: 'Subcategorías',
              route: RouteNames.profesorAcademiaSubcategorias,
              asDrawer: asDrawer,
            ),
            menuItem(
              icon: Icons.groups,
              title: 'Estudiantes',
              route: RouteNames.profesorAcademiaEstudiantes,
              asDrawer: asDrawer,
            ),
            menuItem(
              icon: Icons.check_circle,
              title: 'Asistencias',
              route: RouteNames.profesorAcademiaAsistencias,
              asDrawer: asDrawer,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(height: 0),
            ),
            sectionTitle('Sistema'),
            menuItem(
              icon: Icons.analytics,
              title: 'Reportes',
              route: RouteNames.profesorReportes,
              asDrawer: asDrawer,
            ),
            menuItem(
              icon: Icons.settings,
              title: 'Config',
              route: RouteNames.profesorConfig,
              asDrawer: asDrawer,
            ),
          ],
        ),
      );
    }

    // -------------------------
    // Dashboard (sin redundancia)
    // - Móvil: accesos rápidos
    // - Desktop: solo mensaje
    // -------------------------
    Widget dashboard() {
      // Card tipo “quick access” estilo AdminEstudiantesScreen
      Widget quickCard({
        required IconData icon,
        required String title,
        required String subtitle,
        required String route,
      }) {
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: cardShape(),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).pushNamed(route),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: cs.surfaceContainerHighest.withOpacity(0.55),
                    child: Icon(icon, color: cs.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                            )),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        );
      }

      // Móvil: mostrar accesos rápidos + botón abrir menú
      if (isSmall) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    elevation: 0,
                    shape: cardShape(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Académico (Profesor)',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'En móvil, abre el menú tocando el ícono ☰ o usa estos accesos rápidos.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          Builder(
                            builder: (ctx) => FilledButton.icon(
                              onPressed: () => Scaffold.of(ctx).openDrawer(),
                              icon: const Icon(Icons.menu),
                              label: const Text('Abrir menú'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  quickCard(
                    icon: Icons.groups,
                    title: 'Estudiantes',
                    subtitle: 'Ver listado y entrar al detalle',
                    route: RouteNames.profesorAcademiaEstudiantes,
                  ),
                  quickCard(
                    icon: Icons.check_circle,
                    title: 'Asistencias',
                    subtitle: 'Registrar y revisar asistencias',
                    route: RouteNames.profesorAcademiaAsistencias,
                  ),
                  quickCard(
                    icon: Icons.category,
                    title: 'Categorías',
                    subtitle: 'Ver categorías disponibles',
                    route: RouteNames.profesorAcademiaCategorias,
                  ),
                  quickCard(
                    icon: Icons.account_tree,
                    title: 'Subcategorías',
                    subtitle: 'Ver subcategorías y estudiantes',
                    route: RouteNames.profesorAcademiaSubcategorias,
                  ),
                  quickCard(
                    icon: Icons.analytics,
                    title: 'Reportes',
                    subtitle: 'Reportes limitados para profesor',
                    route: RouteNames.profesorReportes,
                  ),
                  quickCard(
                    icon: Icons.settings,
                    title: 'Config',
                    subtitle: 'Configuración de la app',
                    route: RouteNames.profesorConfig,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Desktop: NO duplicamos el menú lateral
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 0,
              shape: cardShape(),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_outlined,
                        size: 56, color: cs.primary.withOpacity(0.85)),
                    const SizedBox(height: 12),
                    const Text(
                      'Académico (Profesor)',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selecciona una opción desde el menú lateral.',
                      style: TextStyle(color: cs.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final content = child ?? dashboard();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text(
          'Académico',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: cs.surface,
        elevation: 0.6,
        shadowColor: Colors.black12,
      ),
      drawer: isSmall ? Drawer(child: menu(asDrawer: true)) : null,
      body: Row(
        children: [
          if (!isSmall)
            Container(
              width: 280,
              decoration: shellDecoration(),
              child: menu(),
            ),
          if (!isSmall)
            VerticalDivider(width: 0, color: cs.outlineVariant.withOpacity(0.4)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: cs.surface,
                  child: content,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
