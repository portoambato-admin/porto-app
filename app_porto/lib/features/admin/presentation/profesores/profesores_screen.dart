import 'package:flutter/material.dart';
import '../admin_shell.dart';
import '../widgets/admin_section_tabs.dart';
import 'profesores_tab.dart';

class ProfesoresScreen extends StatefulWidget {
  const ProfesoresScreen({super.key});

  @override
  State<ProfesoresScreen> createState() => _ProfesoresScreenState();
}

class _ProfesoresScreenState extends State<ProfesoresScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Panel • Profesores',
      current: AdminSection.profesores,
      // ↓ Sub-tabs en el AppBar, como en PanelScreen
      bottomExtra: TabBar(
        controller: _tab,
        tabs: const [
          Tab(text: 'Profesores activos'),
          Tab(text: 'Profesores inactivos'),
          Tab(text: 'Todos'),
        ],
      ),
      // ↓ Contenido con el mismo look & feel que PanelScreen
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ProfesoresTab(tab: _tab),
      ),
    );
  }
}
