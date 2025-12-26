import 'package:flutter/material.dart';
import '../../../../core/constants/route_names.dart';

class ProfesorShellScreen extends StatelessWidget {
  const ProfesorShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel Profesor')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Accesos rápidos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Mis estudiantes'),
            onTap: () => Navigator.pushNamed(context, RouteNames.profesorEstudiantes),
          ),
          ListTile(
            title: const Text('Asistencias'),
            onTap: () => Navigator.pushNamed(context, RouteNames.profesorAsistencias),
          ),
          ListTile(
            title: const Text('Evaluaciones'),
            onTap: () => Navigator.pushNamed(context, RouteNames.profesorEvaluaciones),
          ),
        ],
      ),
    );
  }
}
