// ===========================================================
// lib/features/admin/sections/roles_screen.dart
// FUSIÓN FINAL A+B (solo 2 vistas) + DIALOGOS PREMIUM
// + LABELS (accesibilidad) en inputs e iconos
// ===========================================================

import 'dart:async';
import 'dart:convert';
import 'package:app_porto/core/services/session_token_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ====== UI GLOBAL ======
import 'package:app_porto/ui/components/entity_header.dart';
import 'package:app_porto/ui/components/breadcrumbs.dart';
import 'package:app_porto/core/config/app_env.dart';
import 'package:app_porto/core/rbac/permission_gate.dart';
import 'package:app_porto/core/rbac/forbidden.dart';
import '../presentation/admin_shell.dart';

// ====== ENUM PARA VISTAS ======
enum _ViewMode { cards, tableClassic }

class RolesScreen extends StatefulWidget {
  final bool embedded;
  const RolesScreen({super.key, this.embedded = false});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  String get _apiBase => AppEnv.apiBase;

  // --------------------------
  // ESTADOS
  // --------------------------
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  _ViewMode _viewMode = _ViewMode.cards;

  List<Map<String, dynamic>> _roles = [];
  bool _loadingRoles = false;
  String? _errorRoles;

  // FORM
  final _formNombreCtl = TextEditingController();
  final _formDescCtl = TextEditingController();

  // PERMISOS
  List<Map<String, dynamic>> _allPerms = [];
  bool _loadingPerms = false;
  String _filterPerms = '';
  final Set<int> _selectedPerms = {};

  // CACHE
  final Map<int, int> _permCountCache = {};
  final Map<int, List<String>> _permNamesCache = {};

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ===========================================================
  //                         HELPERS HTTP
  // ===========================================================

  String _join(String path) {
    final b = _apiBase.endsWith('/') ? _apiBase.substring(0, _apiBase.length - 1) : _apiBase;
    final p = path.startsWith('/') ? path.substring(1) : path;
    return '$b/$p';
  }

  Future<Map<String, String>> _headers() async {
    final token = await SessionTokenProvider.instance.readToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token'
    };
  }

  // ===========================================================
  //                      CARGA ROLES (A)
  // ===========================================================

  Future<void> _loadRoles() async {
    setState(() {
      _loadingRoles = true;
      _errorRoles = null;
    });

    try {
      final uri = Uri.parse(_join('/rbac/roles')).replace(
        queryParameters: {
          if (_searchCtrl.text.trim().isNotEmpty) 'q': _searchCtrl.text.trim(),
        },
      );

      final r = await http.get(uri, headers: await _headers());
      if (r.statusCode >= 400) throw 'HTTP ${r.statusCode}: ${r.body}';

      final data = jsonDecode(r.body);

      List<Map<String, dynamic>> items = [];
      if (data is Map) {
        items = List<Map<String, dynamic>>.from(
          data['items'] ?? data['rows'] ?? data['data'] ?? const [],
        );
      } else if (data is List) {
        items = List<Map<String, dynamic>>.from(data);
      }

      setState(() => _roles = items);
    } catch (e) {
      setState(() => _errorRoles = e.toString());
    } finally {
      if (mounted) setState(() => _loadingRoles = false);
    }
  }

  // ===========================================================
  //                         BUSCADOR
  // ===========================================================

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      // refresca el suffixIcon y dispara la carga
      if (mounted) setState(() {});
      _loadRoles();
    });
  }

  // ===========================================================
  //                    PERMISOS + CACHE
  // ===========================================================

  Future<void> _loadAllPerms() async {
    setState(() => _loadingPerms = true);
    try {
      final r = await http.get(Uri.parse(_join('/rbac/permisos')), headers: await _headers());
      if (r.statusCode >= 400) throw 'Error ${r.statusCode}';

      final data = jsonDecode(r.body);

      final list = data is List
          ? data
          : data is Map && data['items'] is List
              ? data['items']
              : data is Map && data['rows'] is List
                  ? data['rows']
                  : data is Map && data['data'] is List
                      ? data['data']
                      : const [];

      _allPerms = List<Map<String, dynamic>>.from(
        list.map((e) => Map<String, dynamic>.from(e)),
      )
        ..sort((a, b) {
          final an = (a['nombre'] ?? '').toString();
          final bn = (b['nombre'] ?? '').toString();
          return an.compareTo(bn);
        });
    } finally {
      if (mounted) setState(() => _loadingPerms = false);
    }
  }

  Future<List<Map<String, dynamic>>> _getRolePerms(int id) async {
    final r = await http.get(Uri.parse(_join('/rbac/roles/$id/permisos')), headers: await _headers());
    if (r.statusCode >= 400) throw 'Error ${r.statusCode}';

    final data = jsonDecode(r.body);
    final list = data is List ? data : (data['items'] ?? data['rows'] ?? data['data'] ?? const []);
    return List<Map<String, dynamic>>.from(list.map((e) => Map<String, dynamic>.from(e)));
  }

  Future<void> _warmPermSummary(int idRol) async {
    if (_permCountCache.containsKey(idRol)) return;
    try {
      final rows = await _getRolePerms(idRol);
      final names = rows.map((m) => (m['nombre'] ?? '').toString()).toList();
      if (!mounted) return;
      setState(() {
        _permCountCache[idRol] = names.length;
        _permNamesCache[idRol] = names;
      });
    } catch (_) {}
  }

  // ===========================================================
  //                        CRUD ROLES
  // ===========================================================

  Future<int?> _createRole({required String nombre, required String descripcion}) async {
    final r = await http.post(
      Uri.parse(_join('/rbac/roles')),
      headers: await _headers(),
      body: jsonEncode({'nombre': nombre, 'descripcion': descripcion}),
    );
    if (r.statusCode >= 400) throw r.body;

    final data = jsonDecode(r.body);
    return (data['id'] ?? data['id_rol']) as int?;
  }

  Future<void> _updateRole({required int idRol, required String nombre, required String descripcion}) async {
    final r = await http.put(
      Uri.parse(_join('/rbac/roles/$idRol')),
      headers: await _headers(),
      body: jsonEncode({'nombre': nombre, 'descripcion': descripcion}),
    );
    if (r.statusCode >= 400) throw r.body;
  }

  Future<void> _assignPerms(int idRol, Set<int> ids) async {
    await http.post(
      Uri.parse(_join('/rbac/roles/$idRol/permisos')),
      headers: await _headers(),
      body: jsonEncode({'permisosIds': ids.toList()}),
    );
    _warmPermSummary(idRol);
  }

  Future<void> _deleteOptimistic(Map<String, dynamic> role) async {
    final id = (role['id'] ?? role['id_rol']) as int?;
    if (id == null) return;

    final index = _roles.indexOf(role);
    setState(() => _roles.removeAt(index));

    try {
      final r = await http.delete(
        Uri.parse(_join('/rbac/roles/$id')),
        headers: await _headers(),
      );
      if (r.statusCode >= 400) throw r.body;
    } catch (_) {
      if (!mounted) return;
      setState(() => _roles.insert(index, role));
    }
  }

  // ===========================================================
  //                DIALOGO PREMIUM CREAR / EDITAR
  // ===========================================================

  Future<void> _openForm({Map<String, dynamic>? initial}) async {
    if (_allPerms.isEmpty) await _loadAllPerms();

    _selectedPerms.clear();
    _filterPerms = '';

    if (initial != null) {
      _formNombreCtl.text = (initial['nombre'] ?? '').toString();
      _formDescCtl.text = (initial['descripcion'] ?? '').toString();

      final idRol = (initial['id'] ?? initial['id_rol']) as int;
      try {
        final rows = await _getRolePerms(idRol);
        _selectedPerms.addAll(rows.map((m) => (m['id'] ?? m['id_permiso']) as int));
      } catch (_) {}
    } else {
      _formNombreCtl.clear();
      _formDescCtl.clear();
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final cs = Theme.of(context).colorScheme;

        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          backgroundColor: cs.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: StatefulBuilder(
            builder: (modalCtx, setModal) {
              final filteredPerms = _allPerms.where((p) {
                final name = (p['nombre'] ?? '').toString().toLowerCase();
                return name.contains(_filterPerms);
              }).toList();

              return SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ---------------- HEADER ----------------
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            cs.primary.withOpacity(0.75),
                            cs.primary.withOpacity(0.9),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white24,
                            child: Icon(
                              initial == null ? Icons.add_moderator : Icons.edit,
                              color: Colors.white,
                              size: 26,
                              semanticLabel: initial == null ? 'Crear rol' : 'Editar rol',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            initial == null ? 'Nuevo Rol' : 'Editar Rol',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Cerrar',
                            icon: const Icon(Icons.close, color: Colors.white, semanticLabel: 'Cerrar'),
                            onPressed: () => Navigator.pop(modalCtx),
                          ),
                        ],
                      ),
                    ),

                    // ----------------- CUERPO -----------------
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _formNombreCtl,
                              decoration: InputDecoration(
                                labelText: 'Nombre del rol',
                                hintText: 'Ej. Administrador, Profesor, Padre',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: _formDescCtl,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Descripción (opcional)',
                                hintText: 'Describe el propósito del rol',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 24),

                            Text(
                              'Permisos seleccionados: ${_selectedPerms.length}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),

                            TextField(
                              decoration: InputDecoration(
                                // LABEL aplicado
                                labelText: 'Filtrar permisos',
                                hintText: 'Escribe para buscar permisos...',
                                prefixIcon: const Icon(Icons.search, semanticLabel: 'Buscar permisos'),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                suffixIcon: _filterPerms.isNotEmpty
                                    ? IconButton(
                                        tooltip: 'Limpiar filtro',
                                        icon: const Icon(Icons.close, semanticLabel: 'Limpiar filtro'),
                                        onPressed: () => setModal(() => _filterPerms = ''),
                                      )
                                    : null,
                              ),
                              onChanged: (v) => setModal(() => _filterPerms = v.toLowerCase().trim()),
                            ),
                            const SizedBox(height: 12),

                            _loadingPerms
                                ? const Center(child: CircularProgressIndicator())
                                : Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: filteredPerms.map((p) {
                                      final id = (p['id'] ?? p['id_permiso']) as int;
                                      final selected = _selectedPerms.contains(id);
                                      final name = (p['nombre'] ?? '').toString();

                                      return FilterChip(
                                        label: Text(
                                          name,
                                          style: TextStyle(
                                            color: selected ? cs.onPrimary : null,
                                            fontWeight: selected ? FontWeight.bold : null,
                                          ),
                                        ),
                                        selected: selected,
                                        showCheckmark: true,
                                        selectedColor: cs.primary,
                                        onSelected: (v) => setModal(() {
                                          v ? _selectedPerms.add(id) : _selectedPerms.remove(id);
                                        }),
                                      );
                                    }).toList(),
                                  ),
                          ],
                        ),
                      ),
                    ),

                    // ----------------- FOOTER -----------------
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: cs.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          final nombre = _formNombreCtl.text.trim();
                          final desc = _formDescCtl.text;

                          if (nombre.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('El nombre es obligatorio')),
                            );
                            return;
                          }

                          try {
                            int idRol;

                            if (initial == null) {
                              idRol = await _createRole(nombre: nombre, descripcion: desc) ?? 0;
                            } else {
                              idRol = (initial['id'] ?? initial['id_rol']) as int;
                              await _updateRole(idRol: idRol, nombre: nombre, descripcion: desc);
                            }

                            await _assignPerms(idRol, _selectedPerms);

                            if (!mounted) return;
                            Navigator.pop(modalCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Rol "$nombre" guardado')),
                            );

                            _loadRoles();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        child: const Text('GUARDAR ROL', style: TextStyle(fontSize: 16)),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ===========================================================
  //                       PERMISOS SHEET
  // ===========================================================

  void _openPermsSheet(int idRol, String nombre) async {
    if (!_permNamesCache.containsKey(idRol)) {
      try {
        final rows = await _getRolePerms(idRol);
        final names = rows.map((m) => (m['nombre'] ?? '').toString()).toList();
        _permNamesCache[idRol] = names;
        _permCountCache[idRol] = names.length;
      } catch (_) {
        return;
      }
    }

    final names = _permNamesCache[idRol] ?? [];

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          runSpacing: 10,
          children: [
            Text('Permisos de "$nombre"', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            names.isEmpty
                ? const Text("Sin permisos asignados")
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: names.map((n) => Chip(label: Text(n))).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  //                         CARDS VIEW (A)
  // ===========================================================

  Widget _buildCardsView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _roles.length,
      itemBuilder: (ctx, i) {
        final r = _roles[i];
        final id = (r['id'] ?? r['id_rol']) as int;

        final count = _permCountCache[id] ??
            (r['permisos'] is List ? (r['permisos'] as List).length : null);

        if (count == null) _warmPermSummary(id);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // ICONO
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.security,
                    color: Colors.indigo.shade400,
                    size: 26,
                    semanticLabel: 'Rol',
                  ),
                ),

                const SizedBox(width: 18),

                // INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (r['nombre'] ?? '').toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (r['descripcion'] ?? '—').toString(),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 10),

                      // BADGE PERMISOS
                      Tooltip(
                        message: 'Ver permisos del rol',
                        child: InkWell(
                          onTap: () => _openPermsSheet(id, (r['nombre'] ?? '').toString()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.indigo.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${count ?? "..."}',
                                  style: TextStyle(
                                    color: Colors.indigo.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.vpn_key_outlined,
                                  size: 16,
                                  color: Colors.indigo.shade400,
                                  semanticLabel: 'Permisos',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Column(
                  children: [
                    IconButton(
                      tooltip: 'Editar rol',
                      icon: const Icon(Icons.edit_outlined, semanticLabel: 'Editar rol'),
                      onPressed: () => _openForm(initial: r),
                    ),
                    IconButton(
                      tooltip: 'Eliminar rol',
                      icon: const Icon(Icons.delete_outline, color: Colors.red, semanticLabel: 'Eliminar rol'),
                      onPressed: () => _deleteOptimistic(r),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================
  //                         TABLA CLÁSICA (A)
  // ===========================================================

  Widget _buildClassicTable() {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: cs.outlineVariant),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text("ID")),
              DataColumn(label: Text("Rol")),
              DataColumn(label: Text("Descripción")),
              DataColumn(label: Text("Permisos")),
              DataColumn(label: Text("Acciones")),
            ],
            rows: _roles.map((r) {
              final id = (r['id'] ?? r['id_rol']) as int;
              final count = _permCountCache[id] ??
                  (r['permisos'] is List ? (r['permisos'] as List).length : null);

              if (count == null) _warmPermSummary(id);

              return DataRow(
                cells: [
                  DataCell(Text("$id")),
                  DataCell(Text((r['nombre'] ?? '').toString())),
                  DataCell(Text((r['descripcion'] ?? '').toString())),
                  DataCell(
                    Tooltip(
                      message: 'Ver permisos del rol',
                      child: InkWell(
                        onTap: () => _openPermsSheet(id, (r['nombre'] ?? '').toString()),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: cs.primary.withOpacity(0.1),
                              ),
                              child: Text('${count ?? "..."}'),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.vpn_key_outlined, size: 16, semanticLabel: 'Permisos'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Editar rol',
                          icon: const Icon(Icons.edit_outlined, semanticLabel: 'Editar rol'),
                          onPressed: () => _openForm(initial: r),
                        ),
                        IconButton(
                          tooltip: 'Eliminar rol',
                          icon: const Icon(Icons.delete_outline, color: Colors.red, semanticLabel: 'Eliminar rol'),
                          onPressed: () => _deleteOptimistic(r),
                        ),
                      ],
                    ),
                  )
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ===========================================================
  //                         HEADER MODERNO (A)
  // ===========================================================

  Widget _buildHeader() {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          // BUSCADOR (con label)
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                setState(() {}); // refresca suffixIcon en vivo
                _onSearchChanged(v);
              },
              decoration: InputDecoration(
                labelText: 'Buscar rol',
                hintText: 'Nombre o descripción',
                prefixIcon: Icon(Icons.search, color: cs.primary, semanticLabel: 'Buscar'),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        tooltip: 'Limpiar búsqueda',
                        icon: const Icon(Icons.close, semanticLabel: 'Limpiar búsqueda'),
                        onPressed: () {
                          setState(() {
                            _searchCtrl.clear();
                          });
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // TOGGLE VISTAS (con tooltip)
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Vista tarjetas',
                  icon: Icon(
                    Icons.grid_view_rounded,
                    color: _viewMode == _ViewMode.cards ? cs.primary : cs.onSurfaceVariant,
                    semanticLabel: 'Vista tarjetas',
                  ),
                  onPressed: () => setState(() => _viewMode = _ViewMode.cards),
                ),
                Container(width: 1, height: 20, color: cs.outlineVariant.withOpacity(0.6)),
                IconButton(
                  tooltip: 'Vista tabla',
                  icon: Icon(
                    Icons.table_rows_rounded,
                    color: _viewMode == _ViewMode.tableClassic ? cs.primary : cs.onSurfaceVariant,
                    semanticLabel: 'Vista tabla',
                  ),
                  onPressed: () => setState(() => _viewMode = _ViewMode.tableClassic),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // NUEVO
          PermissionGate(
            any: const ['roles.create'],
            child: FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add, semanticLabel: 'Nuevo rol'),
              label: const Text("Nuevo"),
            ),
          )
        ],
      ),
    );
  }

  // ===========================================================
  //                        CONTENIDO
  // ===========================================================

  Widget _content() {
    Widget vista;

    if (_loadingRoles && _roles.isEmpty) {
      vista = const Center(child: CircularProgressIndicator());
    } else if (_roles.isEmpty) {
      vista = const Center(child: Text("No se encontraron roles"));
    } else {
      vista = _viewMode == _ViewMode.cards ? _buildCardsView() : _buildClassicTable();
    }

    return Column(
      children: [
        const EntityHeader(
          title: 'Roles y permisos',
          subtitle: 'Gestiona y controla el acceso al sistema',
        ),
        _buildHeader(),

        if (_errorRoles != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Theme.of(context).colorScheme.errorContainer,
            child: Text(
              _errorRoles!,
              style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
            ),
          ),

        Expanded(child: vista),
      ],
    );
  }

  // ===========================================================
  //                         BUILD
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _content();

    return AdminShell(
      current: AdminHub.personas,
      crumbs: const [Crumb('Admin'), Crumb('Personas'), Crumb('Roles')],
      child: PermissionGate(
        roles: const ['admin'],
        any: const ['roles.read'],
        fallback: const ForbiddenScreen(message: 'No tienes permiso'),
        child: _content(),
      ),
    );
  }
}
