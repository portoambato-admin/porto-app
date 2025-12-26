import 'package:flutter/material.dart';

class ProfesorEstudiantesScreen extends StatelessWidget {
  const ProfesorEstudiantesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(title: Text('Mis estudiantes')),
      body: Center(child: Text('TODO: listar solo estudiantes asignados al profesor')),
    );
  }
}
