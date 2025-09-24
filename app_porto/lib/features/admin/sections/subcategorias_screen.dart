import 'package:flutter/material.dart';
import '../presentation/admin_shell.dart';
import '../presentation/widgets/admin_section_tabs.dart';

class AdminSubcategoriasScreen extends StatelessWidget {
  const AdminSubcategoriasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Panel • Subcategorías',
      current: AdminSection.subcategorias,
      child: const Center(
        child: Text('Subcategorías — próximamente'),
      ),
    );
  }
}
