import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:characters/characters.dart';

import '../../../../core/services/session.dart';
import '../../../../core/services/api_service.dart';

class ProfesoresTab extends StatefulWidget {
  const ProfesoresTab({super.key, required this.tab});
  final TabController tab;

  @override
  State<ProfesoresTab> createState() => _ProfesoresTabState();
}

// ==== Enums de vista ====
enum _ViewMode { table, cards }

class _ProfesoresTabState extends State<ProfesoresTab> {
  // Estado base
  final _searchCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  int _page = 1;
  int _pageSize = 10;
  String _sort = 'id_profesor'; // Compat con API (usa 'cedula' si tu API lo soporta)
  String _order = 'desc';
  int _total = 0;
  List<Map<String, dynamic>> _rows = [];

  // Preferencias visuales
  _ViewMode _viewMode = _ViewMode.cards; // 👉 por defecto: Tarjetas
  bool _dense = false;

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

  // ====== Carga de datos ======
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
      builder: (_) => _ProfesorDialog(data: data),
    );
    if (ok == true) _load();
  }

  // ========= Detalle (sin IDs ni fechas) =========
  Future<void> _openDetails(Map<String, dynamic> r) async {
    final cs = Theme.of(context).colorScheme;

    String _docFrom(Map<String, dynamic> r) {
      final v = r['cedula'] ?? r['dni'] ?? r['numero_cedula'] ?? '';
      final s = '$v'.trim();
      return s.isEmpty ? 'Sin identificar' : s;
    }

    final doc = _docFrom(r);
    final nombre = (r['nombre_usuario'] ?? r['nombre'] ?? '').toString();
    final correo = (r['correo'] ?? '').toString();
    final tel = (r['telefono'] ?? '').toString();
    final dir = (r['direccion'] ?? '').toString();
    final esp = (r['especialidad'] ?? '').toString();
    final avatar = (r['avatar_url'] ?? '').toString();
    final activo = r['activo'] == true;

    final header = ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 26,
        backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
        child: avatar.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text(
        nombre.isEmpty ? '(Sin nombre)' : nombre,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      subtitle: Row(
        children: [
          Flexible(
            child: Text(
              correo.isEmpty ? '(Sin correo)' : correo,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (correo.isNotEmpty) ...[
            const SizedBox(width: 4),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Copiar correo',
              iconSize: 18,
              onPressed: () => _copy(context, 'Correo', correo),
              icon: const Icon(Icons.copy_rounded),
            ),
          ],
        ],
      ),
      trailing: Chip(
        label: Text(activo ? 'Activo' : 'Inactivo'),
        avatar: Icon(
          activo ? Icons.check_circle : Icons.cancel,
          size: 18,
          color: activo ? cs.onPrimaryContainer : cs.onErrorContainer,
        ),
        backgroundColor: activo ? cs.primaryContainer : cs.errorContainer,
        side: BorderSide(color: cs.outlineVariant),
      ),
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 4),
        Divider(color: cs.outlineVariant),
        const SizedBox(height: 6),

        _kvIcon(context, 'Cédula', doc, Icons.badge_outlined,
            copyable: doc != 'Sin identificar', copyLabel: 'Cédula'),
        _kvIcon(context, 'Especialidad', esp.isEmpty ? '—' : esp, Icons.school_outlined),
        _kvIcon(context, 'Teléfono', tel.isEmpty ? '—' : tel, Icons.phone_outlined,
            copyable: tel.isNotEmpty, copyLabel: 'Teléfono'),
        _kvIcon(context, 'Dirección', dir.isEmpty ? '—' : dir, Icons.location_on_outlined,
            copyable: dir.isNotEmpty, copyLabel: 'Dirección'),

        const SizedBox(height: 4),

        if (doc == 'Sin identificar')
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Chip(
                avatar: const Icon(Icons.warning_amber_rounded, size: 18),
                label: const Text('Sin cédula registrada'),
                backgroundColor: cs.secondaryContainer,
                side: BorderSide(color: cs.outlineVariant),
              ),
            ),
          ),
      ],
    );

    final actions = [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
      FilledButton.icon(
        onPressed: () { Navigator.pop(context); _openEdit(r); },
        icon: const Icon(Icons.edit),
        label: const Text('Editar'),
      ),
    ];

    final isNarrow = MediaQuery.of(context).size.width < 640;

    if (isNarrow) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: cs.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16, right: 16,
              top: 12,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    child: Container(
                      width: 36, height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cs.outlineVariant, borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Text('Información del profesor',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  header,
                  content,
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Información del profesor'),
        content: SizedBox(width: 560, child: Column(mainAxisSize: MainAxisSize.min, children: [header, content])),
        actions: actions,
      ),
    );
  }

  // ========= UI principal =========
  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 820;

    final headerRow = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: LayoutBuilder(
        builder: (_, cc) {
          final compact = cc.maxWidth < 720;

          final chips = Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              // Vista
              InputChip(
                label: Text(_viewMode == _ViewMode.table ? 'Tabla' : 'Tarjetas'),
                avatar: Icon(_viewMode == _ViewMode.table ? Icons.table_chart : Icons.view_agenda, size: 18),
                onPressed: () => setState(() {
                  _viewMode = _viewMode == _ViewMode.table ? _ViewMode.cards : _ViewMode.table;
                }),
              ),
              // Densidad
              InputChip(
                label: Text(_dense ? 'Denso' : 'Cómodo'),
                avatar: Icon(_dense ? Icons.compress : Icons.unfold_more, size: 18),
                onPressed: () => setState(() => _dense = !_dense),
              ),
              // Filtro de búsqueda activo (informativo)
              if (_searchCtrl.text.trim().isNotEmpty)
                InputChip(
                  avatar: const Icon(Icons.search, size: 18),
                  label: Text('Búsqueda: "${_searchCtrl.text.trim()}"'),
                  onDeleted: () { _searchCtrl.clear(); _page = 1; _load(); },
                ),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _rows.isEmpty ? null : _exportCsv,
                icon: const Icon(Icons.download),
                label: const Text('Exportar CSV'),
              ),
              FilledButton.icon(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                chips,
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: chips),
              actions,
            ],
          );
        },
      ),
    );

    final coreContent = _loading && _rows.isEmpty
        ? _LoadingPlaceholder(isNarrow: isNarrow, viewMode: _viewMode, dense: _dense)
        : (_error != null
            ? _ErrorView(error: _error!, onRetry: _load)
            : (_rows.isEmpty
                ? const _EmptyState(
                    title: 'Sin profesores',
                    subtitle: 'Ajusta la búsqueda o crea un profesor.',
                    primary: ('Refrescar', null),
                  )
                : (_viewMode == _ViewMode.cards
                    ? _cards(context, _rows)
                    : _table(context, _rows))));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _toolbar(),   // búsqueda + tamaño de página
        headerRow,    // chips + acciones
        Expanded(
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: coreContent,
              ),
              if (_loading && _rows.isNotEmpty)
                const Positioned(right: 12, top: 8, child: _LoadingChip()),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: _Paginator(
            page: _page,
            pageSize: _pageSize,
            total: _total,
            onPage: (p) { setState(() => _page = p); _load(); },
          ),
        ),
      ],
    );
  }

  // ====== Toolbar (búsqueda + page size) ======
  Widget _toolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: LayoutBuilder(
        builder: (ctx, c) {
          final search = Expanded(
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar por nombre, cédula, teléfono o correo…',
              ),
              onSubmitted: (_) { _page = 1; _load(); },
            ),
          );

          final perPage = SizedBox(
            width: 160,
            child: DropdownButtonFormField<int>(
              value: _pageSize,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.format_list_numbered),
                labelText: 'Por página',
              ),
              items: const [
                DropdownMenuItem(value: 5, child: Text('5')),
                DropdownMenuItem(value: 10, child: Text('10')),
                DropdownMenuItem(value: 20, child: Text('20')),
                DropdownMenuItem(value: 50, child: Text('50')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() { _pageSize = v; _page = 1; });
                _load();
              },
            ),
          );

          final narrow = c.maxWidth < 900;
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
              search,
              const SizedBox(width: 8),
              perPage,
            ],
          );
        },
      ),
    );
  }

  // ====== Vista TABLA (sin columna "Especialidad") ======
  Widget _table(BuildContext context, List<Map<String, dynamic>> rows) {
    final textStyle = _dense
        ? Theme.of(context).textTheme.bodySmall
        : Theme.of(context).textTheme.bodyMedium;

    String doc(Map r) {
      final v = r['cedula'] ?? r['dni'] ?? r['numero_cedula'] ?? '';
      final s = '$v'.trim();
      return s.isEmpty ? 'Sin identificar' : s;
    }

    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: true),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: _dense ? 36 : 48,
          dataRowMinHeight: _dense ? 32 : 44,
          dataRowMaxHeight: _dense ? 40 : null,
          columns: [
            DataColumn(
              label: const Text('Cédula'),
              onSort: (_, asc) => _toggleSort('id_profesor'), // usa 'cedula' si tu API lo soporta
            ),
            DataColumn(
              label: const Text('Nombre'),
              onSort: (_, asc) => _toggleSort('nombre_usuario'),
            ),
            const DataColumn(label: Text('Teléfono')),
            DataColumn(
              label: const Text('Correo'),
              onSort: (_, asc) => _toggleSort('correo'),
            ),
            const DataColumn(label: Text('Activo')),
            const DataColumn(label: Text('Acciones')),
          ],
          rows: rows.map((r) {
            final bool activo = r['activo'] == true;
            return DataRow(
              onSelectChanged: (_) => _openDetails(r),
              cells: [
                DataCell(SelectableText(doc(r), style: textStyle)),
                DataCell(SelectableText((r['nombre_usuario'] ?? r['nombre'] ?? '').toString(), style: textStyle)),
                DataCell(SelectableText('${r['telefono'] ?? '—'}', style: textStyle)),
                DataCell(SelectableText('${r['correo'] ?? ''}', style: textStyle)),
                DataCell(Icon(
                  activo ? Icons.check_circle : Icons.cancel,
                  color: activo ? Colors.green : Colors.grey,
                  size: _dense ? 18 : 20,
                  semanticLabel: activo ? 'Activo' : 'Inactivo',
                )),
                DataCell(_rowActions(r: r, activo: activo, dense: _dense)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ====== Vista TARJETAS ======
  Widget _cards(BuildContext context, List<Map<String, dynamic>> rows) {
    final compactPad = EdgeInsets.symmetric(horizontal: 12, vertical: _dense ? 4 : 6);

    String doc(Map r) {
      final v = r['cedula'] ?? r['dni'] ?? r['numero_cedula'] ?? '';
      final s = '$v'.trim();
      return s.isEmpty ? 'Sin identificar' : s;
    }

    String initials(String? nombre) {
      final n = (nombre ?? '').trim().split(' ').where((e) => e.isNotEmpty).toList();
      if (n.isEmpty) return '👤';
      final i1 = n.first.characters.first;
      final i2 = n.length > 1 ? n[1].characters.first : '';
      final r = (i1 + i2).toUpperCase();
      return r.isEmpty ? '👤' : r;
    }

    Color avatarColor(String seed) {
      final h = seed.hashCode & 0xFFFFFF;
      return Color(0xFF000000 | h).withOpacity(1);
    }

    Widget miniChip(BuildContext ctx, String text, IconData icon) {
      final theme = Theme.of(ctx);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 4),
            Text(text, style: theme.textTheme.labelSmall),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final r = rows[i];
        final activo = r['activo'] == true;
        final nombre = (r['nombre_usuario'] ?? r['nombre'] ?? '').toString();
        final telefono = r['telefono']?.toString() ?? '—';
        final correo = r['correo']?.toString() ?? '';
        final cedula = doc(r);
        final initialsText = initials(nombre);
        final color = avatarColor('$nombre$cedula');

        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: ListTile(
            dense: true,
            contentPadding: compactPad,
            onTap: () => _openDetails(r),
            leading: CircleAvatar(
              radius: _dense ? 14 : 16,
              backgroundColor: color.withOpacity(0.15),
              child: Text(
                initialsText,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    nombre.isEmpty ? 'Sin nombre' : nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  activo ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: activo ? Colors.green : Colors.grey,
                  semanticLabel: activo ? 'Activo' : 'Inactivo',
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  miniChip(context, 'Cédula: $cedula', Icons.badge_outlined),
                  if (telefono.trim().isNotEmpty && telefono != '—')
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.call, size: 14),
                        const SizedBox(width: 3),
                        Text(telefono, style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  if (correo.trim().isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mail, size: 14),
                        const SizedBox(width: 3),
                        Text(correo, style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                ],
              ),
            ),
            trailing: _rowActions(r: r, activo: activo, dense: true),
          ),
        );
      },
    );
  }

  // ===== Acciones por fila =====
  Widget _rowActions({required Map<String, dynamic> r, required bool activo, bool dense = false}) {
    final double iconSize = dense ? 18 : 24;
    final EdgeInsets padding = EdgeInsets.all(dense ? 4 : 8);
    final BoxConstraints? k = dense ? const BoxConstraints(minWidth: 36, minHeight: 36) : null;
    final VisualDensity vd = dense ? VisualDensity.compact : VisualDensity.standard;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Ver',
          child: IconButton(
            iconSize: iconSize,
            padding: padding,
            constraints: k,
            visualDensity: vd,
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () => _openDetails(r),
          ),
        ),
        Tooltip(
          message: 'Editar',
          child: IconButton(
            iconSize: iconSize,
            padding: padding,
            constraints: k,
            visualDensity: vd,
            icon: const Icon(Icons.edit),
            onPressed: () => _openEdit(r),
          ),
        ),
        Tooltip(
          message: activo ? 'Desactivar' : 'Activar',
          child: IconButton(
            iconSize: iconSize,
            padding: padding,
            constraints: k,
            visualDensity: vd,
            icon: Icon(activo ? Icons.visibility_off : Icons.visibility),
            onPressed: () => _toggleActivo(r),
          ),
        ),
      ],
    );
  }

  // ========= Helpers UI =========
  Widget _kvIcon(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool copyable = false,
    String? copyLabel,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isMuted = value.trim().isEmpty || value == '—' || value == 'Sin identificar';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          SizedBox(
            width: 128,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                color: isMuted ? cs.onSurfaceVariant : cs.onSurface,
              ),
            ),
          ),
          if (copyable && value.trim().isNotEmpty)
            IconButton(
              tooltip: 'Copiar ${copyLabel ?? label.toLowerCase()}',
              icon: const Icon(Icons.copy_rounded, size: 18),
              onPressed: () => _copy(context, copyLabel ?? label, value),
            ),
        ],
      ),
    );
  }

  void _copy(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copiado')),
    );
  }

  // ===== Export CSV simple (copiar desde diálogo) =====
  void _exportCsv() {
    final csv = StringBuffer()..writeln('Cedula,Nombre,Telefono,Correo,Activo');
    for (final r in _rows) {
      final ced = (r['cedula'] ?? r['dni'] ?? r['numero_cedula'] ?? '').toString();
      final nom = (r['nombre_usuario'] ?? r['nombre'] ?? '').toString();
      final tel = (r['telefono'] ?? '').toString();
      final cor = (r['correo'] ?? '').toString();
      final act = (r['activo'] == true) ? '1' : '0';
      csv.writeln('${_csv(ced)},${_csv(nom)},${_csv(tel)},${_csv(cor)},$act');
    }
    _showCsvDialog(csv.toString(), 'profesores_page$_page.csv');
  }

  static String _csv(Object? v) {
    final s = v?.toString() ?? '';
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  Future<void> _showCsvDialog(String data, String filename) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('CSV: $filename'),
        content: SizedBox(width: 600, height: 360, child: SelectableText(data)),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: data));
              if (mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copiado al portapapeles')));
            },
            child: const Text('Copiar'),
          ),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
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

    return SafeArea(
      top: false,
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

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final (String, VoidCallback?) primary;
  final (String, VoidCallback)? secondary;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.primary, 
    // ignore: unused_element_parameter
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Theme.of(context).hintColor),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(onPressed: primary.$2, child: Text(primary.$1)),
                if (secondary != null)
                  OutlinedButton(onPressed: secondary!.$2, child: Text(secondary!.$1)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 56),
            const SizedBox(height: 12),
            Text('Error al cargar datos', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _LoadingChip extends StatelessWidget {
  const _LoadingChip();

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      label: const Text('Cargando…'),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  final bool isNarrow;
  final _ViewMode viewMode;
  final bool dense;

  const _LoadingPlaceholder({required this.isNarrow, required this.viewMode, required this.dense});

  @override
  Widget build(BuildContext context) {
    if (viewMode == _ViewMode.cards || isNarrow) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _Skeleton(height: dense ? 84 : 104),
        ),
      );
    }
    return Column(
      children: [
        _Skeleton(height: dense ? 44 : 52),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: 8,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _Skeleton(height: dense ? 36 : 44),
            ),
          ),
        ),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double height;
  const _Skeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
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
