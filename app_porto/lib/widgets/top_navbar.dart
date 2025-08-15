import 'package:flutter/material.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  const TopNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  void _navAndClose(BuildContext ctx, String route, {bool useRoot = true}) {
    // Cerrar el bottom sheet si está abierto, luego navegar
    Navigator.of(ctx).pop();
    if (useRoot) {
      Navigator.of(ctx, rootNavigator: true).pushNamed(route);
    } else {
      Navigator.of(ctx).pushNamed(route);
    }
  }

  void _showComingSoon(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Próximamente'),
        content: const Text(
          'Estamos trabajando en el portal de usuarios para que padres, jugadores y profesores '
          'puedan acceder a inscripciones, pagos, evaluaciones y mucho más.\n\n'
          'Muy pronto podrás iniciar sesión, gestionar tu perfil y recibir notificaciones en tiempo real. '
          '¡Gracias por ser parte de la familia PortoAmbato! 💙⚽',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Entendido')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 900;
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/';

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
                errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer, size: 32),
              ),
              const SizedBox(width: 12),
              const Spacer(),
              if (!isSmall) ...[
                _NavButton(
                  text: 'Inicio',
                  route: '/',
                  currentRoute: currentRoute,
                  onPressed: () => Navigator.pushNamed(context, '/'),
                ),
                _NavButton(
                  text: 'Tienda',
                  route: '/tienda',
                  currentRoute: currentRoute,
                  onPressed: () => Navigator.pushNamed(context, '/tienda'),
                ),
                _NavButton(
                  text: 'Eventos',
                  route: '/eventos',
                  currentRoute: currentRoute,
                  onPressed: () => Navigator.pushNamed(context, '/eventos'),
                ),
                _NavButton(
                  text: 'Categorías',
                  route: '/categorias',
                  currentRoute: currentRoute,
                  onPressed: () => Navigator.pushNamed(context, '/categorias'),
                ),
                _NavButton(
                  text: 'Sponsors',
                  route: '/beneficios',
                  currentRoute: currentRoute,
                  onPressed: () => Navigator.pushNamed(context, '/beneficios'),
                ),
                _NavButton(
                  text: 'Conócenos',
                  route: '/conocenos',
                  currentRoute: currentRoute,
                  onPressed: () => Navigator.pushNamed(context, '/conocenos'),
                ),
                const SizedBox(width: 12),
                // 🔹 Ahora muestra el diálogo "Próximamente" en escritorio también
                FilledButton(
                  onPressed: () => _showComingSoon(context),
                  child: const Text('Ingresar'),
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
                              onTap: () => _navAndClose(sheetCtx, '/'),
                            ),
                            ListTile(
                              title: const Text('Tienda'),
                              onTap: () => _navAndClose(sheetCtx, '/tienda'),
                            ),
                            ListTile(
                              title: const Text('Eventos'),
                              onTap: () => _navAndClose(sheetCtx, '/eventos'),
                            ),
                            ListTile(
                              title: const Text('Categorías'),
                              onTap: () => _navAndClose(sheetCtx, '/categorias'),
                            ),
                            ListTile(
                              title: const Text('Sponsors'),
                              onTap: () => _navAndClose(sheetCtx, '/beneficios'),
                            ),
                            ListTile(
                              title: const Text('Conócenos'),
                              onTap: () => _navAndClose(sheetCtx, '/conocenos'),
                            ),
                            const Divider(height: 0),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: FilledButton(
                                onPressed: () {
                                  Navigator.of(sheetCtx).pop();
                                  _showComingSoon(context);
                                },
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                child: const Text('Ingresar'),
                              ),
                            ),
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
          color: isActive ? Theme.of(context).colorScheme.primary : Colors.black87,
        ),
      ),
    );
  }
}
