// lib/features/admin/sections/pagos_screen.dart
import 'package:flutter/material.dart';

class AdminPagosScreen extends StatelessWidget {
  const AdminPagosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagos')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Ahora la gestión de pagos (mensualidades, uniformes, extras) '
            'se hace desde el Detalle del Estudiante.\n\n'
            'Ve a Panel → Subcategorías → elige una → Estudiantes → toca un estudiante.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
