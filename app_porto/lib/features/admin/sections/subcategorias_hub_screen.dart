import 'package:flutter/material.dart';
import './admin_subcategorias_screen.dart';
import './subcategorias_screen.dart' show SubcategoriaEstudiantesScreen;

class SubcategoriasHubScreen extends StatefulWidget {
  const SubcategoriasHubScreen({super.key});

  @override
  State<SubcategoriasHubScreen> createState() => _SubcategoriasHubScreenState();
}

class _SubcategoriasHubScreenState extends State<SubcategoriasHubScreen> {
  Map<String, dynamic>? _selected; // subcategoría elegida en el listado
  bool _showDetailOnNarrow = false;

  void _openDetail(Map<String, dynamic> row) {
    setState(() {
      _selected = row;
      _showDetailOnNarrow = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final detail = _selected == null
        ? const _EmptyDetail()
        : SubcategoriaEstudiantesScreen(
            idSubcategoria: (_selected!['id'] as num).toInt(),
            nombreSubcategoria: _selected!['nombre']?.toString() ?? '',
            idCategoria: _selected!['idCategoria'] as int?,
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subcategorías'),
        leading: _showDetailOnNarrow
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _showDetailOnNarrow = false),
              )
            : null,
      ),
      body: LayoutBuilder(
        builder: (ctx, c) {
          final wide = c.maxWidth >= 1100;

          final listPane = SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                type: MaterialType.transparency,
                child: AdminSubcategoriasScreen(
                  embedded: true,
                  onOpenEstudiantes: _openDetail,
                ),
              ),
            ),
          );

          final detailPane = SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                type: MaterialType.transparency,
                child: detail,
              ),
            ),
          );

          if (wide) {
            // Master–Detail lado a lado
            return Row(
              children: [
                Expanded(flex: 5, child: listPane),
                const VerticalDivider(width: 1),
                Expanded(flex: 7, child: detailPane),
              ],
            );
          }

          // Pantalla angosta: alterna entre lista y detalle
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _showDetailOnNarrow ? detailPane : listPane,
          );
        },
      ),
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Selecciona una subcategoría para ver sus estudiantes.',
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
