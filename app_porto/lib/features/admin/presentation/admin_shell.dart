// lib/features/admin/presentation/admin_shell.dart
import 'package:flutter/material.dart';
import 'package:app_porto/core/state/auth_state.dart';
import 'package:app_porto/app/app_scope.dart';
import 'package:app_porto/core/constants/route_names.dart';
import 'package:app_porto/ui/components/breakpoints.dart';
import 'package:app_porto/ui/components/breadcrumbs.dart';
// Compatibilidad con la firma anterior (AdminSection)
import 'widgets/admin_section_tabs.dart' show AdminSection;

/// Hubs principales del panel
enum AdminHub { dashboard, personas, academia, finanzas, reportes, sistema }

extension _HubMeta on AdminHub {
  String get label {
    switch (this) {
      case AdminHub.dashboard:
        return 'Dashboard';
      case AdminHub.personas:
        return 'Personas';
      case AdminHub.academia:
        return 'Academia';
      case AdminHub.finanzas:
        return 'Finanzas';
      case AdminHub.reportes:
        return 'Reportes';
      case AdminHub.sistema:
        return 'Sistema';
    }
  }

  IconData get icon {
    switch (this) {
      case AdminHub.dashboard:
        return Icons.dashboard_outlined;
      case AdminHub.personas:
        return Icons.groups_2_outlined;
      case AdminHub.academia:
        return Icons.school_outlined;
      case AdminHub.finanzas:
        return Icons.payments_outlined;
      case AdminHub.reportes:
        return Icons.data_thresholding_outlined;
      case AdminHub.sistema:
        return Icons.settings_suggest_outlined;
    }
  }

  String get route {
    switch (this) {
      case AdminHub.dashboard:
        return '/admin/dashboard';
      case AdminHub.personas:
        return '/admin/personas';
      case AdminHub.academia:
        return '/admin/academia';
      case AdminHub.finanzas:
        return '/admin/finanzas';
      case AdminHub.reportes:
        return '/admin/reportes';
      case AdminHub.sistema:
        return '/admin/sistema';
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
  final double? maxContentWidth; // si es null aplica heurística por breakpoint
  final EdgeInsetsGeometry? contentPadding;
  final bool centerBottomExtra; // centra el bottom (p.ej. TabBar)

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
      // Profesor: solo ve Academia
      return const [AdminHub.academia];
    }

    // Admin (y otros roles con acceso completo)
    return const [
      AdminHub.dashboard,
      AdminHub.personas,
      AdminHub.academia,
      AdminHub.finanzas,
      AdminHub.reportes, // ← Reportes antes de Sistema
      AdminHub.sistema,
    ];
  }

  void _navigate(AdminHub hub) {
    Navigator.of(context).pushNamed(hub.route);
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
                        decoration: const InputDecoration(
                          hintText: 'Escribe para buscar',
                        ),
                        onSubmitted: (v) => Navigator.pop(context, v),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.pop(context, controller.text.trim()),
                          child: const Text('Buscar'),
                        ),
                      ],
                    );
                  },
                );
                if (text != null && text.trim().isNotEmpty) {
                  onSearch(text.trim());
                }
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

    final userName = _safeUserField(auth.user, 'nombre', fallback: 'Usuario');
    final userEmail = _safeUserField(auth.user, 'correo', fallback: '');
    final avatarUrl = _safeUserField(auth.user, 'avatar_url', fallback: '');

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
      labelType: context.isDesktop
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.selected,
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
              Text(
                'Panel administrativo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
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
        if (widget.actions != null) ...widget.actions!,
        _AdminAccountMenu(
          userName: userName,
          userEmail: userEmail,
          avatarUrl: avatarUrl,
          onSignOut: () async {
            try {
              await auth.signOut();
            } catch (_) {}
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                RouteNames.root,
                (r) => false,
              );
            }
          },
        ),
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


String _safeUserField(Map<String, dynamic>? user, String field, {String fallback = ''}) {
  if (user == null) return fallback;
  final v = user[field];
  final s = v?.toString() ?? '';
  if (s.trim().isEmpty) return fallback;
  return s;
}

class _AdminAccountMenu extends StatelessWidget {
  const _AdminAccountMenu({
    required this.userName,
    required this.userEmail,
    required this.avatarUrl,
    required this.onSignOut,
  });

  final String userName;
  final String userEmail;
  final String avatarUrl;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return PopupMenuButton<int>(
      tooltip: 'Cuenta',
      position: PopupMenuPosition.under,
      onSelected: (v) async {
        switch (v) {
          case 1:
            Navigator.of(context).pushNamed(RouteNames.perfil);
            break;
          case 2:
            Navigator.of(context).pushNamed(RouteNames.notificaciones);
            break;
          case 3:
            Navigator.of(context).pushNamed(RouteNames.adminDashboard);
            break;
          case 99:
            await onSignOut();
            break;
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 0,
          enabled: false,
          child: Row(
            children: [
              _AvatarCircle(url: avatarUrl, radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (userEmail.trim().isNotEmpty)
                      Text(
                        userEmail,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 1,
          child: ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Perfil'),
          ),
        ),
        PopupMenuItem(
          value: 2,
          child: _NotificacionesMenuEntry(),
        ),
        const PopupMenuItem(
          value: 3,
          child: ListTile(
            leading: Icon(Icons.dashboard_outlined),
            title: Text('Dashboard'),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 99,
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Cerrar sesión'),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AvatarCircle(url: avatarUrl, radius: 16),
            if (!isMobile) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(width: 6),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class _NotificacionesMenuEntry extends StatelessWidget {
  const _NotificacionesMenuEntry();

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<int>(
      future: scope.notificaciones.unreadCount(),
      builder: (context, snap) {
        final unread = (snap.data ?? 0);

        return ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('Notificaciones'),
          trailing: unread > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: cs.surface, width: 1),
                  ),
                  constraints: const BoxConstraints(minWidth: 18),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({this.url = '', this.radius = 16});
  final String url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url.trim().isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundImage: hasUrl ? NetworkImage(url) : null,
      child: !hasUrl ? const Icon(Icons.person, size: 16) : null,
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

    case AdminSection.categorias:
    case AdminSection.subcategorias:
    case AdminSection.asistencias:
      return AdminHub.academia;

    case AdminSection.pagos:
      return AdminHub.finanzas;

    case AdminSection.config:
      return AdminHub.sistema;
  }
}
