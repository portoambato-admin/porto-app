import 'package:flutter/material.dart';
import '../../../app/app_scope.dart';

class SubcategoriaEstudiantesScreen extends StatefulWidget {
  final int idSubcategoria;
  final String nombreSubcategoria;
  final int? idCategoria; // para matrícula

  const SubcategoriaEstudiantesScreen({
    super.key,
    required this.idSubcategoria,
    required this.nombreSubcategoria,
    this.idCategoria,
  });

  @override
  State<SubcategoriaEstudiantesScreen> createState() => _SubcategoriaEstudiantesScreenState();
}

class _SubcategoriaEstudiantesScreenState extends State<SubcategoriaEstudiantesScreen> {
  late final _subcatEst = AppScope.of(context).subcatEst;
  late final _est = AppScope.of(context).estudiantes;
  late final _mat = AppScope.of(context).matriculas;

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // ✅ Ahora pedimos directamente por subcategoría
      final asign = await _subcatEst.porSubcategoria(widget.idSubcategoria);

      // Si no vienen nombres en la asignación, consulta puntual del estudiante
      final list = <Map<String, dynamic>>[];
      for (final a in asign) {
        final idEst = (a['idEstudiante'] as num).toInt();
        String? nombres = a['nombres'];
        String? apellidos = a['apellidos'];

        if ((nombres == null || apellidos == null) && a['estudiante'] != null) {
          final parts = (a['estudiante'] as String).split(' ');
          if (parts.isNotEmpty) {
            // Deja el string completo si no quieres separar
            nombres = a['estudiante'];
            apellidos = '';
          }
        }

        if (nombres == null || apellidos == null) {
          final info = await _est.byId(idEst);
          nombres = info?['nombres'];
          apellidos = info?['apellidos'];
        }

        list.add({
          'id': idEst,
          'nombres': nombres ?? '—',
          'apellidos': apellidos ?? '',
          'activo': a['activo'] ?? true,
        });
      }

      setState(() => _rows = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _inscribir() async {
    final formKey = GlobalKey<FormState>();
    final nombres = TextEditingController();
    final apellidos = TextEditingController();
    final telefono = TextEditingController();
    final direccion = TextEditingController();
    final fecha = TextEditingController(); // opcional YYYY-MM-DD
    int idAcademia = 1;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Inscribir en ${widget.nombreSubcategoria}'),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombres,
                  decoration: const InputDecoration(labelText: 'Nombres'),
                  validator: (v) => (v==null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: apellidos,
                  decoration: const InputDecoration(labelText: 'Apellidos'),
                  validator: (v) => (v==null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(controller: telefono, decoration: const InputDecoration(labelText: 'Teléfono (opcional)')),
                const SizedBox(height: 8),
                TextFormField(controller: direccion, decoration: const InputDecoration(labelText: 'Dirección (opcional)')),
                const SizedBox(height: 8),
                TextFormField(controller: fecha, decoration: const InputDecoration(labelText: 'Fecha nac. YYYY-MM-DD (opcional)')),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: '1',
                  decoration: const InputDecoration(labelText: 'ID Academia'),
                  onChanged: (v) => idAcademia = int.tryParse(v) ?? 1,
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
                // 1) Crear estudiante
                final nuevo = await _est.crear(
                  nombres: nombres.text.trim(),
                  apellidos: apellidos.text.trim(),
                  telefono: telefono.text.trim().isEmpty ? null : telefono.text.trim(),
                  direccion: direccion.text.trim().isEmpty ? null : direccion.text.trim(),
                  fechaNacimiento: fecha.text.trim().isEmpty ? null : fecha.text.trim(),
                  idAcademia: idAcademia,
                );
                final idEst = (nuevo['id'] as num).toInt();

                // 2) Crear matrícula con la categoría de la subcategoría (si la tenemos)
                if (widget.idCategoria != null) {
                  await _mat.crear(
                    idEstudiante: idEst,
                    idCategoria: widget.idCategoria!,
                    ciclo: null,
                  );
                }

                // 3) Asignar a subcategoría
                await _subcatEst.asignar(
                  idEstudiante: idEst,
                  idSubcategoria: widget.idSubcategoria,
                );

                if (mounted) Navigator.pop(context, true);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Inscribir'),
          ),
        ],
      ),
    );

    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nombreSubcategoria),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _inscribir,
        icon: const Icon(Icons.person_add),
        label: const Text('Inscribir'),
      ),
      body: _error != null
        ? Center(child: Text(_error!))
        : _rows.isEmpty
          ? const Center(child: Text('Sin estudiantes en esta subcategoría'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final r = _rows[i];
                return Card(
                  child: ListTile(
                    leading: Icon((r['activo']==true) ? Icons.check_circle : Icons.cancel),
                    title: Text('${r['nombres']} ${r['apellidos']}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/admin/estudiantes/detalle',
                      arguments: {'id': (r['id'] as num).toInt()},
                    ),
                  ),
                );
              },
            ),
    );
  }
}
