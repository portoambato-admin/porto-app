// lib/features/admin/presentation/admin_shell.dart
import 'package:flutter/material.dart';
import 'package:app_porto/core/state/auth_state.dart';
import 'package:app_porto/ui/components/breakpoints.dart';
import 'package:app_porto/ui/components/breadcrumbs.dart';
// Compatibilidad con la firma anterior (AdminSection)
import 'widgets/admin_section_tabs.dart' show AdminSection;

/// Hubs principales del panel
enum AdminHub { personas, academia, finanzas, sistema }

extension _HubMeta on AdminHub {
  String get label {
    switch (this) {
      case AdminHub.personas: return 'Personas';
      case AdminHub.academia: return 'Academia';
      case AdminHub.finanzas: return 'Finanzas';
      case AdminHub.sistema:  return 'Sistema';
    }
  }

  IconData get icon {
    switch (this) {
      case AdminHub.personas: return Icons.groups_2_outlined;
      case AdminHub.academia: return Icons.school_outlined;
      case AdminHub.finanzas: return Icons.payments_outlined;
      case AdminHub.sistema:  return Icons.settings_suggest_outlined;
    }
  }

  String get route {
    switch (this) {
      case AdminHub.personas: return '/admin/personas';
      case AdminHub.academia: return '/admin/academia';
      case AdminHub.finanzas: return '/admin/finanzas';
      case AdminHub.sistema:  return '/admin/sistema';
    }
  }
}

/// Shell base con NavigationRail/Drawer + AppBar (breadcrumbs + búsqueda) + slot
class AdminShell extends StatefulWidget {
  // —— API nueva
  final AdminHub current;
  final List<Crumb> crumbs;
  final Widget child;
  final ValueChanged<String>? onSearch;
  final List<Widget>? actions;
  final Widget? fab;
  final PreferredSizeWidget? bottomExtra;

  /// NUEVO: centralización
  final double? maxContentWidth;         // si es null aplica heurística por breakpoint
  final EdgeInsetsGeometry? contentPadding;
  final bool centerBottomExtra;          // centra el bottom (p.ej. TabBar)

  const AdminShell({
    super.key,
    required this.current,
    required this.crumbs,
    required this.child,
    this.onSearch,
    this.actions,
    this.fab,
    this.bottomExtra,
    this.maxContentWidth,
    this.contentPadding,
    this.centerBottomExtra = true,
  });

  // ============================================================
  // 🔄 Compatibilidad firma antigua: AdminShell.legacy(...)
  // Permite seguir usando AdminSection y title como antes.
  // ============================================================
  factory AdminShell.legacy({
    Key? key,
    required AdminSection section,
    String? title,
    required Widget child,
    ValueChanged<String>? onSearch,
    List<Widget>? actions,
    Widget? fab,
    PreferredSizeWidget? bottomExtra,
    double? maxContentWidth,
    EdgeInsetsGeometry? contentPadding,
    bool centerBottomExtra = true,
  }) {
    final hub = _hubFromSection(section);
    final crumbs = <Crumb>[
      const Crumb('Admin'),
      Crumb(title ?? hub.label),
    ];
    return AdminShell(
      key: key,
      current: hub,
      crumbs: crumbs,
      child: child,
      onSearch: onSearch,
      actions: actions,
      fab: fab,
      bottomExtra: bottomExtra,
      maxContentWidth: maxContentWidth,
      contentPadding: contentPadding,
      centerBottomExtra: centerBottomExtra,
    );
  }

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final _searchCtl = TextEditingController();

  List<AdminHub> _allowedHubsForRole(int? roleId) {
    // 1=Admin, 2=Teacher, 3=Padre (según tu AuthState actual)
    if (roleId == 2) {
      return const [AdminHub.academia];
    }
    return const [AdminHub.personas, AdminHub.academia, AdminHub.finanzas, AdminHub.sistema];
  }

  void _navigate(AdminHub hub) {
    // En PASO 1 aún no definimos rutas; evitamos crash si faltan
    try {
      Navigator.of(context).pushNamed(hub.route);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las rutas de hubs se activan en el PASO 2')),
      );
    }
  }

  Widget _buildSearch(BuildContext context) {
    final onSearch = widget.onSearch;
    if (context.isMobile) {
      return IconButton(
        tooltip: 'Buscar',
        onPressed: onSearch == null
            ? null
            : () async {
                final text = await showDialog<String>(
                  context: context,
                  builder: (_) {
                    final controller = TextEditingController();
                    return AlertDialog(
                      title: const Text('Buscar'),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(hintText: 'Escribe para buscar'),
                        onSubmitted: (v) => Navigator.pop(context, v),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                        FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Buscar')),
                      ],
                    );
                  },
                );
                if (text != null && text.trim().isNotEmpty) onSearch(text.trim());
              },
        icon: const Icon(Icons.search),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: TextField(
        controller: _searchCtl,
        textInputAction: TextInputAction.search,
        onSubmitted: onSearch,
        decoration: const InputDecoration(
          hintText: 'Buscar…',
          prefixIcon: Icon(Icons.search),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  double _defaultMaxWidth(BuildContext context) {
    if (context.isDesktop) return 1200;
    if (context.isTablet) return 1000;
    return double.infinity; // móvil: ocupa todo
    }

  PreferredSizeWidget? _maybeCenteredBottom(PreferredSizeWidget? bottom) {
    if (bottom == null) return null;
    if (!widget.centerBottomExtra) return bottom;
    // Envolvemos en PreferredSize para mantener la altura del TabBar u otro widget
    return PreferredSize(
      preferredSize: bottom.preferredSize,
      child: Align(alignment: Alignment.center, child: bottom),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final roleId = auth.roleId; // getter real de tu AuthState
    final hubs = _allowedHubsForRole(roleId);

    // Si el hub actual no es permitido, cae al primero visible
    final curr = hubs.contains(widget.current) ? widget.current : hubs.first;
    final selectedIndex = hubs.indexOf(curr);

    final rail = NavigationRail(
      destinations: [
        for (final h in hubs)
          NavigationRailDestination(
            icon: Icon(h.icon),
            selectedIcon: Icon(h.icon),
            label: Text(h.label),
          ),
      ],
      selectedIndex: selectedIndex,
      labelType: context.isDesktop ? NavigationRailLabelType.none : NavigationRailLabelType.selected,
      extended: context.isDesktop, // expandido en desktop
      onDestinationSelected: (i) => _navigate(hubs[i]),
    );

    final drawerList = ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings_outlined, size: 28),
              const SizedBox(width: 10),
              Text('Panel administrativo', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        for (final h in hubs)
          ListTile(
            leading: Icon(h.icon),
            title: Text(h.label),
            selected: h == curr,
            onTap: () {
              Navigator.pop(context);
              _navigate(h);
            },
          ),
      ],
    );

    final appBar = AppBar(
      titleSpacing: 0,
      title: Breadcrumbs(items: widget.crumbs),
      actions: [
        if (!context.isMobile) const SizedBox(width: 12),
        _buildSearch(context),
        if (widget.actions != null) ...widget.actions!,
        const SizedBox(width: 8),
      ],
      bottom: _maybeCenteredBottom(widget.bottomExtra),
    );

    // —— CENTRALIZACIÓN DEL CONTENIDO —— //
    final maxW = widget.maxContentWidth ?? _defaultMaxWidth(context);
    final padding = widget.contentPadding ?? const EdgeInsets.all(12);

    final body = Row(
      children: [
        if (!context.isMobile) rail,
        if (!context.isMobile) const VerticalDivider(width: 1),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: Padding(
                padding: padding,
                child: widget.child,
              ),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: appBar,
      drawer: context.isMobile ? Drawer(child: drawerList) : null,
      body: body,
      floatingActionButton: widget.fab,
    );
  }
}

// ===== Helpers de compatibilidad =====

/// Mapeo AdminSection (viejo) → AdminHub (nuevo)
AdminHub _hubFromSection(AdminSection s) {
  switch (s) {
    case AdminSection.usuarios:
    case AdminSection.profesores:
      return AdminHub.personas;

    case AdminSection.pagos:
      return AdminHub.finanzas;

    case AdminSection.config:
      return AdminHub.sistema;

    case AdminSection.categorias:
    case AdminSection.subcategorias:
    case AdminSection.asistencias:
    
    return AdminHub.academia;
  }
}
