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

  TabBar _tabs({required bool isScrollable}) {
    return TabBar(
      controller: _tab,
      isScrollable: isScrollable,
      tabs: const [
        Tab(text: 'Acctivos'),
        Tab(text: 'Inactivos'),
        Tab(text: 'Todos'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 700; // breakpoint simple para móvil/tablet

    // ====== MODO EMBEBIDO (dentro de otra vista) ======
    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _tabs(isScrollable: isMobile),
            ),
          ),
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

    // ====== MODO NORMAL (pantalla completa con AdminShell) ======
    return AdminShell.legacy(
      section: AdminSection.profesores,
      title: 'Profesores',
      // bottomExtra debe ser PreferredSizeWidget
      bottomExtra: PreferredSize(
        preferredSize: const Size.fromHeight(kTextTabBarHeight),
        child: _tabs(isScrollable: isMobile),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 8 : 12),
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
