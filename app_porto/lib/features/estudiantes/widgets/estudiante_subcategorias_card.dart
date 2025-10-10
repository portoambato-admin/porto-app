// lib/features/estudiantes/widgets/estudiante_subcategorias_card.dart
import 'package:flutter/material.dart';
import '../../../app/app_scope.dart';

class EstudianteSubcategoriasCard extends StatefulWidget {
  final int idEstudiante;
  const EstudianteSubcategoriasCard({super.key, required this.idEstudiante});

  @override
  State<EstudianteSubcategoriasCard> createState() => _EstudianteSubcategoriasCardState();
}

class _EstudianteSubcategoriasCardState extends State<EstudianteSubcategoriasCard> {
  late final _repoAsign = AppScope.of(context).subcatEst;
  late final _repoCats  = AppScope.of(context).categorias;
  late final _repoSubs  = AppScope.of(context).subcategorias;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  // Cache para diálogo
  List<Map<String, dynamic>> _cats = [];
  List<Map<String, dynamic>> _subsActivas = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await _repoAsign.porEstudiante(widget.idEstudiante);
      setState(() => _rows = rows);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openAddDialog() async {
    final formKey = GlobalKey<FormState>();
    int? catSel;
    int? subSel;

    try {
      // Cargamos cat y sub solo una vez por performance
      if (_cats.isEmpty) {
        _cats = await _repoCats.simpleList(); // [{id, nombre}]
      }
      if (_subsActivas.isEmpty) {
        // Subcategorías activas: [{id,idCategoria,nombre,codigo,activo,creadoEn,categoriaNombre}]
        _subsActivas = await _repoSubs.activas();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando cat/sub: $e')));
      return;
    }

    List<Map<String, dynamic>> subsFiltradas() {
      if (catSel == null) return const [];
      return _subsActivas.where((s) => (s['idCategoria'] as int?) == catSel).toList()
        ..sort((a, b) => (a['nombre'] as String).compareTo(b['nombre'] as String));
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Agregar a subcategoría'),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: catSel,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _cats.map((c) => DropdownMenuItem<int>(
                    value: c['id'] as int,
                    child: Text(c['nombre'] as String),
                  )).toList(),
                  onChanged: (v) {
                    setState(() {}); // por si el dialog necesita rebuild externo
                    catSel = v;
                    subSel = null; // reset sub
                  },
                  validator: (v) => v == null ? 'Selecciona una categoría' : null,
                ),
                const SizedBox(height: 8),
                StatefulBuilder(
                  builder: (ctx, setSB) {
                    final lista = subsFiltradas();
                    return DropdownButtonFormField<int>(
                      value: subSel,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Subcategoría',
                        prefixIcon: Icon(Icons.view_list),
                      ),
                      items: lista.map((s) => DropdownMenuItem<int>(
                        value: s['id'] as int,
                        child: Text('${s['nombre']}  •  ${s['codigo'] ?? ''}'.trim()),
                      )).toList(),
                      onChanged: (v) => setSB(() => subSel = v),
                      validator: (v) => v == null ? 'Selecciona una subcategoría' : null,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await _repoAsign.asignar(
                  idEstudiante: widget.idEstudiante,
                  idSubcategoria: subSel!,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asignación creada')));
                Navigator.pop(context, true);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al asignar: $e')));
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (ok == true) _load();
  }

  Future<void> _remove(Map<String, dynamic> r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quitar subcategoría'),
        content: Text('¿Quitar "${r['nombreSubcategoria']}" del estudiante?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Quitar')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _repoAsign.eliminar(
        idEstudiante: r['idEstudiante'] as int,
        idSubcategoria: r['idSubcategoria'] as int,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asignación eliminada')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.groups),
                const SizedBox(width: 8),
                Text('Subcategorías del estudiante',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _openAddDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading) const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )),
            if (_error != null)
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (!_loading && _error == null)
              _rows.isEmpty
                  ? const Text('Sin subcategorías asignadas.')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _rows.map((r) {
                        final txt = StringBuffer()
                          ..write(r['nombreSubcategoria'] ?? '—');
                        final cat = (r['nombreCategoria'] ?? '').toString();
                        final cod = (r['codigoUnico'] ?? '').toString();
                        if (cat.isNotEmpty) txt.write('  •  $cat');
                        if (cod.isNotEmpty) txt.write('  •  $cod');

                        return Chip(
                          label: Text(txt.toString()),
                          deleteIcon: const Icon(Icons.close),
                          onDeleted: () => _remove(r),
                        );
                      }).toList(),
                    ),
          ],
        ),
      ),
    );
  }
}
