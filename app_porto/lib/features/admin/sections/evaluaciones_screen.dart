import 'package:flutter/material.dart';
import '../presentation/widgets/admin_section_tabs.dart';

class AdminEvaluacionesScreen extends StatelessWidget {
  const AdminEvaluacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel • Evaluaciones'),
        bottom: const AdminSectionTabs(current: AdminSection.evaluaciones),
      ),
      body: const Center(child: Text('Evaluaciones — próximamente')),
    );
  }
}
