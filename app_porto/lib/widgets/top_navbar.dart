import 'package:flutter/material.dart';
import '../state/auth_state.dart';

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
    Navigator.pushNamed(context, '/auth', arguments: {'redirectTo': current});
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 900;
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/';
    final auth = AuthScope.of(context);
    final user = auth.user;
    final isLogged = auth.isLoggedIn;
    final canSeePanel = auth.isAdmin || auth.isTeacher;

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
                    route: '/',
                    currentRoute: currentRoute,
                    onPressed: () => Navigator.pushNamed(context, '/')),
                _NavButton(
                    text: 'Tienda',
                    route: '/tienda',
                    currentRoute: currentRoute,
                    onPressed: () => Navigator.pushNamed(context, '/tienda')),
                _NavButton(
                    text: 'Eventos',
                    route: '/eventos',
                    currentRoute: currentRoute,
                    onPressed: () => Navigator.pushNamed(context, '/eventos')),
                _NavButton(
                    text: 'Categorías',
                    route: '/categorias',
                    currentRoute: currentRoute,
                    onPressed: () =>
                        Navigator.pushNamed(context, '/categorias')),
                _NavButton(
                    text: 'Sponsors',
                    route: '/beneficios',
                    currentRoute: currentRoute,
                    onPressed: () =>
                        Navigator.pushNamed(context, '/beneficios')),
                _NavButton(
                    text: 'Conócenos',
                    route: '/conocenos',
                    currentRoute: currentRoute,
                    onPressed: () =>
                        Navigator.pushNamed(context, '/conocenos')),
                const SizedBox(width: 12),
                if (!isLogged)
                  FilledButton(
                      onPressed: () =>
                          _goAuth(context, redirectTo: currentRoute),
                      child: const Text('Ingresar'))
                else
                  _UserMenu(
                    user: user!,
                    canSeePanel: canSeePanel,
                    onSignOut: () async {
                      await auth.signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/', (r) => false);
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
                                onTap: () => _navAndClose(sheetCtx, '/')),
                            ListTile(
                                title: const Text('Tienda'),
                                onTap: () => _navAndClose(sheetCtx, '/tienda')),
                            ListTile(
                                title: const Text('Eventos'),
                                onTap: () =>
                                    _navAndClose(sheetCtx, '/eventos')),
                            ListTile(
                                title: const Text('Categorías'),
                                onTap: () =>
                                    _navAndClose(sheetCtx, '/categorias')),
                            ListTile(
                                title: const Text('Sponsors'),
                                onTap: () =>
                                    _navAndClose(sheetCtx, '/beneficios')),
                            ListTile(
                                title: const Text('Conócenos'),
                                onTap: () =>
                                    _navAndClose(sheetCtx, '/conocenos')),
                            const Divider(height: 0),
                            if (!isLogged)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: FilledButton(
                                  onPressed: () {
                                    Navigator.of(sheetCtx).pop();
                                    _goAuth(context,
                                        redirectTo: currentRoute);
                                  },
                                  style: FilledButton.styleFrom(
                                      minimumSize:
                                          const Size.fromHeight(48)),
                                  child: const Text('Ingresar'),
                                ),
                              )
                            else ...[
                              ListTile(
                                leading: _AvatarCircle(
                                    url: user?['avatar_url'] as String?),
                                title: Text(user?['nombre'] ?? ''),
                                subtitle: Text(user?['correo'] ?? ''),
                                onTap: () =>
                                    _navAndClose(sheetCtx, '/perfil'),
                              ),
                              if (canSeePanel)
                                ListTile(
                                  leading:
                                      const Icon(Icons.dashboard_customize),
                                  title: const Text('Panel'),
                                  onTap: () =>
                                      _navAndClose(sheetCtx, '/panel'),
                                ),
                              ListTile(
                                leading: const Icon(Icons.logout),
                                title: const Text('Cerrar sesión'),
                                onTap: () async {
                                  Navigator.of(sheetCtx).pop();
                                  await auth.signOut();
                                  if (context.mounted) {
                                    Navigator.pushNamedAndRemoveUntil(
                                        context, '/', (r) => false);
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
    required this.user,
    required this.canSeePanel,
    required this.onSignOut,
  });

  final Map<String, dynamic> user;
  final bool canSeePanel;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Cuenta',
      position: PopupMenuPosition.under,
      onSelected: (v) async {
        switch (v) {
          case 1:
            Navigator.pushNamed(context, '/perfil');
            break;
          case 2:
            if (canSeePanel) Navigator.pushNamed(context, '/panel');
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
              _AvatarCircle(url: user['avatar_url'] as String?),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['nombre'] ?? '',
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    Text(user['correo'] ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
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
                leading: Icon(Icons.person), title: Text('Perfil'))),
        if (canSeePanel)
          const PopupMenuItem(
              value: 2,
              child: ListTile(
                  leading: Icon(Icons.dashboard),
                  title: Text('Panel'))),
        const PopupMenuDivider(),
        const PopupMenuItem(
            value: 99,
            child: ListTile(
                leading: Icon(Icons.logout),
                title: Text('Cerrar sesión'))),
      ],
      child: Row(
        children: [
          _AvatarCircle(url: user['avatar_url'] as String?),
          const SizedBox(width: 8),
          Text(user['nombre'] ?? ''),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({this.url, this.radius = 16});
  final String? url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final img = (url != null && url!.isNotEmpty) ? NetworkImage(url!) : null;
    return CircleAvatar(
      radius: radius,
      backgroundImage: img,
      child: img == null ? const Icon(Icons.person, size: 16) : null,
    );
  }
}
