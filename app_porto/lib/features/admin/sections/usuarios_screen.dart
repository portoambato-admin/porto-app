import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/app_scope.dart';
import '../data/usuarios_repository.dart';
import '../models/usuario_model.dart';

// --- Clase auxiliar para guardar el estado de CADA pestaña ---
class _TabState {
  List<Usuario> items = [];
  int total = 0;
  int page = 1;
  int pageSize = 10;
  String sort = 'creado_en';
  bool asc = false;
}

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> with SingleTickerProviderStateMixin {
  late UsuariosRepository _repo;
  late final TabController _tab;
  
  // Estado global de la UI
  bool _loading = false;
  String? _error;
  Timer? _debounce;
  final TextEditingController _searchCtrl = TextEditingController();

  final List<_TabState> _tabsData = [
    _TabState(), // Activos
    _TabState(), // Inactivos
    _TabState(), // Todos
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (!_tab.indexIsChanging) {
          if (_tabsData[_tab.index].items.isEmpty) {
            _loadData();
          } else {
            setState(() {});
          }
        }
      });
      
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo = AppScope.of(context).usuarios;
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // --- Lógica de Carga Unificada ---
  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final index = _tab.index;
      final state = _tabsData[index];

      PagedResult<Usuario> res;

      if (index == 0) {
        res = await _repo.pagedActivos(
          page: state.page,
          pageSize: state.pageSize,
          q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
          sort: state.sort,
          order: state.asc ? 'asc' : 'desc',
        );
      } else if (index == 1) {
        res = await _repo.pagedInactivos(
          page: state.page,
          pageSize: state.pageSize,
          q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
          sort: state.sort,
          order: state.asc ? 'asc' : 'desc',
        );
      } else {
        res = await _repo.pagedTodos(
          page: state.page,
          pageSize: state.pageSize,
          q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
          sort: state.sort,
          order: state.asc ? 'asc' : 'desc',
        );
      }

      setState(() {
        state.items = res.items;
        state.total = res.total;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _tabsData[_tab.index].page = 1;
      _loadData();
    });
  }

  void _onSort(String field, bool asc) {
    setState(() {
      final state = _tabsData[_tab.index];
      state.sort = field;
      state.asc = asc;
      state.page = 1; 
    });
    _loadData();
  }

  void _onPageChange(int p) {
    setState(() => _tabsData[_tab.index].page = p);
    _loadData();
  }

  void _onPageSizeChange(int size) {
    setState(() {
      final state = _tabsData[_tab.index];
      state.pageSize = size;
      state.page = 1;
    });
    _loadData();
  }

  bool get _isCurrentUserAdmin {
    // TODO: Conectar con Provider/Bloc real
    return true; 
  }

  // --- ESTILOS COMPARTIDOS ---
  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 22),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  // --- DIÁLOGO CREAR USUARIO ---
  Future<void> _openCreateUserDialog() async {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final correoCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    
    int idRol = UserRole.usuario.id; 
    bool obscurePass = true;
    bool isSaving = false;

    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (innerContext, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Column(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(Icons.person_add, size: 30, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 16),
                const Text('Nuevo Usuario', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nombreCtrl,
                        decoration: _inputDeco('Nombre completo', Icons.person_outline),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) {
                          if (v == null || v.trim().length < 3) return 'Mínimo 3 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: correoCtrl,
                        decoration: _inputDeco('Correo electrónico', Icons.email_outlined),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          final regex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                          if (v == null || v.isEmpty) return 'Requerido';
                          if (!regex.hasMatch(v)) return 'Correo inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passCtrl,
                        obscureText: obscurePass,
                        decoration: _inputDeco('Contraseña', Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setStateDialog(() => obscurePass = !obscurePass),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: idRol,
                        decoration: _inputDeco('Rol asignado', Icons.badge_outlined),
                        items: UserRole.values.map((r) => 
                          DropdownMenuItem(value: r.id, child: Text(r.label))
                        ).toList(),
                        onChanged: (v) => idRol = v ?? idRol,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext), 
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey))
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSaving ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  
                  setStateDialog(() => isSaving = true);
                  
                  try {
                    await _repo.create(
                      nombre: nombreCtrl.text.trim(),
                      correo: correoCtrl.text.trim(),
                      password: passCtrl.text,
                      idRol: idRol,
                    );
                    
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('✅ Usuario registrado exitosamente'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      _loadData();
                    }
                  } catch (e) {
                    setStateDialog(() => isSaving = false);
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Registrar'),
              ),
            ],
          );
        }
      ),
    );
  }

  // --- DIÁLOGO EDITAR USUARIO ---
  Future<void> _openEditUserDialog(Usuario u) async {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(text: u.nombre);
    final correoCtrl = TextEditingController(text: u.correo);
    int idRol = u.rol.id;
    bool isSaving = false;

    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (innerContext, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Column(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.blue.shade50,
                  child: Icon(Icons.edit, size: 28, color: Colors.blue.shade700),
                ),
                const SizedBox(height: 16),
                const Text('Editar Usuario', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nombreCtrl,
                        decoration: _inputDeco('Nombre completo', Icons.person_outline),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) {
                          if (v == null || v.trim().length < 3) return 'Mínimo 3 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: correoCtrl,
                        decoration: _inputDeco('Correo electrónico', Icons.email_outlined),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          final regex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                          if (v == null || v.isEmpty) return 'Requerido';
                          if (!regex.hasMatch(v)) return 'Correo inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: idRol,
                        decoration: _inputDeco('Rol asignado', Icons.badge_outlined),
                        items: UserRole.values.map((r) => 
                          DropdownMenuItem(value: r.id, child: Text(r.label))
                        ).toList(),
                        onChanged: (v) => idRol = v ?? idRol,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext), 
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey))
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSaving ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  
                  setStateDialog(() => isSaving = true);
                  
                  try {
                    await _repo.update(
                      idUsuario: u.id, 
                      nombre: nombreCtrl.text.trim(), 
                      correo: correoCtrl.text.trim(), 
                      idRol: idRol
                    );
                    
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    
                    if (mounted) {
                      messenger.showSnackBar(const SnackBar(content: Text('✅ Usuario actualizado')));
                      _loadData();
                    }
                  } catch (e) {
                    setStateDialog(() => isSaving = false);
                    if (mounted) {
                      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                child: isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Guardar Cambios'),
              ),
            ],
          );
        }
      ),
    );
  }

  // --- UI Principal ---
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentState = _tabsData[_tab.index]; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Activos'),
            Tab(text: 'Inactivos'),
            Tab(text: 'Todos'),
          ],
        ),
        actions: [
            IconButton(
            tooltip: 'Refrescar',
            onPressed: _loading ? null : _loadData,
            icon: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: _isCurrentUserAdmin 
        ? FloatingActionButton.extended(
            onPressed: _openCreateUserDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Nuevo Usuario'),
            backgroundColor: cs.primaryContainer,
            foregroundColor: cs.onPrimaryContainer,
          )
        : null,
      
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Buscar por nombre, correo o cédula...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onSearchChanged('');
                            })
                        : null,
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<int>(
                    value: currentState.pageSize,
                    decoration: InputDecoration(
                      labelText: 'Filas',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: const [10, 20, 50, 100].map((s) => 
                      DropdownMenuItem(value: s, child: Text('$s'))
                    ).toList(),
                    onChanged: (v) => _onPageSizeChange(v ?? 10),
                  ),
                ),
              ],
            ),
          ),
          
          if (_error != null)
             Container(
               padding: const EdgeInsets.all(8),
               color: cs.errorContainer,
               width: double.infinity,
               child: Text(_error!, style: TextStyle(color: cs.onErrorContainer)),
             ),

          Expanded(
            child: _UsersTable(
              users: currentState.items,
              total: currentState.total,
              page: currentState.page,
              pageSize: currentState.pageSize,
              sortField: currentState.sort,
              sortAscending: currentState.asc,
              isInactiveTab: _tab.index == 1,
              onSort: _onSort,
              onPageChange: _onPageChange,
              onEdit: _openEditUserDialog,
              onToggleStatus: (u) => _toggleUserStatus(u, _tab.index == 1),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(Usuario u, bool isActivate) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(isActivate ? Icons.check_circle : Icons.warning_amber_rounded, 
                 color: isActivate ? Colors.green : Colors.orange),
            const SizedBox(width: 10),
            Text(isActivate ? 'Activar' : 'Desactivar'),
          ],
        ),
        content: Text('¿Confirmas ${isActivate ? 'activar' : 'desactivar'} a ${u.nombre}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isActivate ? Colors.green : Colors.redAccent
            ),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Confirmar')
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (isActivate) {
        await _repo.activate(u.id);
      } else {
        await _repo.remove(u.id);
      }
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isActivate ? 'Usuario activado' : 'Usuario desactivado')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

// --- Widget de Tabla Reutilizable y Responsive ---

class _UsersTable extends StatelessWidget {
  final List<Usuario> users;
  final int total;
  final int page;
  final int pageSize;
  final String sortField;
  final bool sortAscending;
  final bool isInactiveTab;
  final Function(String, bool) onSort;
  final Function(int) onPageChange;
  final Function(Usuario) onEdit;
  final Function(Usuario) onToggleStatus;

  const _UsersTable({
    required this.users,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.sortField,
    required this.sortAscending,
    required this.isInactiveTab,
    required this.onSort,
    required this.onPageChange,
    required this.onEdit,
    required this.onToggleStatus,
  });

  int get _sortColIndex {
    switch (sortField) {
      case 'cedula': return 0;
      case 'nombre': return 1;
      case 'correo': return 2;
      case 'creado_en': return 3;
      default: return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No se encontraron usuarios', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    final from = (total == 0) ? 0 : ((page - 1) * pageSize + 1);
    final to = ((page * pageSize) > total) ? total : (page * pageSize);

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 700) {
                return _buildMobileList(context);
              } else {
                return _buildDesktopTable(context);
              }
            },
          ),
        ),
        
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.black12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '$from - $to de $total',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: page > 1 ? () => onPageChange(page - 1) : null,
                  ),
                  Container(
                    alignment: Alignment.center,
                    constraints: const BoxConstraints(minWidth: 32),
                    child: Text('$page', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: to < total ? () => onPageChange(page + 1) : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          sortColumnIndex: _sortColIndex,
          sortAscending: sortAscending,
          headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          columns: [
            DataColumn(label: const Text('Cédula'), onSort: (_, asc) => onSort('cedula', asc)),
            DataColumn(label: const Text('Nombre'), onSort: (_, asc) => onSort('nombre', asc)),
            DataColumn(label: const Text('Correo'), onSort: (_, asc) => onSort('correo', asc)),
            DataColumn(label: const Text('Creado'), onSort: (_, asc) => onSort('creado_en', asc)),
            const DataColumn(label: Text('Rol')),
            const DataColumn(label: Text('Acciones')),
          ],
          rows: users.map((u) {
            return DataRow(cells: [
              DataCell(Text(u.cedula ?? '—', style: const TextStyle(fontFamily: 'Monospace', color: Colors.blueGrey))),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: (u.avatarUrl != null) ? NetworkImage(u.avatarUrl!) : null,
                    backgroundColor: Colors.blue.shade50,
                    child: (u.avatarUrl == null) ? const Icon(Icons.person, size: 16, color: Colors.blue) : null,
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: Text(u.nombre, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500))),
                ],
              )),
              DataCell(Text(u.correo)),
              DataCell(Text(u.creadoEn.toString().split(' ')[0])),
              DataCell(_buildRoleBadge(u.rol)),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                    tooltip: 'Editar',
                    onPressed: () => onEdit(u),
                  ),
                  IconButton(
                    icon: Icon(
                      isInactiveTab ? Icons.check_circle_outline : Icons.block_outlined,
                      color: isInactiveTab ? Colors.green : Colors.red[300],
                      size: 20,
                    ),
                    tooltip: isInactiveTab ? 'Activar' : 'Desactivar',
                    onPressed: () => onToggleStatus(u),
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final u = users[i];
        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200)
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: (u.avatarUrl != null) ? NetworkImage(u.avatarUrl!) : null,
                      backgroundColor: Colors.blue.shade50,
                      child: (u.avatarUrl == null) ? const Icon(Icons.person, color: Colors.blue) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          _buildRoleBadge(u.rol),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueGrey),
                      onPressed: () => onEdit(u),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: Icon(
                        isInactiveTab ? Icons.check_circle : Icons.block,
                        color: isInactiveTab ? Colors.green : Colors.red[300],
                      ),
                      onPressed: () => onToggleStatus(u),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(),
                ),
                _buildMobileInfoRow(Icons.email_outlined, u.correo),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildMobileInfoRow(Icons.badge_outlined, u.cedula ?? 'Sin cédula')),
                    Text(
                      u.creadoEn.toString().split(' ')[0], 
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text, 
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(UserRole rol) {
    Color color;
    switch (rol) {
      case UserRole.admin: color = Colors.purple; break;
      case UserRole.profesor: color = Colors.orange; break;
      case UserRole.padre: color = Colors.blue; break;
      default: color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        rol.label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}