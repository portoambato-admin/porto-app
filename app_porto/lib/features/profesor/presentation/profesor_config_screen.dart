import 'package:flutter/material.dart';

class ProfesorConfigScreen extends StatelessWidget {
  const ProfesorConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Config (Profesor)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.palette),
            title: Text('Tema'),
            subtitle: Text('Config de tema (si ya tienes Settings global, lo enlazamos aquí).'),
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notificaciones'),
            subtitle: Text('Preferencias de notificaciones (placeholder).'),
          ),
          ListTile(
            leading: Icon(Icons.security),
            title: Text('Seguridad'),
            subtitle: Text('Opciones de sesión/privacidad (placeholder).'),
          ),
        ],
      ),
    );
  }
}
