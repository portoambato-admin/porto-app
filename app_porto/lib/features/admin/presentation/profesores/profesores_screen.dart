import 'package:app_porto/features/admin/presentation/widgets/admin_section_tabs.dart';
import 'package:flutter/material.dart';
import '../admin_shell.dart';
import 'profesores_tab.dart';

class ProfesoresScreen extends StatefulWidget {
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

    return AdminShell.legacy(
      section: AdminSection.profesores,
      title: 'Profesores',
      bottomExtra: _tabs(),
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
            const SnackBar(content: Text('Crear profesor (pendiente)')),
          );
        },
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Nuevo'),
      ),
    );
  }
}
