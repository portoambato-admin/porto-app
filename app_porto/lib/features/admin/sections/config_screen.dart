import 'package:flutter/material.dart';
import '../presentation/widgets/admin_section_tabs.dart';

class AdminConfigScreen extends StatelessWidget {
  const AdminConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel • Configuración'),
        bottom: const AdminSectionTabs(current: AdminSection.config),
      ),
      body: const Center(child: Text('Configuración — próximamente')),
    );
  }
}
