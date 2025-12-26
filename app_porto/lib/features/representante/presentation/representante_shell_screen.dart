import 'package:flutter/material.dart';
import '../../../../core/constants/route_names.dart';

class RepresentanteShellScreen extends StatelessWidget {
  const RepresentanteShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel Representante')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Accesos rápidos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Mis mensualidades'),
            onTap: () =>
                Navigator.pushNamed(context, RouteNames.representanteMensualidades),
          ),
        ],
      ),
    );
  }
}
