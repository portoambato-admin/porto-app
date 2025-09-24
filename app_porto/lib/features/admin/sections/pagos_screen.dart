import 'package:flutter/material.dart';
import '../presentation/widgets/admin_section_tabs.dart';

class AdminPagosScreen extends StatelessWidget {
  const AdminPagosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel • Pagos'),
        bottom: const AdminSectionTabs(current: AdminSection.pagos),
      ),
      body: const Center(child: Text('Pagos — próximamente')),
    );
  }
}
