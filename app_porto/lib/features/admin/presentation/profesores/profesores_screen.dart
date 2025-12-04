import 'package:flutter/material.dart';
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Gestión de Profesores',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tab,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(
              text: 'Activos',
              icon: Icon(Icons.check_circle_outline, size: 20),
            ),
            Tab(
              text: 'Inactivos',
              icon: Icon(Icons.block_outlined, size: 20),
            ),
            Tab(
              text: 'Todos',
              icon: Icon(Icons.list_alt_rounded, size: 20),
            ),
          ],
        ),
      ),
      
      body: ProfesoresTab(tab: _tab),
    );
  }
}