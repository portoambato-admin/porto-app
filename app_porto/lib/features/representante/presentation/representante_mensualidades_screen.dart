import 'package:flutter/material.dart';
import '../../../../core/constants/route_names.dart';

class RepresentanteMensualidadesScreen extends StatelessWidget {
  const RepresentanteMensualidadesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis mensualidades')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('TODO: mostrar mensualidades del/los representados'),
            subtitle: Text('Pendiente / Pagado / Vencido'),
          ),
          ListTile(
            title: const Text('Abrir detalle (demo)'),
            onTap: () => Navigator.pushNamed(
              context,
              RouteNames.representanteMensualidadDetalle,
            ),
          ),
        ],
      ),
    );
  }
}
