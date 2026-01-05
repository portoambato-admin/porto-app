import 'package:flutter/material.dart';
import '../../core/state/auth_state.dart';
import '../../core/rbac/permission_gate.dart' show Permissions;
import '../../core/constants/route_names.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  const TopNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  void _navAndClose(BuildContext ctx, String route, {bool useRoot = true}) {
    Navigator.of(ctx).pop();
    if (useRoot) {
      Navigator.of(ctx, rootNavigator: true).pushNamed(route);
    } else {
      Navigator.of(ctx).pushNamed(route);
    }
  }

  void _goAuth(BuildContext context, {String? redirectTo}) {
    final current = redirectTo ?? (ModalRoute.of(context)?.settings.name ?? '/');
    Navigator.pushNamed(context, RouteNames.auth, arguments: {'redirectTo': current});
  }

  // ✅ Helper para obtener valores de forma segura
  String _getUserField(Map<String, dynamic>? user, String field, {String defaultValue = ''}) {
    if (user == null) return defaultValue;
    final value = user[field];
    return value?.toString() ?? defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 900;
    final currentRoute = ModalRoute.of(context)?.settings.name ?? RouteNames.root;

    final auth = AuthScope.of(context);
    final user = auth.user;
    final isLogged = auth.isLoggedIn;

    // =========================================================================
    // ✅ Dashboard por rol (NO usar /panel para profesor/representante)
    // =========================================================================
    bool showDashboard = false;
    String dashboardLabel = '';
    String dashboardRoute = '';
    IconData dashboardIcon = Icons.dashboard_customize;

    // Fallback por id_rol (tu modelo actual)
    if (isLogged) {
      if (auth.isAdmin) {
        showDashboard = true;
        dashboardLabel = 'Admin';
        dashboardRoute = RouteNames.adminDashboard;
        dashboardIcon = Icons.dashboard;
      } else if (auth.isTeacher) {
        showDashboard = true;
        dashboardLabel = 'Académico';
        dashboardRoute = RouteNames.profesorRoot;
        dashboardIcon = Icons.school;
      } else if (auth.isParent) {
        showDashboard = true;
        dashboardLabel = 'Mensualidades';
        dashboardRoute = RouteNames.representanteMensualidades;
        dashboardIcon = Icons.payments;
      }
    }

    // Override opcional por PermissionsHost (si existe)
    // Mantengo tu lógica, pero la traduzco a dashboards correctos.
    try {
      final perms = Permissions.of(context);

      final isAdminByPerms = perms.hasAnyRole(['admin', 'ADMIN']);
      final isTeacherByPerms = perms.hasAnyRole(['staff', 'teacher', 'profesor', 'PROFESOR']);
      final isParentByPerms = perms.hasAnyRole(['parent', 'representante', 'REPRESENTANTE']);

      // Si hay permisos concretos de módulos, también ayudan:
      final canReadAdminStuff = perms.hasAny([
        'usuarios.read',
        'roles.read',
        'categorias.read',
        'estudiantes.read',
        'reportes.read',
      ]);

      final canReadMensualidades = perms.hasAny([
        'mensualidades.read',
        'pagos.read',
      ]);

      if (isLogged) {
        if (isAdminByPerms || canReadAdminStuff) {
          showDashboard = true;
          dashboardLabel = 'Dashboard';
          dashboardRoute = RouteNames.adminDashboard;
          dashboardIcon = Icons.dashboard;
        } else if (isTeacherByPerms) {
          showDashboard = true;
          dashboardLabel = 'Académico';
          dashboardRoute = RouteNames.profesorRoot;
          dashboardIcon = Icons.school;
        } else if (isParentByPerms || canReadMensualidades) {
          showDashboard = true;
          dashboardLabel = 'Mensualidades';
          dashboardRoute = RouteNames.representanteMensualidades;
          dashboardIcon = Icons.payments;
        }
      }
    } catch (_) {
      // Si el PermissionsHost no está montado, usamos el fallback por id_rol
    }

    return AppBar(
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.white,
      elevation: 0.5,
      shadowColor: Colors.black12,
      titleSpacing: 0,
      title: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              Image.asset(
                'assets/img/thumbs/banner_thumb.webp',
                height: 42,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.sports_soccer, size: 32),
              ),
              const SizedBox(width: 12),
              const Spacer(),

              if (!isSmall) ...[
                _NavButton(
                  text: 'Inicio',
                  route: RouteNames.root,
                  currentRoute: currentRoute,
                  onPressed: () => Navigator.pushNamed(context, RouteNames.root),
                ),
                _NavButton(
                  text: 'Tienda',
                  route: RouteNames.tienda,
                  currentRoute: currentRoute,
                  onPressed: () => Navigator.pushNamed(context, RouteNames.tienda),
                ),
                _NavButton(
                  text: 'Eventos',
                  route: RouteNames.eventos,
                  currentRoute: currentRoute,
                  onPressed: () => Navigator.pushNamed(context, RouteNames.eventos),
                ),
                _NavButton(
                  text: 'Categorías',
                  route: RouteNames.categorias,
                  currentRoute: currentRoute,
                  onPressed: () => Navigator.pushNamed(context, RouteNames.categorias),
                ),
                _NavButton(
                  text: 'Sponsors',
                  route: RouteNames.beneficios,
                  currentRoute: currentRoute,
                  onPressed: () => Navigator.pushNamed(context, RouteNames.beneficios),
                ),
                _NavButton(
                  text: 'Conócenos',
                  route: RouteNames.conocenos,
                  currentRoute: currentRoute,
                  onPressed: () => Navigator.pushNamed(context, RouteNames.conocenos),
                ),
                const SizedBox(width: 12),

                if (!isLogged)
                  FilledButton(
                    onPressed: () => _goAuth(context, redirectTo: currentRoute),
                    child: const Text('Ingresar'),
                  )
                else
                  _UserMenu(
                    userName: _getUserField(user, 'nombre', defaultValue: 'Usuario'),
                    userEmail: _getUserField(user, 'correo'),
                    avatarUrl: _getUserField(user, 'avatar_url'),
                    showDashboard: showDashboard,
                    dashboardLabel: dashboardLabel,
                    dashboardRoute: dashboardRoute,
                    dashboardIcon: dashboardIcon,
                    onSignOut: () async {
                      await auth.signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          RouteNames.root,
                          (r) => false,
                        );
                      }
                    },
                  ),
              ] else
                IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      showDragHandle: true,
                      builder: (sheetCtx) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text('Inicio'),
                              onTap: () => _navAndClose(sheetCtx, RouteNames.root),
                            ),
                            ListTile(
                              title: const Text('Tienda'),
                              onTap: () => _navAndClose(sheetCtx, RouteNames.tienda),
                            ),
                            ListTile(
                              title: const Text('Eventos'),
                              onTap: () => _navAndClose(sheetCtx, RouteNames.eventos),
                            ),
                            ListTile(
                              title: const Text('Categorías'),
                              onTap: () => _navAndClose(sheetCtx, RouteNames.categorias),
                            ),
                            ListTile(
                              title: const Text('Sponsors'),
                              onTap: () => _navAndClose(sheetCtx, RouteNames.beneficios),
                            ),
                            ListTile(
                              title: const Text('Conócenos'),
                              onTap: () => _navAndClose(sheetCtx, RouteNames.conocenos),
                            ),
                            const Divider(height: 0),

                            if (!isLogged)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: FilledButton(
                                  onPressed: () {
                                    Navigator.of(sheetCtx).pop();
                                    _goAuth(context, redirectTo: currentRoute);
                                  },
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                  child: const Text('Ingresar'),
                                ),
                              )
                            else ...[
                              ListTile(
                                leading: _AvatarCircle(url: _getUserField(user, 'avatar_url')),
                                title: Text(_getUserField(user, 'nombre', defaultValue: 'Usuario')),
                                subtitle: Text(_getUserField(user, 'correo')),
                                onTap: () => _navAndClose(sheetCtx, RouteNames.perfil),
                              ),

                              if (showDashboard)
                                ListTile(
                                  leading: Icon(dashboardIcon),
                                  title: Text(dashboardLabel),
                                  onTap: () => _navAndClose(sheetCtx, dashboardRoute),
                                ),

                              ListTile(
                                leading: const Icon(Icons.logout),
                                title: const Text('Cerrar sesión'),
                                onTap: () async {
                                  Navigator.of(sheetCtx).pop();
                                  await auth.signOut();
                                  if (context.mounted) {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      RouteNames.root,
                                      (r) => false,
                                    );
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String text;
  final String route;
  final String currentRoute;
  final VoidCallback onPressed;

  const _NavButton({
    required this.text,
    required this.route,
    required this.currentRoute,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = currentRoute == route;
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Colors.black87,
        ),
      ),
    );
  }
}

class _UserMenu extends StatelessWidget {
  const _UserMenu({
    required this.userName,
    required this.userEmail,
    required this.avatarUrl,
    required this.showDashboard,
    required this.dashboardLabel,
    required this.dashboardRoute,
    required this.dashboardIcon,
    required this.onSignOut,
  });

  final String userName;
  final String userEmail;
  final String avatarUrl;

  final bool showDashboard;
  final String dashboardLabel;
  final String dashboardRoute;
  final IconData dashboardIcon;

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Cuenta',
      position: PopupMenuPosition.under,
      onSelected: (v) async {
        switch (v) {
          case 1:
            Navigator.pushNamed(context, RouteNames.perfil);
            break;
          case 2:
            if (showDashboard) Navigator.pushNamed(context, dashboardRoute);
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
              _AvatarCircle(url: avatarUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      userEmail,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
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
            leading: Icon(Icons.person),
            title: Text('Perfil'),
          ),
        ),
        if (showDashboard)
          PopupMenuItem(
            value: 2,
            child: ListTile(
              leading: Icon(dashboardIcon),
              title: Text(dashboardLabel),
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
      child: Row(
        children: [
          _AvatarCircle(url: avatarUrl),
          const SizedBox(width: 8),
          Text(userName),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  // ignore: unused_element_parameter
  const _AvatarCircle({this.url = '', this.radius = 16});
  final String url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundImage: hasUrl ? NetworkImage(url) : null,
      child: !hasUrl ? const Icon(Icons.person, size: 16) : null,
    );
  }
}
