import 'package:flutter/material.dart';
import '../state/auth_state.dart';
import '../services/session.dart';
import '../services/api_service.dart';

class PanelScreen extends StatefulWidget {
  const PanelScreen({super.key});

  @override
  State<PanelScreen> createState() => _PanelScreenState();
}

class _PanelScreenState extends State<PanelScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  bool _loading = false;
  String? _error;

  // ======== Estado por pestaña ========
  // Activos
  List<Map<String, dynamic>> _activos = [];
  int _activosTotal = 0;
  int _activosPage = 1;
  int _activosPageSize = 10;
  String _activosSort = 'creado_en';
  bool _activosAsc = false;

  // Inactivos
  List<Map<String, dynamic>> _inactivos = [];
  int _inactivosTotal = 0;
  int _inactivosPage = 1;
  int _inactivosPageSize = 10;
  String _inactivosSort = 'creado_en';
  bool _inactivosAsc = false;

  // Todos
  List<Map<String, dynamic>> _todos = [];
  int _todosTotal = 0;
  int _todosPage = 1;
  int _todosPageSize = 10;
  String _todosSort = 'creado_en';
  bool _todosAsc = false;

  // búsqueda
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this)
      ..addListener(() {
        // Se llama cuando cambias por swipe o ya terminó el cambio
        if (!_tab.indexIsChanging) _loadCurrentTab();
      });
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    final auth = AuthScope.of(context);
    if (auth.isAdmin) {
      await _loadCurrentTab();
    }
  }

  Future<void> _loadCurrentTab() async {
    switch (_tab.index) {
      case 0:
        return _loadActivos();
      case 1:
        return _loadInactivos();
      case 2:
        return _loadTodos();
    }
  }

  Future<void> _loadActivos() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await Session.getToken();
      if (token == null) throw Exception('Sesión expirada');
      final res = await ApiService.getUsuariosActivosPaged(
        token,
        page: _activosPage,
        pageSize: _activosPageSize,
        q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        sort: _activosSort,
        order: _activosAsc ? 'asc' : 'desc',
      );
      setState(() {
        _activos = List<Map<String, dynamic>>.from(res['items']);
        _activosTotal = (res['total'] as num).toInt();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadInactivos() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await Session.getToken();
      if (token == null) throw Exception('Sesión expirada');
      final res = await ApiService.getUsuariosInactivosPaged(
        token,
        page: _inactivosPage,
        pageSize: _inactivosPageSize,
        q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        sort: _inactivosSort,
        order: _inactivosAsc ? 'asc' : 'desc',
      );
      setState(() {
        _inactivos = List<Map<String, dynamic>>.from(res['items']);
        _inactivosTotal = (res['total'] as num).toInt();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadTodos() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await Session.getToken();
      if (token == null) throw Exception('Sesión expirada');
      final res = await ApiService.getUsuariosTodosPaged(
        token,
        page: _todosPage,
        pageSize: _todosPageSize,
        q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        sort: _todosSort,
        order: _todosAsc ? 'asc' : 'desc',
      );
      setState(() {
        _todos = List<Map<String, dynamic>>.from(res['items']);
        _todosTotal = (res['total'] as num).toInt();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _rolLabel(dynamic idRol) {
    switch ((idRol as num?)?.toInt()) {
      case 1:
        return 'Admin';
      case 2:
        return 'Profesor';
      default:
        return 'Padre';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final isAdmin = auth.isAdmin;
    final isTeacher = auth.isTeacher;

    if (!isAdmin && !isTeacher) {
      return Scaffold(
        appBar: AppBar(title: const Text('Panel')),
        body: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.block, size: 48),
                  const SizedBox(height: 12),
                  const Text('No tienes acceso al panel'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/', (r) => false),
                    child: const Text('Volver al inicio'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel'),
        bottom: isAdmin
            ? TabBar(
                controller: _tab,
                onTap: (_) => _loadCurrentTab(),
                tabs: const [
                  Tab(text: 'Usuarios activos'),
                  Tab(text: 'Usuarios inactivos'),
                  Tab(text: 'Todos'),
                ],
              )
            : null,
      ),
      body: isAdmin ? _buildAdmin(cs) : _buildTeacher(),
    );
  }

  // ===================== ADMIN ======================
  Widget _buildAdmin(ColorScheme cs) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: LayoutBuilder(
            builder: (ctx, c) {
              final narrow = c.maxWidth < 600;

              // --- MÓVIL: columna apilada ---
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Buscar por nombre/correo…',
                      ),
                      onSubmitted: (_) => _loadCurrentTab(),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: switch (_tab.index) {
                        0 => _activosPageSize,
                        1 => _inactivosPageSize,
                        _ => _todosPageSize,
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
                          if (_tab.index == 0) {
                            _activosPageSize = v;
                            _activosPage = 1;
                          } else if (_tab.index == 1) {
                            _inactivosPageSize = v;
                            _inactivosPage = 1;
                          } else {
                            _todosPageSize = v;
                            _todosPage = 1;
                          }
                        });
                        _loadCurrentTab();
                      },
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _loading ? null : _loadCurrentTab,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: const Text('Refrescar'),
                    ),
                  ],
                );
              }

              // --- ESCRITORIO: fila ---
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Buscar por nombre/correo…',
                      ),
                      onSubmitted: (_) => _loadCurrentTab(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 140,
                    child: DropdownButtonFormField<int>(
                      value: switch (_tab.index) {
                        0 => _activosPageSize,
                        1 => _inactivosPageSize,
                        _ => _todosPageSize,
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
                          if (_tab.index == 0) {
                            _activosPageSize = v;
                            _activosPage = 1;
                          } else if (_tab.index == 1) {
                            _inactivosPageSize = v;
                            _inactivosPage = 1;
                          } else {
                            _todosPageSize = v;
                            _todosPage = 1;
                          }
                        });
                        _loadCurrentTab();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Refrescar',
                    onPressed: _loading ? null : _loadCurrentTab,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                  ),
                ],
              );
            },
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(_error!, style: TextStyle(color: cs.error)),
            ),
          ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _UsersTable(
                rows: _activos,
                inactiveTable: false,
                sortField: _activosSort,
                sortAscending: _activosAsc,
                total: _activosTotal,
                page: _activosPage,
                pageSize: _activosPageSize,
                onSort: (field, asc) {
                  setState(() {
                    _activosSort = field;
                    _activosAsc = asc;
                    _activosPage = 1;
                  });
                  _loadActivos();
                },
                onPageChange: (p) {
                  setState(() => _activosPage = p);
                  _loadActivos();
                },
                onEdit: _openEditUserDialog,
                onDelete: _confirmDesactivar,
                onActivate: _activateUser,
                rolLabel: _rolLabel,
              ),
              _UsersTable(
                rows: _inactivos,
                inactiveTable: true,
                sortField: _inactivosSort,
                sortAscending: _inactivosAsc,
                total: _inactivosTotal,
                page: _inactivosPage,
                pageSize: _inactivosPageSize,
                onSort: (field, asc) {
                  setState(() {
                    _inactivosSort = field;
                    _inactivosAsc = asc;
                    _inactivosPage = 1;
                  });
                  _loadInactivos();
                },
                onPageChange: (p) {
                  setState(() => _inactivosPage = p);
                  _loadInactivos();
                },
                onEdit: _openEditUserDialog,
                onDelete: _confirmDesactivar,
                onActivate: _activateUser,
                rolLabel: _rolLabel,
              ),
              _UsersTable(
                rows: _todos,
                inactiveTable: false,
                sortField: _todosSort,
                sortAscending: _todosAsc,
                total: _todosTotal,
                page: _todosPage,
                pageSize: _todosPageSize,
                onSort: (field, asc) {
                  setState(() {
                    _todosSort = field;
                    _todosAsc = asc;
                    _todosPage = 1;
                  });
                  _loadTodos();
                },
                onPageChange: (p) {
                  setState(() => _todosPage = p);
                  _loadTodos();
                },
                onEdit: _openEditUserDialog,
                onDelete: _confirmDesactivar,
                onActivate: _activateUser,
                rolLabel: _rolLabel,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =================== PROFESOR =====================
  Widget _buildTeacher() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.school, size: 48),
            SizedBox(height: 12),
            Text('Panel de profesor',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            SizedBox(height: 8),
            Text(
              'Próximamente: gestión de grupos, asistencia, evaluaciones, eventos…',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ===== acciones: editar / desactivar / activar =====
  Future<void> _openEditUserDialog(Map<String, dynamic> u) async {
    final formKey = GlobalKey<FormState>();
    final nombre = TextEditingController(text: u['nombre']?.toString() ?? '');
    final correo = TextEditingController(text: u['correo']?.toString() ?? '');
    int idRol = (u['id_rol'] as int?) ?? 3;

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar usuario'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombre,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Requerido';
                    if (s.length > 40) return 'Máximo 40 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: correo,
                  decoration: const InputDecoration(labelText: 'Correo'),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Requerido';
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(s)) {
                      return 'Correo inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: idRol,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Admin')),
                    DropdownMenuItem(value: 2, child: Text('Profesor')),
                    DropdownMenuItem(value: 3, child: Text('Padre')),
                  ],
                  onChanged: (v) => idRol = v ?? 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final token = await Session.getToken();
                if (token == null) throw Exception('Sesión expirada');
                await ApiService.putUsuario(
                  token: token,
                  idUsuario: (u['id_usuario'] as num).toInt(),
                  nombre: nombre.text.trim(),
                  correo: correo.text.trim(),
                  idRol: idRol,
                );
                if (!mounted) return;
                Navigator.pop(context);
                await _loadCurrentTab();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Usuario actualizado')));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDesactivar(Map<String, dynamic> u) async {
    final id = (u['id_usuario'] as num?)?.toInt();
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desactivar usuario'),
        content: Text('¿Seguro que deseas desactivar a "${u['nombre']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí, desactivar')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final token = await Session.getToken();
      if (token == null) throw Exception('Sesión expirada');
      await ApiService.deleteUsuario(token: token, idUsuario: id);
      await _loadCurrentTab();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario desactivado')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _activateUser(Map<String, dynamic> u) async {
    final id = (u['id_usuario'] as num?)?.toInt();
    if (id == null) return;
    try {
      final token = await Session.getToken();
      if (token == null) throw Exception('Sesión expirada');
      await ApiService.putUsuario(
        token: token,
        idUsuario: id,
        nombre: (u['nombre'] ?? '').toString(),
        correo: (u['correo'] ?? '').toString(),
        idRol: (u['id_rol'] as num?)?.toInt() ?? 3,
        activo: true, // activar
      );
      await _loadCurrentTab();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario activado')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

// ==================== Tabla / Lista reutilizable ====================
class _UsersTable extends StatelessWidget {
  const _UsersTable({
    required this.rows,
    required this.inactiveTable,
    required this.sortField,
    required this.sortAscending,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.onSort,
    required this.onPageChange,
    required this.onEdit,
    required this.onDelete,
    required this.onActivate,
    required this.rolLabel,
  });

  final List<Map<String, dynamic>> rows;
  final bool inactiveTable;
  final String sortField;
  final bool sortAscending;
  final int total;
  final int page;
  final int pageSize;
  final void Function(String field, bool asc) onSort;
  final void Function(int newPage) onPageChange;
  final Future<void> Function(Map<String, dynamic>) onEdit;
  final Future<void> Function(Map<String, dynamic>) onDelete;
  final Future<void> Function(Map<String, dynamic>) onActivate;
  final String Function(dynamic idRol) rolLabel;

  int get _sortColumnIndex {
    switch (sortField) {
      case 'id_usuario':
        return 0;
      case 'nombre':
        return 1;
      case 'correo':
        return 2;
      default:
        return 3; // creado_en
    }
  }

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(child: Text('Sin resultados'));
    }

    final from = (total == 0) ? 0 : ((page - 1) * pageSize + 1);
    final to = ((page * pageSize) > total) ? total : (page * pageSize);

    return LayoutBuilder(
      builder: (ctx, c) {
        final wide = c.maxWidth > 700;

        // ====== Vista móvil: tarjetas ======
        if (!wide) {
          final list = ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final u = rows[i];
              final name = (u['nombre'] ?? '').toString();
              final email = (u['correo'] ?? '').toString();
              final rol = rolLabel(u['id_rol']);
              final created = (u['creado_en'] ?? '').toString();
              final avatar = (u['avatar_url'] ?? '').toString();

              return Card(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage:
                            avatar.isNotEmpty ? NetworkImage(avatar) : null,
                        child:
                            avatar.isEmpty ? const Icon(Icons.person) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(email, style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 2),
                            Text('Rol: $rol  •  $created',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: () => onEdit(u),
                        icon: const Icon(Icons.edit),
                      ),
                      if (inactiveTable)
                        IconButton(
                          tooltip: 'Activar',
                          onPressed: () => onActivate(u),
                          icon: const Icon(Icons.person_add_alt_1),
                        )
                      else
                        IconButton(
                          tooltip: 'Desactivar',
                          onPressed: () => onDelete(u),
                          icon: const Icon(Icons.person_off),
                        ),
                    ],
                  ),
                ),
              );
            },
          );

          final pager = Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Text('Mostrando $from–$to de $total'),
                const Spacer(),
                IconButton(
                  tooltip: 'Anterior',
                  onPressed:
                      (page > 1) ? () => onPageChange(page - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('$page'),
                IconButton(
                  tooltip: 'Siguiente',
                  onPressed: (to < total)
                      ? () => onPageChange(page + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          );

          return Column(children: [Expanded(child: list), pager]);
        }

        // ====== Vista escritorio: DataTable ======
        final table = SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: DataTable(
            sortColumnIndex: _sortColumnIndex,
            sortAscending: sortAscending,
            columns: [
              DataColumn(
                label: const Text('ID'),
                onSort: (_, asc) => onSort('id_usuario', asc),
              ),
              DataColumn(
                label: const Text('Nombre'),
                onSort: (_, asc) => onSort('nombre', asc),
              ),
              DataColumn(
                label: const Text('Correo'),
                onSort: (_, asc) => onSort('correo', asc),
              ),
              DataColumn(
                label: const Text('Creado'),
                onSort: (_, asc) => onSort('creado_en', asc),
              ),
              const DataColumn(label: Text('Rol')),
              const DataColumn(label: Text('Acciones')),
            ],
            rows: rows.map((u) {
              return DataRow(cells: [
                DataCell(Text('${u['id_usuario']}')),
                DataCell(Text(u['nombre'] ?? '')),
                DataCell(Text(u['correo'] ?? '')),
                DataCell(Text('${u['creado_en'] ?? ''}')),
                DataCell(Text(rolLabel(u['id_rol']))),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Editar',
                      onPressed: () => onEdit(u),
                      icon: const Icon(Icons.edit),
                    ),
                    if (inactiveTable)
                      IconButton(
                        tooltip: 'Activar',
                        onPressed: () => onActivate(u),
                        icon: const Icon(Icons.person_add_alt_1),
                      )
                    else
                      IconButton(
                        tooltip: 'Desactivar',
                        onPressed: () => onDelete(u),
                        icon: const Icon(Icons.person_off),
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
                tooltip: 'Anterior',
                onPressed: (page > 1) ? () => onPageChange(page - 1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('$page'),
              IconButton(
                tooltip: 'Siguiente',
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
