import 'package:flutter/material.dart';

enum AdminSection {
  usuarios,
  profesores,
  categorias,
  subcategorias,
  asistencias,
  pagos,
  config,
}

class AdminSectionTabs extends StatelessWidget implements PreferredSizeWidget {
  const AdminSectionTabs({super.key, required this.current});
  final AdminSection current;

  // ===== Navegación =====
  static String _routeOf(AdminSection s) {
    switch (s) {
      case AdminSection.usuarios:       return '/admin/usuarios';
      case AdminSection.profesores:     return '/admin/profesores';
      case AdminSection.categorias:     return '/admin/categorias';
      case AdminSection.subcategorias:  return '/admin/subcategororias'; // <- ojo: si tu ruta real es /admin/subcategorias, cambia aquí
      case AdminSection.asistencias:    return '/admin/asistencias';

      case AdminSection.pagos:          return '/admin/pagos';
      case AdminSection.config:         return '/admin/config';
    }
  }

  void _go(BuildContext ctx, AdminSection s) {
    final route = _routeOf(s);
    if (ModalRoute.of(ctx)?.settings.name == route) return;
    Navigator.pushReplacementNamed(ctx, route);
  }

  // ===== Apariencia =====
  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Fondo sutil tipo “pill bar” con borde suave
    final barBg = Color.alphaBlend(cs.primary.withOpacity(0.04), cs.surface);
    final barBorder = cs.outlineVariant;

    final items = <_SectionItem>[
      _SectionItem(AdminSection.usuarios,      Icons.groups_2_rounded,               'Usuarios'),
      _SectionItem(AdminSection.profesores,    Icons.school_rounded,                 'Profesores'),
      _SectionItem(AdminSection.categorias,    Icons.category_rounded,               'Categorías'),
      _SectionItem(AdminSection.subcategorias, Icons.account_tree_rounded,           'Subcategorías'),
      _SectionItem(AdminSection.asistencias,   Icons.fact_check_rounded,             'Asistencias'),
  
      _SectionItem(AdminSection.pagos,         Icons.account_balance_wallet_rounded, 'Pagos'),
      _SectionItem(AdminSection.config,        Icons.settings_rounded,               'Config'),
    ];

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: barBg,
          border: Border(
            top: BorderSide(color: barBorder, width: 0.5),
            bottom: BorderSide(color: barBorder, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment: Alignment.centerLeft,
        child: _HorizontalFader(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final it in items)
                  _PillButton(
                    icon: it.icon,
                    label: it.label,
                    active: current == it.section,
                    onTap: () => _go(context, it.section),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionItem {
  const _SectionItem(this.section, this.icon, this.label);
  final AdminSection section;
  final IconData icon;
  final String label;
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bgActive   = cs.secondaryContainer;
    final fgActive   = cs.onSecondaryContainer;
    final bgInactive = Colors.transparent;
    final fgInactive = cs.primary;
    final borderClr  = active ? cs.secondaryContainer : cs.outlineVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? bgActive : bgInactive,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderClr, width: 1),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: cs.secondary.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: active ? fgActive : fgInactive),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active ? fgActive : fgInactive,
                  fontSize: 14,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sutileza: degradados en los bordes cuando hay overflow horizontal
class _HorizontalFader extends StatelessWidget {
  const _HorizontalFader({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            child,
            // Fade izquierdo
            Positioned(
              left: 0, top: 0, bottom: 0, width: 20,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor,
                        Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Fade derecho
            Positioned(
              right: 0, top: 0, bottom: 0, width: 20,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor,
                        Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Línea inferior muy sutil
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 0.5,
                    color: cs.outlineVariant.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
