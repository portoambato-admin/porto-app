// lib/features/admin/sections/roles_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:app_porto/ui/components/admin_data_table.dart';
import 'package:app_porto/ui/components/entity_header.dart';
import 'package:app_porto/ui/components/slide_over_form.dart';
import 'package:app_porto/ui/components/breadcrumbs.dart';
import 'package:app_porto/core/services/session.dart';
import 'package:app_porto/core/config/app_env.dart';
import 'package:app_porto/core/rbac/permission_gate.dart';
import 'package:app_porto/core/rbac/forbidden.dart';

import '../presentation/admin_shell.dart';

class RolesScreen extends StatefulWidget {
  final bool embedded;
  const RolesScreen({super.key, this.embedded = false});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  String get _apiBase => AppEnv.apiBase;

  final _formNombreCtl = TextEditingController();
  final _formDescCtl   = TextEditingController();

  // Permisos (de /rbac/permisos)
  List<Map<String, dynamic>> _allPerms = [];
  bool _loadingPerms = false;
  String _filterPerms = '';

  // Selección actual en el formulario (IDs)
  final Set<int> _selectedPerms = <int>{};

  // Cache para mostrar conteo/nombres en tabla sin N+1
  final Map<int, int> _permCountCache = {};          // idRol -> count
  final Map<int, List<String>> _permNamesCache = {}; // idRol -> nombres

  int _reloadTick = 0;

  @override
  void dispose() {
    _formNombreCtl.dispose();
    _formDescCtl.dispose();
    super.dispose();
  }

  // ========================= HTTP helpers =========================

  String _join(String path) {
    final b = _apiBase.endsWith('/') ? _apiBase.substring(0, _apiBase.length - 1) : _apiBase;
    final p = path.startsWith('/') ? path.substring(1) : path;
    return '$b/$p';
  }

  Future<Map<String, String>> _headers() async {
    final t = await Session.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  Future<void> _loadAllPerms() async {
    setState(() => _loadingPerms = true);
    try {
      final r = await http.get(Uri.parse(_join('/rbac/permisos')), headers: await _headers());
      if (r.statusCode >= 400) throw 'HTTP ${r.statusCode}: ${r.body}';
      final data = jsonDecode(r.body);
      final list = data is List
          ? data
          : (data is Map && data['items'] is List)
              ? data['items']
              : (data is Map && data['rows'] is List)
                  ? data['rows']
                  : (data is Map && data['data'] is List)
                      ? data['data']
                      : const [];
      _allPerms = (list as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        ..sort((a, b) => (a['nombre'] ?? '').toString().compareTo((b['nombre'] ?? '').toString()));
    } finally {
      if (mounted) setState(() => _loadingPerms = false);
    }
  }

  Future<List<Map<String, dynamic>>> _getRolePerms(int idRol) async {
    final r = await http.get(Uri.parse(_join('/rbac/roles/$idRol/permisos')), headers: await _headers());
    if (r.statusCode >= 400) throw 'HTTP ${r.statusCode}: ${r.body}';
    final data = jsonDecode(r.body);
    final list = data is List
        ? data
        : (data is Map && data['items'] is List)
            ? data['items']
            : (data is Map && data['rows'] is List)
                ? data['rows']
                : (data is Map && data['data'] is List)
                    ? data['data']
                    : const [];
    return (list as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _warmPermSummary(int idRol) async {
    if (_permCountCache.containsKey(idRol)) return;
    try {
      final rows  = await _getRolePerms(idRol);
      final names = rows.map((m) => (m['nombre'] ?? '').toString()).where((s) => s.isNotEmpty).toList();
      setState(() {
        _permCountCache[idRol] = names.length;
        _permNamesCache[idRol] = names;
      });
    } catch (_) {/* silent */}
  }

  Future<int?> _createRole({required String nombre, required String descripcion}) async {
    final r = await http.post(
      Uri.parse(_join('/rbac/roles')),
      headers: await _headers(),
      // Enviamos SIEMPRE 'descripcion' como string (permite guardar y también limpiar si backend lo trata a null)
      body: jsonEncode({
        'nombre': nombre,
        'descripcion': descripcion,
      }),
    );
    if (r.statusCode >= 400) throw 'HTTP ${r.statusCode}: ${r.body}';
    final ct = (r.headers['content-type'] ?? '').toLowerCase();
    if (ct.contains('application/json')) {
      final data = jsonDecode(r.body);
      if (data is Map) {
        if (data['id'] is num) return (data['id'] as num).toInt();
        if (data['id_rol'] is num) return (data['id_rol'] as num).toInt();
        if (data['data'] is Map && (data['data']['id'] is num)) return (data['data']['id'] as num).toInt();
      }
    }
    return null;
  }

  Future<void> _updateRole({required int idRol, required String nombre, required String descripcion}) async {
    final r = await http.put(
      Uri.parse(_join('/rbac/roles/$idRol')),
      headers: await _headers(),
      body: jsonEncode({
        'nombre': nombre,
        'descripcion': descripcion,
      }),
    );
    if (r.statusCode >= 400) throw 'HTTP ${r.statusCode}: ${r.body}';
  }

  Future<void> _assignPermsToRole({required int idRol, required Set<int> permisosIds}) async {
    final r = await http.post(
      Uri.parse(_join('/rbac/roles/$idRol/permisos')),
      headers: await _headers(),
      body: jsonEncode({'permisosIds': permisosIds.toList()}),
    );
    if (r.statusCode >= 400) throw 'HTTP ${r.statusCode}: ${r.body}';
    // cache inmediata para feedback instantáneo
    final names = _allPerms
        .where((p) => permisosIds.contains((p['id_permiso'] ?? p['id']) as int))
        .map((p) => (p['nombre'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toList();
    setState(() {
      _permCountCache[idRol] = names.length;
      _permNamesCache[idRol] = names;
    });
  }

  Future<void> _deleteRole(int idRol) async {
    final r = await http.delete(Uri.parse(_join('/rbac/roles/$idRol')), headers: await _headers());
    if (r.statusCode >= 400) throw 'HTTP ${r.statusCode}: ${r.body}';
  }

  // ========================= UI helpers =========================

  Future<void> _openPermsSheet(int idRol, String titulo) async {
    if (!_permNamesCache.containsKey(idRol)) {
      try {
        final rows  = await _getRolePerms(idRol);
        final names = rows.map((m) => (m['nombre'] ?? '').toString()).where((s) => s.isNotEmpty).toList();
        setState(() {
          _permCountCache[idRol] = names.length;
          _permNamesCache[idRol] = names;
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudieron leer permisos: $e')));
      }
    }
    if (!mounted) return;

    final names = _permNamesCache[idRol] ?? const <String>[];
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Permisos de "$titulo"', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (names.isEmpty)
                const Text('Este rol no tiene permisos asignados.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: names.map((n) => Chip(label: Text(n))).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openForm({Map<String, dynamic>? initial}) async {
    if (_allPerms.isEmpty) {
      try {
        await _loadAllPerms();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando permisos: $e')));
        return;
      }
    }

    _selectedPerms.clear();
    _filterPerms = '';

    if (initial != null) {
      _formNombreCtl.text = (initial['nombre'] ?? initial['rol'] ?? '').toString();
      _formDescCtl.text   = (initial['descripcion'] ?? initial['description'] ?? '').toString();
      final idRol = (initial['id'] ?? initial['id_rol']) as int?;
      if (idRol != null) {
        try {
          final rows = await _getRolePerms(idRol);
          _selectedPerms.addAll(rows.map((m) => (m['id_permiso'] ?? m['id']) as int));
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando permisos del rol: $e')));
        }
      }
    } else {
      _formNombreCtl.clear();
      _formDescCtl.clear();
    }

    // --- Abrimos el formulario con StatefulBuilder para que TODO reaccione dentro del modal ---
    await showAdminForm<void>(
      context,
      title: initial == null ? 'Nuevo rol' : 'Editar rol',
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () async {
            final nombre = _formNombreCtl.text.trim();
            final desc   = _formDescCtl.text; // se envía siempre
            if (nombre.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre del rol es obligatorio')));
              return;
            }
            try {
              int? idRol;
              if (initial == null) {
                idRol = await _createRole(nombre: nombre, descripcion: desc);
              } else {
                idRol = (initial['id'] ?? initial['id_rol']) as int?;
                if (idRol == null) throw 'ID de rol inválido';
                await _updateRole(idRol: idRol, nombre: nombre, descripcion: desc);
              }

              if (idRol != null) {
                await _assignPermsToRole(idRol: idRol, permisosIds: _selectedPerms);
              }

              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rol "$nombre" guardado')));
              setState(() => _reloadTick++);
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
            }
          },
          child: const Text('Guardar'),
        ),
      ],
      child: StatefulBuilder(
        builder: (ctx, setModal) {
          // Helpers que actualizan el estado DENTRO del modal
          void setModalSafe(VoidCallback fn) => setModal(fn);

          Widget selectedHeader() {
            return Row(
              children: [
                Text(
                  'Permisos seleccionados: ${_selectedPerms.length}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                if (_selectedPerms.isNotEmpty)
                  Tooltip(
                    message: 'Quitar todo',
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.clear_all),
                      onPressed: () => setModalSafe(() => _selectedPerms.clear()),
                    ),
                  ),
              ],
            );
          }

          Widget filterBox() {
            return TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Filtrar permisos por nombre…',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (s) => setModalSafe(() => _filterPerms = s.trim().toLowerCase()),
            );
          }

          Widget permisosWrap() {
            if (_loadingPerms) {
              return const Padding(
                padding: EdgeInsets.all(8),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (_allPerms.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(8),
                child: Text('No hay permisos definidos.'),
              );
            }
            final filtered = _filterPerms.isEmpty
                ? _allPerms
                : _allPerms.where((p) => (p['nombre'] ?? '').toString().toLowerCase().contains(_filterPerms)).toList();

            final cs = Theme.of(ctx).colorScheme;

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filtered.map((perm) {
                final id = (perm['id_permiso'] ?? perm['id']) as int;
                final nombre = (perm['nombre'] ?? '').toString();
                final selected = _selectedPerms.contains(id);

                return FilterChip(
                  label: Text(
                    nombre,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected ? cs.onPrimary : null,
                    ),
                  ),
                  selected: selected,
                  showCheckmark: true,
                  checkmarkColor: cs.onPrimary,
                  // Estilo MUY visible al seleccionar
                  backgroundColor: cs.surface,
                  selectedColor: cs.primary,
                  side: BorderSide(color: selected ? cs.primary : cs.outlineVariant, width: selected ? 2 : 1),
                  avatar: selected ? const Icon(Icons.check, size: 16) : null,
                  visualDensity: VisualDensity.compact,
                  onSelected: (v) {
                    setModalSafe(() {
                      if (v) {
                        _selectedPerms.add(id);
                      } else {
                        _selectedPerms.remove(id);
                      }
                    });
                  },
                );
              }).toList(),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _formNombreCtl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del rol',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _formDescCtl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                selectedHeader(),
                const SizedBox(height: 8),
                filterBox(),
                const SizedBox(height: 8),
                permisosWrap(),
              ],
            ),
          );
        },
      ),
    );
  }

  // ========================= Tabla =========================

  Widget _permCell(Map<String, dynamic> e) {
    final idRol = (e['id'] ?? e['id_rol']) as int?;
    final nombreRol = (e['nombre'] ?? e['rol'] ?? '').toString();
    if (idRol == null) return const Text('0');

    final backendCount = (e['permisos'] is List)
        ? (e['permisos'] as List).length
        : (e['permisos_count'] is num)
            ? (e['permisos_count'] as num).toInt()
            : (e['count'] is num)
                ? (e['count'] as num).toInt()
                : null;

    final cacheCount = _permCountCache[idRol];
    final count = backendCount ?? cacheCount ?? 0;

    if (backendCount == null && cacheCount == null) {
      _warmPermSummary(idRol);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.primary),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
          ),
          child: Text('$count'),
        ),
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'Ver permisos',
          icon: const Icon(Icons.visibility_outlined),
          onPressed: () => _openPermsSheet(idRol, nombreRol),
        ),
      ],
    );
  }

  Widget _table() {
    return AdminDataTable<Map<String, dynamic>>(
      key: ValueKey('roles_table_$_reloadTick'),
      searchHint: 'Buscar por nombre o descripción…',
      columns: [
        AdminColumn<Map<String, dynamic>>(
          label: 'ID',
          isNumeric: true,
          cellBuilder: (e) => Text('${e['id'] ?? e['id_rol'] ?? ''}'),
        ),
        AdminColumn<Map<String, dynamic>>(
          label: 'Rol',
          cellBuilder: (e) => Text('${e['nombre'] ?? e['rol'] ?? ''}'),
        ),
        AdminColumn<Map<String, dynamic>>(
          label: 'Descripción',
          cellBuilder: (e) {
            final s = (e['descripcion'] ?? e['description'] ?? '').toString().trim();
            return Tooltip(
              message: s.isEmpty ? '—' : s,
              child: Text(s.isEmpty ? '—' : s, maxLines: 2, overflow: TextOverflow.ellipsis),
            );
          },
        ),
        AdminColumn<Map<String, dynamic>>(
          label: 'Permisos',
          cellBuilder: _permCell,
        ),
      ],
      trailingBuilder: (e) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PermissionGate(
            any: const ['roles.update'],
            child: IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openForm(initial: e),
            ),
          ),
          PermissionGate(
            any: const ['roles.delete'],
            child: IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final id = e['id'] ?? e['id_rol'];
                if (id == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rol sin ID válido')));
                  return;
                }
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminar rol'),
                    content: Text('¿Seguro que quieres eliminar el rol "${e['nombre'] ?? e['rol']}"?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
                    ],
                  ),
                );
                if (confirm != true) return;

                try {
                  await _deleteRole(id as int);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rol eliminado')));
                  setState(() {
                    _reloadTick++;
                    _permCountCache.remove(id);
                    _permNamesCache.remove(id);
                  });
                } catch (err) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $err')));
                }
              },
            ),
          ),
        ],
      ),
      fetch: (q) async {
        final uri = Uri.parse(_join('/rbac/roles')).replace(
          queryParameters: {
            'page': '${q.page}',
            'limit': '${q.limit}',
            if ((q.q ?? '').isNotEmpty) 'q': q.q!,
          },
        );

        final r = await http.get(uri, headers: await _headers());
        if (r.statusCode >= 400) throw 'HTTP ${r.statusCode}: ${r.body}';

        final ct = (r.headers['content-type'] ?? '').toLowerCase();
        if (!ct.contains('application/json')) {
          final preview = r.body.length > 160 ? '${r.body.substring(0, 160)}…' : r.body;
          throw 'Respuesta no JSON (${r.statusCode}). Body: $preview';
        }

        final data = jsonDecode(r.body);
        List<Map<String, dynamic>> items;
        int total;

        if (data is Map<String, dynamic>) {
          final listRaw = (data['items'] ?? data['rows'] ?? data['data']) as List?;
          items = (listRaw ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
          total = (data['total'] is num)
              ? (data['total'] as num).toInt()
              : (r.headers['x-total-count'] != null
                  ? int.tryParse(r.headers['x-total-count']!) ?? items.length
                  : items.length);
        } else if (data is List) {
          items = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          total = items.length;
        } else {
          items = const [];
          total = 0;
        }

        // precalienta permisos de los roles visibles
        for (final it in items) {
          final id = (it['id'] ?? it['id_rol']);
          if (id is int && !_permCountCache.containsKey(id) && it['permisos'] == null && it['permisos_count'] == null) {
            _warmPermSummary(id);
          }
        }

        return AdminPage(items: items, total: total);
      },
    );
  }

  // ========================= Layout =========================

  Widget _content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const EntityHeader(
          title: 'Roles y permisos',
          subtitle: 'Define quién puede ver/editar cada módulo',
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: PermissionGate(
            any: const ['roles.create'],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: FilledButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo rol'),
              ),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(overscroll: false),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: _table(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Padding(padding: const EdgeInsets.all(12), child: _content());
    }
    return AdminShell(
      current: AdminHub.personas,
      crumbs: const [Crumb('Admin'), Crumb('Personas'), Crumb('Roles')],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: PermissionGate(
          roles: const ['admin'],
          any: const ['roles.read'],
          child: _content(),
          fallback: const ForbiddenScreen(message: 'No tienes permiso para ver roles'),
        ),
      ),
    );
  }
}
