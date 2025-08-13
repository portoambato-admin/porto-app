import 'package:flutter/material.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  const TopNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 900;

    // Ruta actual
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
                'assets/img/banner.jpg',
                height: 42,
                errorBuilder: (_, __, ___) {
                  return const Icon(Icons.sports_soccer, size: 32);
                },
              ),
              const SizedBox(width: 12),
              Text(
                '', //aqui va algo de texto
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
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
                  text: 'Profesores',
                  route: '/profesores',
                  currentRoute: currentRoute,
                  onPressed: () {},
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
                FilledButton(onPressed: () {}, child: const Text('Ingresar')),
              ] else
                IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      showDragHandle: true,
                      builder: (_) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text('Inicio'),
                              onTap: () => Navigator.pushNamed(context, '/'),
                            ),
                            ListTile(
                              title: const Text('Tienda'),
                              onTap: () =>
                                  Navigator.pushNamed(context, '/tienda'),
                            ),
                            const ListTile(title: Text('Categorías')),
                            const ListTile(title: Text('Profesores')),
                            const ListTile(title: Text('Contacto')),
                            const Divider(height: 0),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: FilledButton(
                                onPressed: () {},
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
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Colors.black87,
        ),
      ),
    );
  }
}
