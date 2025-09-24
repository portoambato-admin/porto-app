import 'package:flutter/material.dart';
import '../../../../core/services/session.dart';
import '../../../../core/services/api_service.dart';

class ProfesoresTab extends StatefulWidget {
  const ProfesoresTab({super.key, required this.tab});
  final TabController tab;

  @override
  State<ProfesoresTab> createState() => _ProfesoresTabState();
}

class _ProfesoresTabState extends State<ProfesoresTab> {
  final _searchCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  int _page = 1;
  int _pageSize = 10;
  String _sort = 'id_profesor'; // id_profesor|especialidad|nombre_usuario|id_usuario
  String _order = 'desc';       // asc|desc
  int _total = 0;
  List<Map<String, dynamic>> _rows = [];

  late final VoidCallback _tabListener;

  @override
  void initState() {
    super.initState();
    _tabListener = () {
      if (!widget.tab.indexIsChanging) {
        setState(() => _page = 1);
        _load();
      }
    };
    widget.tab.addListener(_tabListener);
    _load();
  }

  @override
  void didUpdateWidget(covariant ProfesoresTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab != widget.tab) {
      oldWidget.tab.removeListener(_tabListener);
      widget.tab.addListener(_tabListener);
      _page = 1;
      _load();
    }
  }

  @override
  void dispose() {
    widget.tab.removeListener(_tabListener);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await Session.getToken();
      if (token == null) throw Exception('Sesión expirada');
      final q = _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim();

      Map<String, dynamic> resp;
      switch (widget.tab.index) {
        case 0:
          resp = await ApiService.getProfesoresActivosPaged(
            token, page: _page, pageSize: _pageSize, q: q, sort: _sort, order: _order,
          );
          break;
        case 1:
          resp = await ApiService.getProfesoresInactivosPaged(
            token, page: _page, pageSize: _pageSize, q: q, sort: _sort, order: _order,
          );
          break;
        default:
          resp = await ApiService.getProfesoresTodosPaged(
            token, page: _page, pageSize: _pageSize, q: q, sort: _sort, order: _order,
          );
      }

      setState(() {
        _rows = List<Map<String, dynamic>>.from(resp['items'] as List);
        _total = (resp['total'] as num).toInt();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleSort(String key) {
    setState(() {
      if (_sort == key) {
        _order = _order == 'asc' ? 'desc' : 'asc';
      } else {
        _sort = key;
        _order = 'asc';
      }
      _page = 1;
    });
    _load();
  }

  Future<void> _toggleActivo(Map<String, dynamic> r) async {
    try {
      final token = await Session.getToken();
      if (token == null) throw Exception('Sesión expirada');
      final id = (r['id_profesor'] as num).toInt();
      final activo = r['activo'] == true;

      if (activo) {
        await ApiService.deleteProfesor(token: token, idProfesor: id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profesor desactivado')));
      } else {
        await ApiService.activarProfesor(token: token, idProfesor: id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profesor activado')));
      }
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _openEdit(Map<String, dynamic> data) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ProfesorDialog(data: data), // solo edita campos de profesor
    );
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filtros / acciones (el TabBar está en el AppBar)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar por nombre, especialidad, teléfono…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) { _page = 1; _load(); },
              ),
            ),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
            const Spacer(),
            DropdownButton<int>(
              value: _pageSize,
              onChanged: (v) { if (v != null) { setState(() { _pageSize = v; _page = 1; }); _load(); } },
              items: const [
                DropdownMenuItem(value: 5, child: Text('5')),
                DropdownMenuItem(value: 10, child: Text('10')),
                DropdownMenuItem(value: 20, child: Text('20')),
                DropdownMenuItem(value: 50, child: Text('50')),
              ],
            ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ),
        const SizedBox(height: 6),

        // Lista / Tabla
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _rows.isEmpty
                  ? const Center(child: Text('Sin resultados'))
                  : isWide
                      ? _DesktopTable(
                          rows: _rows,
                          sort: _sort,
                          order: _order,
                          onSort: _toggleSort,
                          onEdit: _openEdit,
                          onToggleActivo: _toggleActivo,
                        )
                      : _MobileCards(
                          rows: _rows,
                          onEdit: _openEdit,
                          onToggleActivo: _toggleActivo,
                        ),
        ),

        // Paginador
        _Paginator(
          page: _page,
          pageSize: _pageSize,
          total: _total,
          onPage: (p) { setState(() => _page = p); _load(); },
        ),
      ],
    );
  }
}

/* =========================
   Tabla / Cards / Paginador
   ========================= */

class _DesktopTable extends StatelessWidget {
  const _DesktopTable({
    required this.rows,
    required this.sort,
    required this.order,
    required this.onSort,
    required this.onEdit,
    required this.onToggleActivo,
  });

  final List<Map<String, dynamic>> rows;
  final String sort;
  final String order;
  final void Function(String) onSort;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onToggleActivo;

  @override
  Widget build(BuildContext context) {
    final asc = order.toLowerCase() == 'asc';
    DataColumn c(String label, String key) => DataColumn(
      label: InkWell(
        onTap: () => onSort(key),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (sort == key) Icon(asc ? Icons.arrow_drop_up : Icons.arrow_drop_down),
          ],
        ),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: DataTable(
        columns: [
          c('ID', 'id_profesor'),
          c('Nombre', 'nombre_usuario'),
          c('Especialidad', 'especialidad'),
          c('Teléfono', 'telefono'),
          c('Correo', 'correo'),
          c('Activo', 'activo'),
          const DataColumn(label: Text('Acciones')),
        ],
        rows: rows.map((r) {
          final nombre = (r['nombre_usuario'] ?? r['nombre'] ?? '').toString();
          final correo = (r['correo'] ?? '').toString();
          final activo = r['activo'] == true;
          return DataRow(cells: [
            DataCell(Text('${r['id_profesor']}')),
            DataCell(Text(nombre)),
            DataCell(Text('${r['especialidad'] ?? ''}')),
            DataCell(Text('${r['telefono'] ?? ''}')),
            DataCell(Text(correo)),
            DataCell(Icon(activo ? Icons.check_circle : Icons.cancel)),
            DataCell(Row(
              children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => onEdit(r)),
                IconButton(
                  icon: Icon(activo ? Icons.block : Icons.check_circle),
                  onPressed: () => onToggleActivo(r),
                ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }
}

class _MobileCards extends StatelessWidget {
  const _MobileCards({
    required this.rows,
    required this.onEdit,
    required this.onToggleActivo,
  });

  final List<Map<String, dynamic>> rows;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onToggleActivo;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final r = rows[i];
        final activo = r['activo'] == true;
        final nombre = (r['nombre_usuario'] ?? r['nombre'] ?? '').toString();
        return Card(
          child: ListTile(
            title: Text(nombre),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Especialidad: ${r['especialidad'] ?? ''}'),
                Text('Teléfono: ${r['telefono'] ?? ''}'),
                Text('Correo: ${r['correo'] ?? ''}'),
              ],
            ),
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => onEdit(r)),
                IconButton(
                  icon: Icon(activo ? Icons.block : Icons.check_circle),
                  onPressed: () => onToggleActivo(r),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Paginator extends StatelessWidget {
  const _Paginator({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.onPage,
  });

  final int page, pageSize, total;
  final void Function(int) onPage;

  @override
  Widget build(BuildContext context) {
    final to = (page * pageSize > total) ? total : (page * pageSize);
    final from = (total == 0) ? 0 : ((page - 1) * pageSize + 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          Text('Mostrando $from–$to de $total'),
          const Spacer(),
          IconButton(
            tooltip: 'Anterior',
            onPressed: page > 1 ? () => onPage(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('$page'),
          IconButton(
            tooltip: 'Siguiente',
            onPressed: (to < total) ? () => onPage(page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

/* =========================
   Diálogo de EDICIÓN (solo profesor)
   ========================= */

class _ProfesorDialog extends StatefulWidget {
  const _ProfesorDialog({required this.data});
  final Map<String, dynamic> data;

  @override
  State<_ProfesorDialog> createState() => _ProfesorDialogState();
}

class _ProfesorDialogState extends State<_ProfesorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _espCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _dirCtrl = TextEditingController();
  bool _activo = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _espCtrl.text = d['especialidad'] ?? '';
    _telCtrl.text = d['telefono'] ?? '';
    _dirCtrl.text = d['direccion'] ?? '';
    _activo = (d['activo'] ?? true) == true;
  }

  @override
  void dispose() {
    _espCtrl.dispose();
    _telCtrl.dispose();
    _dirCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final token = await Session.getToken();
      if (token == null) throw Exception('Sesión expirada');

      await ApiService.putProfesor(
        token: token,
        idProfesor: (widget.data['id_profesor'] as num).toInt(),
        especialidad: _espCtrl.text.trim().isEmpty ? null : _espCtrl.text.trim(),
        telefono: _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
        direccion: _dirCtrl.text.trim().isEmpty ? null : _dirCtrl.text.trim(),
        activo: _activo,
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = (widget.data['nombre_usuario'] ?? widget.data['nombre'] ?? '').toString();
    final correo = (widget.data['correo'] ?? '').toString();

    return AlertDialog(
      title: const Text('Editar profesor'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  enabled: false,
                  initialValue: '$nombre · $correo',
                  decoration: const InputDecoration(labelText: 'Usuario'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _espCtrl,
                  decoration: const InputDecoration(labelText: 'Especialidad'),
                ),
                TextFormField(
                  controller: _telCtrl,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
                TextFormField(
                  controller: _dirCtrl,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _activo,
                  onChanged: (v) => setState(() => _activo = v),
                  title: const Text('Activo'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(onPressed: _saving ? null : _save, child: const Text('Guardar')),
      ],
    );
  }
}
