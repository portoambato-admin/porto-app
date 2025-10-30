// lib/features/admin/presentation/profesores/profesores_screen.dart
import 'package:app_porto/features/admin/presentation/widgets/admin_section_tabs.dart';
import 'package:flutter/material.dart';
import '../admin_shell.dart';
import 'profesores_tab.dart';

class ProfesoresScreen extends StatefulWidget {
  /// Cuando es true, NO dibuja AdminShell (se usa como child dentro de PersonasHubScreen)
  final bool embedded;
  const ProfesoresScreen({super.key, this.embedded = false});

  @override
  State<ProfesoresScreen> createState() => _ProfesoresScreenState();
}

class _ProfesoresScreenState extends State<ProfesoresScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ✅ TabBar implementa PreferredSizeWidget, así que sirve para AppBar.bottom
  TabBar _tabs() {
    return TabBar(
      controller: _tab,
      isScrollable: false,
      tabs: const [
        Tab(text: 'Profesores activos'),
        Tab(text: 'Profesores inactivos'),
        Tab(text: 'Todos'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // MODO EMBEBIDO: SIN AdminShell (evita “doble hub” cuando se usa dentro del hub Personas)
    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: Alignment.center, child: _tabs()),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ProfesoresTab(tab: _tab),
            ),
          ),
        ],
      );
    }

    // MODO PANTALLA DIRECTA: CON AdminShell (compat con rutas antiguas)
    return AdminShell.legacy(
      section: AdminSection.profesores,
      title: 'Profesores',
      bottomExtra: _tabs(), // ✅ ahora es PreferredSizeWidget
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ProfesoresTab(tab: _tab),
      ),
      actions: [
        IconButton(
          tooltip: 'Refrescar',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Refrescar (acción demo)')),
            );
          },
          icon: const Icon(Icons.refresh),
        ),
      ],
      fab: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Crear profesor (pendiente PASO 4)')),
          );
        },
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Nuevo'),
      ),
    );
  }
}
