import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class UsuariosScreen extends StatelessWidget {
  const UsuariosScreen({super.key, required this.api});
  final ApiService api;

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Usuarios — usa tu módulo existente aquí'));
  }
}
