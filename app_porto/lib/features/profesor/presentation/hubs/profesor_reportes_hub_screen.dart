import 'package:flutter/material.dart';
import '../../../../core/constants/route_names.dart';

class ProfesorReportesHubScreen extends StatelessWidget {
  const ProfesorReportesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes (Profesor)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Reportes disponibles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Reporte de asistencias'),
              subtitle: const Text('Limitado (profesor)'),
              onTap: () => Navigator.pushNamed(context, RouteNames.profesorReporteAsistencias),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups),
              title: const Text('Listado de estudiantes'),
              subtitle: const Text('Limitado (profesor)'),
              onTap: () => Navigator.pushNamed(context, RouteNames.profesorReporteEstudiantes),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nota: aquí no se muestran reportes financieros ni de administración.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
