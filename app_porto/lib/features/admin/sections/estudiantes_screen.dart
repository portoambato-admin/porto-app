import 'package:flutter/material.dart';
import '../../../app/app_scope.dart';
import 'crear_estudiante_matricula_screen.dart';

class AdminEstudiantesScreen extends StatefulWidget {
  const AdminEstudiantesScreen({super.key});
  @override
  State<AdminEstudiantesScreen> createState() => _AdminEstudiantesScreenState();
}

class _AdminEstudiantesScreenState extends State<AdminEstudiantesScreen> {
  late final _repo = AppScope.of(context).estudiantes;

  bool _loading = false;
  String? _error;

  final _q = TextEditingController();
  int? _catId;
  bool? _onlyActive;

  List<Map<String, dynamic>> _rows = [];
  int _total = 0, _page = 1, _pageSize = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _repo.paged(
        page: _page,
        pageSize: _pageSize,
        q: _q.text.trim().isEmpty ? null : _q.text.trim(),
        categoriaId: _catId,
        onlyActive: _onlyActive,
      );
      setState(() {
        _rows = List<Map<String, dynamic>>.from(res['items']);
        _total = (res['total'] as num).toInt();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit({required Map<String, dynamic> row}) async {
    final formKey = GlobalKey<FormState>();
    final nombres   = TextEditingController(text: row['nombres'] ?? '');
    final apellidos = TextEditingController(text: row['apellidos'] ?? '');
    final fecha     = TextEditingController(text: row['fechaNacimiento'] ?? '');
    final direccion = TextEditingController(text: row['direccion'] ?? '');
    final telefono  = TextEditingController(text: row['telefono'] ?? '');
    int? idAcademia = row['idAcademia'];

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar estudiante'),
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
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: apellidos,
                  decoration: const InputDecoration(labelText: 'Apellidos'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: fecha,
                  decoration: const InputDecoration(labelText: 'Fecha nacimiento (YYYY-MM-DD, opcional)'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: telefono,
                  decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: direccion,
                  decoration: const InputDecoration(labelText: 'Dirección (opcional)'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: idAcademia?.toString() ?? '1',
                  decoration: const InputDecoration(labelText: 'ID Academia'),
                  onChanged: (v) => idAcademia = int.tryParse(v),
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
                await _repo.update(
                  idEstudiante: (row['id'] as num).toInt(),
                  nombres: nombres.text.trim(),
                  apellidos: apellidos.text.trim(),
                  fechaNacimiento: fecha.text.trim().isEmpty ? null : fecha.text.trim(),
                  direccion: direccion.text.trim().isEmpty ? null : direccion.text.trim(),
                  telefono: telefono.text.trim().isEmpty ? null : telefono.text.trim(),
                  idAcademia: idAcademia,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estudiante actualizado')));
                Navigator.pop(context, true);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (ok == true) _load();
  }

  Future<void> _toggleEstado(Map<String, dynamic> r) async {
    final activo = r['activo'] == true;
    final id = (r['id'] as num).toInt();
    try {
      if (activo) {
        await _repo.deactivate(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estudiante desactivado')));
      } else {
        await _repo.activate(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estudiante activado')));
      }
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final from = (_total == 0) ? 0 : ((_page - 1) * _pageSize + 1);
    final to = ((_page * _pageSize) > _total) ? _total : (_page * _pageSize);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estudiantes'),
        actions: [
          IconButton(
            tooltip: 'Refrescar',
            onPressed: _loading ? null : _load,
            icon: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      // FAB ahora abre la pantalla combinada (no el diálogo)
      floatingActionButton: FloatingActionButton.extended(
  onPressed: () async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CrearEstudianteMatriculaScreen()),
    );
    if (created == true) _load();
  },
  icon: const Icon(Icons.add),
  label: const Text('Nuevo'),
),
      body: Column(
        children: [
          _toolbar(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            ),
          Expanded(
            child: _rows.isEmpty
                ? const Center(child: Text('Sin resultados'))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final r = _rows[i];
                      final activo = r['activo'] == true;
                      return Card(
                        child: ListTile(
                          leading: Icon(activo ? Icons.check_circle : Icons.cancel),
                          title: Text('${r['nombres']} ${r['apellidos']}'),
                          subtitle: Text(
                            r['categoriaNombre'] == null
                              ? 'Sin matrícula'
                              : 'Últ. categoría: ${r['categoriaNombre']}',
                          ),
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/admin/estudiantes/detalle',
                            arguments: {'id': (r['id'] as num).toInt()},
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(icon: const Icon(Icons.edit), onPressed: () => _edit(row: r)),
                              IconButton(
                                icon: Icon(activo ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => _toggleEstado(r),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Text('Mostrando $from–$to de $_total'),
                const Spacer(),
                IconButton(
                  onPressed: (_page > 1) ? () { setState(() => _page--); _load(); } : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('$_page'),
                IconButton(
                  onPressed: (to < _total) ? () { setState(() => _page++); _load(); } : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: LayoutBuilder(
        builder: (ctx, c) {
          final search = Expanded(
            child: TextField(
              controller: _q,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar por nombre…'),
              onSubmitted: (_) { _page = 1; _load(); },
            ),
          );

          final catDropdown = FutureBuilder<List<Map<String, dynamic>>>(
            future: AppScope.of(context).categorias.simpleList(),
            builder: (_, snap) {
              final list = snap.data ?? const <Map<String, dynamic>>[];
              return SizedBox(
                width: 260,
                child: DropdownButtonFormField<int>(
                  value: _catId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Categoría', prefixIcon: Icon(Icons.category)),
                  items: [
                    const DropdownMenuItem<int>(value: null, child: Text('Todas')),
                    ...list.map((c) => DropdownMenuItem<int>(
                          value: c['id'] as int,
                          child: Text(c['nombre'] as String),
                        )),
                  ],
                  onChanged: (v) { setState(() { _catId = v; _page = 1; }); _load(); },
                ),
              );
            },
          );

          final estado = SizedBox(
            width: 220,
            child: DropdownButtonFormField<bool>(
              value: _onlyActive,
              decoration: const InputDecoration(labelText: 'Estado', prefixIcon: Icon(Icons.filter_alt)),
              items: const [
                DropdownMenuItem<bool>(value: null, child: Text('Todos')),
                DropdownMenuItem<bool>(value: true, child: Text('Activos')),
                DropdownMenuItem<bool>(value: false, child: Text('Inactivos')),
              ],
              onChanged: (v) { setState(() { _onlyActive = v; _page = 1; }); _load(); },
            ),
          );

          final perPage = SizedBox(
            width: 140,
            child: DropdownButtonFormField<int>(
              value: _pageSize,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.format_list_numbered), labelText: 'Por página'),
              items: const [
                DropdownMenuItem(value: 10, child: Text('10')),
                DropdownMenuItem(value: 20, child: Text('20')),
                DropdownMenuItem(value: 50, child: Text('50')),
              ],
              onChanged: (v) { if (v != null) { setState(() { _pageSize = v; _page = 1; }); _load(); } },
            ),
          );

          final narrow = c.maxWidth < 900;
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [search, const SizedBox(height: 8), catDropdown, const SizedBox(height: 8), estado, const SizedBox(height: 8), perPage],
            );
          }
          return Row(children: [search, const SizedBox(width: 8), catDropdown, const SizedBox(width: 8), estado, const SizedBox(width: 8), perPage]);
        },
      ),
    );
  }
}
