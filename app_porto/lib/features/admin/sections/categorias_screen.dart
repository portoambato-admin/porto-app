import 'package:flutter/material.dart';
import '../presentation/widgets/admin_section_tabs.dart';

class AdminCategoriasScreen extends StatelessWidget {
  const AdminCategoriasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel • Categorías'),
        bottom: const AdminSectionTabs(current: AdminSection.categorias),
      ),
      body: const Center(child: Text('Categorías — próximamente')),
    );
  }
}
