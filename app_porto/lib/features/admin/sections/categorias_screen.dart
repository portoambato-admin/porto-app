import 'package:flutter/material.dart';
import '../../../app/app_scope.dart';

class AdminCategoriasScreen extends StatefulWidget {
  const AdminCategoriasScreen({super.key});

  @override
  State<AdminCategoriasScreen> createState() => _AdminCategoriasScreenState();
}

class _AdminCategoriasScreenState extends State<AdminCategoriasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late final _repo = AppScope.of(context).categorias;

  bool _loading = false;
  String? _error;

  // ======== Estado por pestaña ========
  // Activas
  List<Map<String, dynamic>> _act = [];
  int _actTotal = 0;
  int _actPage = 1;
  int _actPageSize = 10;
  String _actSort = 'creado_en';
  bool _actAsc = false;

  // Inactivas
  List<Map<String, dynamic>> _ina = [];
  int _inaTotal = 0;
  int _inaPage = 1;
  int _inaPageSize = 10;
  String _inaSort = 'creado_en';
  bool _inaAsc = false;

  // Todas
  List<Map<String, dynamic>> _all = [];
  int _allTotal = 0;
  int _allPage = 1;
  int _allPageSize = 10;
  String _allSort = 'creado_en';
  bool _allAsc = false;

  // búsqueda
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (!_tab.indexIsChanging) _loadCurrentTab();
      });
    // primer fetch
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrentTab());
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentTab() async {
    switch (_tab.index) {
      case 0:
        return _loadActivas();
      case 1:
        return _loadInactivas();
      case 2:
        return _loadTodas();
    }
  }

  Future<void> _loadActivas() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _repo.paged(
        page: _actPage,
        pageSize: _actPageSize,
        q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        sort: _actSort,
        order: _actAsc ? 'asc' : 'desc',
        onlyActive: true,
      );
      setState(() {
        _act = List<Map<String, dynamic>>.from(res['items']);
        _actTotal = (res['total'] as num).toInt();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadInactivas() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _repo.paged(
        page: _inaPage,
        pageSize: _inaPageSize,
        q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        sort: _inaSort,
        order: _inaAsc ? 'asc' : 'desc',
        onlyActive: false,
      );
      setState(() {
        _ina = List<Map<String, dynamic>>.from(res['items']);
        _inaTotal = (res['total'] as num).toInt();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadTodas() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _repo.paged(
        page: _allPage,
        pageSize: _allPageSize,
        q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        sort: _allSort,
        order: _allAsc ? 'asc' : 'desc',
        onlyActive: null, // todas
      );
      setState(() {
        _all = List<Map<String, dynamic>>.from(res['items']);
        _allTotal = (res['total'] as num).toInt();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ===== CRUD =====
  Future<void> _newOrEdit({Map<String, dynamic>? row}) async {
    final formKey = GlobalKey<FormState>();
    final nombre = TextEditingController(text: row?['nombre'] ?? '');
    final edadMin = TextEditingController(text: row?['edadMin']?.toString() ?? '');
    final edadMax = TextEditingController(text: row?['edadMax']?.toString() ?? '');
    bool activa = row?['activo'] ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(row == null ? 'Nueva categoría' : 'Editar categoría'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombre,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  maxLength: 60,
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Requerido';
                    if (s.length > 60) return 'Máximo 60 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: edadMin,
                        decoration: const InputDecoration(labelText: 'Edad mínima (opcional)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: edadMax,
                        decoration: const InputDecoration(labelText: 'Edad máxima (opcional)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: activa,
                  onChanged: (v) => setState(() => activa = v),
                  title: const Text('Activa'),
                  contentPadding: EdgeInsets.zero,
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
                if (row == null) {
                  await _repo.crear(
                    nombre: nombre.text.trim(),
                    edadMin: int.tryParse(edadMin.text.trim()),
                    edadMax: int.tryParse(edadMax.text.trim()),
                    activa: activa,
                  );
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Categoría creada')));
                } else {
                  await _repo.update(
                    idCategoria: (row['id'] as num).toInt(),
                    nombre: nombre.text.trim(),
                    edadMin: int.tryParse(edadMin.text.trim()),
                    edadMax: int.tryParse(edadMax.text.trim()),
                    activa: activa,
                  );
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Categoría actualizada')));
                }
                if (mounted) Navigator.pop(context, true);
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: Text(row == null ? 'Crear' : 'Guardar'),
          ),
        ],
      ),
    );

    if (ok == true) _loadCurrentTab();
  }


  Future<void> _toggleEstado(Map<String, dynamic> r) async {
    try {
      final id = (r['id'] as num).toInt();
      final activo = r['activo'] == true;
      if (activo) {
        await _repo.deactivate(id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Categoría desactivada')));
      } else {
        await _repo.activate(id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Categoría activada')));
      }
      _loadCurrentTab();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Material(
            color: Colors.transparent,
            child: TabBar(
              controller: _tab,
              onTap: (_) => _loadCurrentTab(),
              tabs: const [
                Tab(text: 'Activas'),
                Tab(text: 'Inactivas'),
                Tab(text: 'Todas'),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refrescar',
            onPressed: _loading ? null : _loadCurrentTab,
            icon: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
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
            child: TabBarView(
              controller: _tab,
              children: [
                _CatTable(
                  rows: _act,
                  total: _actTotal,
                  page: _actPage,
                  pageSize: _actPageSize,
                  sortField: _actSort,
                  sortAscending: _actAsc,
                  onSort: (f, asc) {
                    setState(() { _actSort = f; _actAsc = asc; _actPage = 1; });
                    _loadActivas();
                  },
                  onPageChange: (p) { setState(() => _actPage = p); _loadActivas(); },
                  onEdit: _newOrEdit,
                 
                  onToggleEstado: _toggleEstado,
                ),
                _CatTable(
                  rows: _ina,
                  total: _inaTotal,
                  page: _inaPage,
                  pageSize: _inaPageSize,
                  sortField: _inaSort,
                  sortAscending: _inaAsc,
                  onSort: (f, asc) {
                    setState(() { _inaSort = f; _inaAsc = asc; _inaPage = 1; });
                    _loadInactivas();
                  },
                  onPageChange: (p) { setState(() => _inaPage = p); _loadInactivas(); },
                  onEdit: _newOrEdit,
                  
                  onToggleEstado: _toggleEstado,
                ),
                _CatTable(
                  rows: _all,
                  total: _allTotal,
                  page: _allPage,
                  pageSize: _allPageSize,
                  sortField: _allSort,
                  sortAscending: _allAsc,
                  onSort: (f, asc) {
                    setState(() { _allSort = f; _allAsc = asc; _allPage = 1; });
                    _loadTodas();
                  },
                  onPageChange: (p) { setState(() => _allPage = p); _loadTodas(); },
                  onEdit: _newOrEdit,
                
                  onToggleEstado: _toggleEstado,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newOrEdit(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva categoría'),
      ),
    );
  }

  Widget _toolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: LayoutBuilder(
        builder: (ctx, c) {
          final narrow = c.maxWidth < 600;
          final search = TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar por nombre…',
            ),
            onSubmitted: (_) {
              switch (_tab.index) {
                case 0: _actPage = 1; _loadActivas(); break;
                case 1: _inaPage = 1; _loadInactivas(); break;
                default: _allPage = 1; _loadTodas(); break;
              }
            },
          );

          final perPage = DropdownButtonFormField<int>(
            value: switch (_tab.index) {
              0 => _actPageSize,
              1 => _inaPageSize,
              _ => _allPageSize,
            },
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.format_list_numbered),
              labelText: 'Por página',
            ),
            items: const [
              DropdownMenuItem(value: 10, child: Text('10')),
              DropdownMenuItem(value: 20, child: Text('20')),
              DropdownMenuItem(value: 50, child: Text('50')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                if (_tab.index == 0) { _actPageSize = v; _actPage = 1; }
                else if (_tab.index == 1) { _inaPageSize = v; _inaPage = 1; }
                else { _allPageSize = v; _allPage = 1; }
              });
              _loadCurrentTab();
            },
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                search,
                const SizedBox(height: 8),
                perPage,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: 8),
              SizedBox(width: 140, child: perPage),
            ],
          );
        },
      ),
    );
  }
}

class _CatTable extends StatelessWidget {
  const _CatTable({
    required this.rows,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    required this.onPageChange,
    required this.onEdit,
 
    required this.onToggleEstado,
  });

  final List<Map<String, dynamic>> rows;
  final int total, page, pageSize;
  final String sortField;
  final bool sortAscending;
  final void Function(String field, bool asc) onSort;
  final void Function(int newPage) onPageChange;
  final Future<void> Function({Map<String, dynamic>? row}) onEdit;
 
  final Future<void> Function(Map<String, dynamic>) onToggleEstado;

  int get _sortIndex {
    switch (sortField) {
      case 'id_categoria': return 0;
      case 'nombre_categoria': return 1;
      case 'edad_minima': return 2;
      case 'edad_maxima': return 2;
      default: return 3; // creado_en
    }
  }

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(child: Text('Sin resultados'));
    }

    final from = (total == 0) ? 0 : ((page - 1) * pageSize + 1);
    final to = ((page * pageSize) > total) ? total : (page * pageSize);
    final asc = sortAscending;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final wide = constraints.maxWidth > 700;

        // --------- Mobile (cards) ---------
        if (!wide) {
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = rows[i];
                    final edad = [
                      r['edadMin']?.toString(),
                      r['edadMax']?.toString(),
                    ].where((e) => e != null && e.isNotEmpty).join(' - ');
                    final activo = r['activo'] == true;

                    return Card(
                      child: ListTile(
                        title: Text(r['nombre'] ?? ''),
                        subtitle: Text(edad.isEmpty ? 'Sin rango de edad' : 'Edad: $edad'),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(icon: const Icon(Icons.edit), onPressed: () => onEdit(row: r)),
                            IconButton(
                              icon: Icon(activo ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => onToggleEstado(r),
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
                    Text('Mostrando $from–$to de $total'),
                    const Spacer(),
                    IconButton(
                      onPressed: (page > 1) ? () => onPageChange(page - 1) : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('$page'),
                    IconButton(
                      onPressed: (to < total) ? () => onPageChange(page + 1) : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        // --------- Desktop (tabla) ---------
        DataColumn col(String label, String key) => DataColumn(
          label: InkWell(
            onTap: () => onSort(key, (sortField == key) ? !asc : true),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (sortField == key) Icon(asc ? Icons.arrow_drop_up : Icons.arrow_drop_down),
              ],
            ),
          ),
        );

        final table = SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          scrollDirection: Axis.horizontal,
          child: DataTable(
            sortColumnIndex: _sortIndex,
            sortAscending: asc,
            columns: [
              col('ID', 'id_categoria'),
              col('Nombre', 'nombre_categoria'),
              col('Edad', 'edad_minima'),
              col('Creado', 'creado_en'),
              const DataColumn(label: Text('Estado')),
              const DataColumn(label: Text('Acciones')),
            ],
            rows: rows.map((r) {
              final edad = [
                r['edadMin']?.toString(),
                r['edadMax']?.toString(),
              ].where((e) => e != null && e.isNotEmpty).join(' - ');
              final activo = r['activo'] == true;

              return DataRow(cells: [
                DataCell(Text('${r['id'] ?? ''}')),
                DataCell(Text(r['nombre'] ?? '')),
                DataCell(Text(edad.isEmpty ? '—' : edad)),
                DataCell(Text('${r['creadoEn'] ?? ''}')),
                DataCell(Icon(activo ? Icons.check_circle : Icons.cancel)),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => onEdit(row: r)),
                    IconButton(
                      icon: Icon(activo ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => onToggleEstado(r),
                    ),
                  
                  ],
                )),
              ]);
            }).toList(),
          ),
        );

        final pager = Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              Text('Mostrando $from–$to de $total'),
              const Spacer(),
              IconButton(
                onPressed: (page > 1) ? () => onPageChange(page - 1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('$page'),
              IconButton(
                onPressed: (to < total) ? () => onPageChange(page + 1) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        );

        return Column(children: [Expanded(child: table), pager]);
      },
    );
  }
}

