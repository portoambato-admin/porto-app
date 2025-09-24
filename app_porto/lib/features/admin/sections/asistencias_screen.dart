import 'package:flutter/material.dart';
import '../presentation/widgets/admin_section_tabs.dart';

class AdminAsistenciasScreen extends StatelessWidget {
  const AdminAsistenciasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel • Asistencias'),
        bottom: const AdminSectionTabs(current: AdminSection.asistencias),
      ),
      body: const Center(child: Text('Asistencias — próximamente')),
    );
  }
}
