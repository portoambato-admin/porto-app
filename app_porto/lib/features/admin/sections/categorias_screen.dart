import 'dart:async'; // Debouncer búsqueda
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_scope.dart';

class AdminCategoriasScreen extends StatefulWidget {
  const AdminCategoriasScreen({super.key});

  @override
  State<AdminCategoriasScreen> createState() => _AdminCategoriasScreenState();
}

// ==== Intents propios para atajos (Ctrl+F / Ctrl+N / Ctrl+R) ====
class _FocusSearchIntent extends Intent { const _FocusSearchIntent(); } // Ctrl+F
class _NewIntent extends Intent { const _NewIntent(); }                 // Ctrl+N
class _ReloadIntent extends Intent { const _ReloadIntent(); }           // Ctrl+R

enum _ViewMode { table, cards }

class _AdminCategoriasScreenState extends State<AdminCategoriasScreen>
    with SingleTickerProviderStateMixin {
  // Repo
  dynamic _repo;
  bool _repoReady = false;

  // Estado general
  late final TabController _tab = TabController(length: 3, vsync: this)
    ..addListener(() {
      if (_tab.indexIsChanging) return;
      if (_itemsForTab(_tab.index).isEmpty) _loadCurrent();
    });

  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;

  bool _loading = false;
  String? _error;

  // Preferencias visuales (solo UI)
  _ViewMode _viewMode = _ViewMode.table;
  bool _dense = false;

  // Paginación por pestaña
  int _actPage = 1, _actPageSize = 10, _actTotal = 0;
  int _inaPage = 1, _inaPageSize = 10, _inaTotal = 0;
  int _allPage = 1, _allPageSize = 10, _allTotal = 0;

  List<Map<String, dynamic>> _actItems = [];
  List<Map<String, dynamic>> _inaItems = [];
  List<Map<String, dynamic>> _allItems = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repoReady) return;
    _repo = AppScope.of(context).categorias;
    _repoReady = true;
    _init();
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ===== Debouncer de búsqueda =====
  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _resetPages();
      _loadCurrent();
    });
  }

  void _resetPages() {
    _actPage = 1; _inaPage = 1; _allPage = 1;
  }

  String? get _q {
    final s = _searchCtrl.text.trim();
    return s.isEmpty ? null : s;
  }

  Future<void> _init() async {
    setState(() => _error = null);
    try {
      await _loadData(_tab.index);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _loadCurrent() async {
    if (_loading) return;
    await _loadData(_tab.index);
  }

  Future<void> _loadData(int tabIndex) async {
    setState(() { _loading = true; _error = null; });

    bool? onlyActive;
    int page, pageSize;
    switch (tabIndex) {
      case 1: onlyActive = false; page = _inaPage; pageSize = _inaPageSize; break;
      case 2: onlyActive = null;  page = _allPage; pageSize = _allPageSize; break;
      case 0:
      default: onlyActive = true; page = _actPage; pageSize = _actPageSize; break;
    }

    try {
      // Mantengo sort simple para copiar el “formato” de Subcategorías
      final res = await _repo.paged(
        page: page,
        pageSize: pageSize,
        q: _q,
        sort: 'nombre_categoria', // si tu API usa 'nombre', no pasa nada si ignora clave
        order: 'asc',
        onlyActive: onlyActive,
      );

      final items = List<Map<String, dynamic>>.from(res['items'] as List);
      final total = (res['total'] as num).toInt();

      setState(() {
        switch (tabIndex) {
          case 1: _inaItems = items; _inaTotal = total; break;
          case 2: _allItems = items; _allTotal = total; break;
          case 0:
          default: _actItems = items; _actTotal = total; break;
        }
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ===== CRUD =====
  Future<void> _onNew() async {
    final ok = await _openForm();
    if (ok == true) _loadCurrent();
  }

  Future<void> _onEditDialog(Map<String, dynamic> row) async {
    final ok = await _openForm(row: row);
    if (ok == true) _loadCurrent();
  }

  Future<void> _toggleEstado(Map<String, dynamic> r) async {
    final activo = r['activo'] == true;
    try {
      if (activo) {
        await _repo.deactivate((r['id'] as num).toInt());
        _showSnack('Categoría desactivada');
      } else {
        await _repo.activate((r['id'] as num).toInt());
        _showSnack('Categoría activada');
      }
      await _loadCurrent();
    } catch (e) {
      _showSnack('Error: $e');
    }
  }

  Future<bool?> _openForm({Map<String, dynamic>? row}) async {
    final formKey = GlobalKey<FormState>();
    final nombre = TextEditingController(text: row?['nombre']?.toString() ?? '');
    final edadMin = TextEditingController(text: row?['edadMin']?.toString() ?? '');
    final edadMax = TextEditingController(text: row?['edadMax']?.toString() ?? '');
    bool activa = row?['activo'] == true || row == null;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(row == null ? 'Nueva categoría' : 'Editar categoría'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nombre,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de categoría',
                      prefixIcon: Icon(Icons.label),
                    ),
                    maxLength: 60,
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return 'Requerido';
                      if (s.length < 3) return 'Muy corto';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: edadMin,
                          decoration: const InputDecoration(
                            labelText: 'Edad mínima (opcional)',
                            prefixIcon: Icon(Icons.cake_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: edadMax,
                          decoration: const InputDecoration(
                            labelText: 'Edad máxima (opcional)',
                            prefixIcon: Icon(Icons.cake),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: activa,
                    onChanged: (v) => activa = v,
                    title: const Text('Activa'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
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
                  } else {
                    await _repo.update(
                      idCategoria: (row['id'] as num).toInt(),
                      nombre: nombre.text.trim(),
                      edadMin: int.tryParse(edadMin.text.trim()),
                      edadMax: int.tryParse(edadMax.text.trim()),
                      activa: activa,
                    );
                  }
                  if (mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  _showSnack('Error: $e');
                }
              },
              child: Text(row == null ? 'Crear' : 'Guardar'),
            ),
          ],
        );
      },
    );
  }

  // ===== Exportar CSV =====
  void _exportCsvCurrent() {
    final tab = _tab.index;
    final data = tab == 0 ? _actItems : (tab == 1 ? _inaItems : _allItems);
    final name = tab == 0
        ? 'categorias_activas'
        : (tab == 1 ? 'categorias_inactivas' : 'categorias_todas');

    final csv = StringBuffer()..writeln('ID,Categoria,EdadMin,EdadMax,Activo,Creado');
    for (final r in data) {
      final id = r['id'] ?? '';
      final nom = _csvEscape(r['nombre']);
      final eMin = r['edadMin']?.toString() ?? '';
      final eMax = r['edadMax']?.toString() ?? '';
      final act = (r['activo'] == true) ? '1' : '0';
      final cre = r['creadoEn']?.toString().split('T').first ?? '';
      csv.writeln('$id,$nom,$eMin,$eMax,$act,$cre');
    }
    final content = csv.toString();

    if (kIsWeb) {
      final bytes = <int>[0xEF, 0xBB, 0xBF]..addAll(utf8.encode(content)); // BOM para Excel
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final a = html.AnchorElement(href: url)..download = '$name.csv';
      a.click();
      html.Url.revokeObjectUrl(url);
    } else {
      _showCsvDialog(content, '$name.csv');
    }
  }

  static String _csvEscape(Object? v) {
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
              _showSnack('Copiado al portapapeles');
            },
            child: const Text('Copiar'),
          ),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  // ===== Paginación =====
  void _onPageChange(int tabIndex, int newPage) {
    if (newPage < 1) return;
    int totalItems, pageSize;
    switch (tabIndex) {
      case 1: totalItems = _inaTotal; pageSize = _inaPageSize; break;
      case 2: totalItems = _allTotal; pageSize = _allPageSize; break;
      case 0:
      default: totalItems = _actTotal; pageSize = _actPageSize; break;
    }
    int lastPage = (totalItems + pageSize - 1) ~/ pageSize;
    if (lastPage == 0) lastPage = 1;
    if (newPage > lastPage) return;

    setState(() {
      switch (tabIndex) {
        case 0: _actPage = newPage; break;
        case 1: _inaPage = newPage; break;
        case 2: _allPage = newPage; break;
      }
    });
    _loadCurrent();
  }

  void _onPageSizeChange(int tabIndex, int newSize) {
    if (newSize <= 0) return;
    setState(() {
      switch (tabIndex) {
        case 0: _actPageSize = newSize; _actPage = 1; break;
        case 1: _inaPageSize = newSize; _inaPage = 1; break;
        case 2: _allPageSize = newSize; _allPage = 1; break;
      }
    });
    _loadCurrent();
  }

  // ===== Helpers UI =====
  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ====================================================================
  // ============================ BUILD =================================
  // ====================================================================
  @override
Widget build(BuildContext context) {
  final isFirstLoad = _loading &&
      _actItems.isEmpty &&
      _inaItems.isEmpty &&
      _allItems.isEmpty;

  final core = LayoutBuilder(
    builder: (ctx, c) {
      final isNarrow = c.maxWidth < 820;
      const double maxContentWidth = 1200;
      final double width = c.maxWidth > maxContentWidth ? maxContentWidth : c.maxWidth;

      final header = _buildHeader(context, isNarrow);

      final tabs = TabBar(
        controller: _tab,
        isScrollable: isNarrow,
        tabs: [
          Tab(text: 'Activas (${_actTotal})'),
          Tab(text: 'Inactivas (${_inaTotal})'),
          Tab(text: 'Todas (${_allTotal})'),
        ],
      );

      final content = isFirstLoad
          ? _LoadingPlaceholder(isNarrow: isNarrow, viewMode: _viewMode, dense: _dense)
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _loadCurrent)
              : TabBarView(
                  controller: _tab,
                  children: [
                    _buildTabContent(context, isNarrow, 0),
                    _buildTabContent(context, isNarrow, 1),
                    _buildTabContent(context, isNarrow, 2),
                  ],
                );

      final body = Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 12),
              tabs,
              const SizedBox(height: 8),
              Expanded(
                child: Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: content,
                    ),
                    if (_loading && !isFirstLoad)
                      const Positioned(
                        right: 12,
                        top: 8,
                        child: _LoadingChip(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      return _withShortcuts(body);
    },
  );

  return Scaffold(
    appBar: AppBar(title: const Text('Categorías')),
    body: Padding(padding: const EdgeInsets.all(12), child: core),
  );
}


  // ===== Header alineado al formato =====
  Widget _buildHeader(BuildContext context, bool isNarrow) {
  final activeFilters = Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      if (_q != null)
        InputChip(
          label: Text('Búsqueda: "${_q!}"'),
          onDeleted: () { _searchCtrl.clear(); _loadCurrent(); },
          avatar: const Icon(Icons.search, size: 18),
        ),
      InputChip(
        label: Text(_viewMode == _ViewMode.table ? 'Tabla' : 'Tarjetas'),
        avatar: Icon(_viewMode == _ViewMode.table ? Icons.table_chart : Icons.view_agenda, size: 18),
        onPressed: () => setState(() {
          _viewMode = _viewMode == _ViewMode.table ? _ViewMode.cards : _ViewMode.table;
        }),
      ),
      InputChip(
        label: Text(_dense ? 'Denso' : 'Cómodo'),
        avatar: Icon(_dense ? Icons.compress : Icons.unfold_more, size: 18),
        onPressed: () => setState(() => _dense = !_dense),
      ),
    ],
  );

  final searchField = TextField(
    controller: _searchCtrl,
    focusNode: _searchFocus,
    decoration: InputDecoration(
      hintText: 'Buscar por nombre…',
      prefixIcon: const Icon(Icons.search),
      suffixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'Limpiar',
            child: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () { _searchCtrl.clear(); _loadCurrent(); },
            ),
          ),
          Tooltip(
            message: 'Recargar (Ctrl+R)',
            child: IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCurrent),
          ),
        ],
      ),
    ),
    onSubmitted: (_) => _loadCurrent(),
    textInputAction: TextInputAction.search,
  );

  final viewSelector = SegmentedButton<_ViewMode>(
    segments: const [
      ButtonSegment<_ViewMode>(value: _ViewMode.table, icon: Icon(Icons.table_chart), label: Text('Tabla')),
      ButtonSegment<_ViewMode>(value: _ViewMode.cards,  icon: Icon(Icons.view_agenda), label: Text('Tarjetas')),
    ],
    selected: {_viewMode},
    onSelectionChanged: (s) => setState(() => _viewMode = s.first),
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
      _loadCurrent();
    },
  );

  final exportBtn = OutlinedButton.icon(
    onPressed: _exportCsvCurrent,
    icon: const Icon(Icons.download),
    label: const Text('Exportar'),
  );

  // ✅ Botón azul “Nueva”
  final add = FilledButton.icon(
    onPressed: _onNew,
    icon: const Icon(Icons.add),
    label: const Text('Nueva'),
  );

  if (isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        searchField,
        const SizedBox(height: 8),
        viewSelector,
        const SizedBox(height: 8),
        perPage,
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          exportBtn,
          const SizedBox(width: 8),
          add,
        ]),
        const SizedBox(height: 8),
        activeFilters,
      ],
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(child: searchField),
          const SizedBox(width: 8),
          SizedBox(width: 240, child: viewSelector),
          const SizedBox(width: 8),
          SizedBox(width: 180, child: perPage),
          const Spacer(),
          exportBtn,
          const SizedBox(width: 8),
          add, // ← aquí queda visible en desktop
        ],
      ),
      const SizedBox(height: 8),
      activeFilters,
    ],
  );
}



  List<Map<String, dynamic>> _itemsForTab(int index) {
    switch (index) {
      case 1: return _inaItems;
      case 2: return _allItems;
      case 0:
      default: return _actItems;
    }
  }

  Widget _buildTabContent(BuildContext context, bool isNarrow, int tabIndex) {
    final items = _itemsForTab(tabIndex);

    int currentPage, totalItems, pageSize;
    switch (tabIndex) {
      case 1: currentPage = _inaPage; totalItems = _inaTotal; pageSize = _inaPageSize; break;
      case 2: currentPage = _allPage; totalItems = _allTotal; pageSize = _allPageSize; break;
      case 0:
      default: currentPage = _actPage; totalItems = _actTotal; pageSize = _actPageSize; break;
    }

    final paginator = _PaginationControls(
      currentPage: currentPage,
      totalItems: totalItems,
      pageSize: pageSize,
      onPageChange: (newPage) => _onPageChange(tabIndex, newPage),
      onPageSizeChange: (newSize) => _onPageSizeChange(tabIndex, newSize),
    );

    if (items.isEmpty && !_loading) {
      return Column(
        children: [
          Expanded(
            child: _EmptyState(
              title: 'Sin categorías',
              subtitle: 'Crea tu primera categoría o ajusta la búsqueda.',
              primary: ('Crear nueva', _onNew),
              secondary: ('Quitar filtros', () {
                setState(() { _searchCtrl.clear(); });
                _resetPages();
                _loadCurrent();
              }),
            ),
          ),
          const SizedBox(height: 8),
          paginator,
        ],
      );
    }

    final content = _viewMode == _ViewMode.cards
        ? _cards(context, items)
        : _table(context, items);

    return Column(
      children: [
        Expanded(child: content),
        if (totalItems > pageSize) paginator,
      ],
    );
  }

  // ===== Tabla (desktop) =====
  Widget _table(BuildContext context, List<Map<String, dynamic>> rows) {
    final textStyle = _dense
        ? Theme.of(context).textTheme.bodySmall
        : Theme.of(context).textTheme.bodyMedium;

    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: true),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: _dense ? 36 : 48,
          dataRowMinHeight: _dense ? 32 : 44,
          dataRowMaxHeight: _dense ? 40 : null,
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Categoría')),
            DataColumn(label: Text('Edad')),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Creado')),
            DataColumn(label: Text('Acciones')),
          ],
          rows: rows.map((r) {
            final bool activo = r['activo'] == true;
            final String edades = [
              r['edadMin']?.toString(),
              r['edadMax']?.toString(),
            ].where((e) => (e != null && e.isNotEmpty)).join(' - ');
            final estadoIcon = Icon(
              activo ? Icons.check_circle : Icons.cancel,
              color: activo ? Colors.green : Colors.grey,
              size: _dense ? 18 : 20,
              semanticLabel: activo ? 'Activa' : 'Inactiva',
            );
            return DataRow(cells: [
              DataCell(SelectableText(r['id']?.toString() ?? '', style: textStyle)),
              DataCell(SelectableText(r['nombre']?.toString() ?? '', style: textStyle)),
              DataCell(SelectableText(edades.isEmpty ? '—' : edades, style: textStyle)),
              DataCell(estadoIcon),
              DataCell(SelectableText(r['creadoEn']?.toString().split('T').first ?? '', style: textStyle)),
              DataCell(_rowActions(r: r, activo: activo, dense: _dense)),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // ===== Tarjetas (móvil) =====
  Widget _cards(BuildContext context, List<Map<String, dynamic>> rows) {
    final spacing = _dense ? 6.0 : 8.0;
    final padding = EdgeInsets.all(_dense ? 10 : 12);

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: rows.length,
      separatorBuilder: (_, __) => SizedBox(height: spacing),
      itemBuilder: (ctx, i) {
        final r = rows[i];
        final bool activo = r['activo'] == true;
        final String edades = [
          r['edadMin']?.toString(),
          r['edadMax']?.toString(),
        ].where((e) => (e != null && e.isNotEmpty)).join(' - ');

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r['nombre']?.toString() ?? '',
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      activo ? Icons.check_circle : Icons.cancel,
                      size: 18,
                      color: activo ? Colors.green : Colors.grey,
                      semanticLabel: activo ? 'Activa' : 'Inactiva',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(edades.isEmpty ? 'Sin rango de edad' : 'Edad: $edades'),
                const SizedBox(height: 8),
                _rowActions(r: r, activo: activo, dense: true),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== Botonera por fila =====
  Widget _rowActions({required Map<String, dynamic> r, required bool activo, bool dense = false}) {
    final double iconSize = dense ? 20 : 24;
    final EdgeInsets padding = EdgeInsets.all(dense ? 6 : 8);

    return OverflowBar(
      spacing: dense ? 4 : 8,
      overflowSpacing: dense ? 4 : 8,
      children: [
        Tooltip(
          message: 'Editar',
          child: IconButton(
            iconSize: iconSize,
            padding: padding,
            icon: const Icon(Icons.edit),
            onPressed: () => _onEditDialog(r),
          ),
        ),
        Tooltip(
          message: activo ? 'Desactivar' : 'Activar',
          child: IconButton(
            iconSize: iconSize,
            padding: padding,
            icon: Icon(activo ? Icons.visibility_off : Icons.visibility),
            onPressed: () => _toggleEstado(r),
          ),
        ),
      ],
    );
  }

  // ===== Atajos de teclado (Ctrl+F / Ctrl+N / Ctrl+R) =====
  Widget _withShortcuts(Widget child) {
    return FocusTraversalGroup(
      child: Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const _FocusSearchIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): const _NewIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR): const _ReloadIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(
              onInvoke: (_) { _searchFocus.requestFocus(); return null; },
            ),
            _NewIntent: CallbackAction<_NewIntent>(
              onInvoke: (_) { _onNew(); return null; },
            ),
            _ReloadIntent: CallbackAction<_ReloadIntent>(
              onInvoke: (_) { _loadCurrent(); return null; },
            ),
          },
          child: Focus(autofocus: true, child: child),
        ),
      ),
    );
  }
}

// ======================= Widgets de apoyo UI =======================

class _PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalItems;
  final int pageSize;
  final void Function(int) onPageChange;
  final void Function(int) onPageSizeChange;

  const _PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChange,
    required this.onPageSizeChange,
  });

  @override
  Widget build(BuildContext context) {
    int totalPages = (totalItems + pageSize - 1) ~/ pageSize;
    if (totalPages < 1) totalPages = 1;
    final bool canGoBack = currentPage > 1;
    final bool canGoFwd = currentPage < totalPages;
    final int from = totalItems == 0 ? 0 : ((currentPage - 1) * pageSize) + 1;
    final int rawTo = currentPage * pageSize;
    final int to = rawTo > totalItems ? totalItems : rawTo;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Text('Mostrando $from–$to de $totalItems'),
            const Spacer(),
            DropdownButton<int>(
              value: pageSize,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 10, child: Text('10 / pág.')),
                DropdownMenuItem(value: 20, child: Text('20 / pág.')),
                DropdownMenuItem(value: 50, child: Text('50 / pág.')),
              ],
              onChanged: (v) { if (v != null) onPageSizeChange(v); },
            ),
            IconButton(
              icon: const Icon(Icons.first_page),
              tooltip: 'Primera página',
              onPressed: canGoBack ? () => onPageChange(1) : null,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Página anterior',
              onPressed: canGoBack ? () => onPageChange(currentPage - 1) : null,
            ),
            Text('$currentPage / $totalPages'),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Página siguiente',
              onPressed: canGoFwd ? () => onPageChange(currentPage + 1) : null,
            ),
            IconButton(
              icon: const Icon(Icons.last_page),
              tooltip: 'Última página',
              onPressed: canGoFwd ? () => onPageChange(totalPages) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final (String, VoidCallback) primary;
  final (String, VoidCallback)? secondary;

  const _EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.primary,
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

  const _ErrorView({super.key, required this.error, required this.onRetry});

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
  const _LoadingChip({super.key});

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

  const _LoadingPlaceholder({super.key, required this.isNarrow, required this.viewMode, required this.dense});

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
  const _Skeleton({super.key, required this.height});

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


