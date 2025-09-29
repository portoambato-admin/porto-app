import 'package:flutter/material.dart';
import '../../../../core/state/auth_state.dart';

class PanelScreen extends StatelessWidget {
  const PanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final isAdmin = auth.isAdmin;
    final isTeacher = auth.isTeacher;

    if (!isAdmin && !isTeacher) {
      return Scaffold(
        appBar: AppBar(title: const Text('Panel')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block, size: 48),
                const SizedBox(height: 12),
                const Text('No tienes acceso al panel'),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () =>
                      Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false),
                  child: const Text('Volver al inicio'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final items = <_Item>[
      if (isAdmin) _Item('Usuarios', Icons.people, '/admin/usuarios'),
      if (isAdmin) _Item('Profesores', Icons.school, '/admin/profesores'),
      if (isAdmin) _Item('Categorías', Icons.category, '/admin/categorias'),
      if (isAdmin) _Item('Subcategorías', Icons.folder, '/admin/subcategorias'),
      if (isAdmin) _Item('Asistencias', Icons.event_available, '/admin/asistencias'),
      if (isAdmin) _Item('Evaluaciones', Icons.assignment_turned_in, '/admin/evaluaciones'),
      if (isAdmin) _Item('Pagos', Icons.payments, '/admin/pagos'),
      _Item('Config', Icons.settings, '/admin/config'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Panel')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) => _MinimalTile(item: items[i]),
          ),
        ),
      ),
    );
  }
}

class _Item {
  final String title;
  final IconData icon;
  final String route;
  const _Item(this.title, this.icon, this.route);
}

class _MinimalTile extends StatelessWidget {
  const _MinimalTile({required this.item});
  final _Item item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Icon(item.icon, color: cs.onPrimaryContainer),
        ),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(context, item.route),
      ),
    );
  }
}
