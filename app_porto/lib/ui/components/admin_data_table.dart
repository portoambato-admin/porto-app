// lib/ui/components/admin_data_table.dart
import 'dart:async';
import 'package:flutter/material.dart';

class AdminQuery {
  int page;            // 1-based
  int limit;           // 10 | 25 | 50
  String? q;           // búsqueda
  String? sortBy;      // (opcional)
  bool asc;

  AdminQuery({
    this.page = 1,
    this.limit = 10,
    this.q,
    this.sortBy,
    this.asc = true,
  });

  AdminQuery copyWith({
    int? page,
    int? limit,
    String? q,
    String? sortBy,
    bool? asc,
  }) {
    return AdminQuery(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      q: q ?? this.q,
      sortBy: sortBy ?? this.sortBy,
      asc: asc ?? this.asc,
    );
  }
}

class AdminPage<T> {
  final List<T> items; // slice de la página actual
  final int total;     // total global (todas las filas)
  const AdminPage({required this.items, required this.total});
}

/// Describe una columna
class AdminColumn<T> {
  final String label;
  final Alignment alignment;
  final bool isNumeric;
  final Widget Function(T item) cellBuilder;
  const AdminColumn({
    required this.label,
    required this.cellBuilder,
    this.alignment = Alignment.centerLeft,
    this.isNumeric = false,
  });
}

/// DataSource que entiende de slices y total
class _AdminDataSource<T> extends DataTableSource {
  final List<T> items;               // slice de la página
  final int total;                   // total global
  final int startIndex;              // índice global del primer elemento del slice
  final List<AdminColumn<T>> cols;
  final void Function(T item)? onRowTap;
  final Widget Function(T item)? trailingBuilder;

  _AdminDataSource({
    required this.items,
    required this.total,
    required this.startIndex,
    required this.cols,
    this.onRowTap,
    this.trailingBuilder,
  });

  @override
  DataRow? getRow(int index) {
    // index es global (0..total-1). Solo podemos renderizar si cae en el slice cargado.
    final end = startIndex + items.length; // no inclusivo
    if (index < startIndex || index >= end) return null;

    final local = index - startIndex;
    final item = items[local];

    final cells = <DataCell>[
      for (final c in cols)
        DataCell(Align(alignment: c.alignment, child: c.cellBuilder(item))),
      if (trailingBuilder != null)
        DataCell(Align(
          alignment: Alignment.centerRight,
          child: trailingBuilder!(item),
        )),
    ];

    return DataRow.byIndex(
      index: index,
      cells: cells,
      onSelectChanged: onRowTap == null ? null : (_) => onRowTap!(item),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => total; // ¡total global!

  @override
  int get selectedRowCount => 0;
}

/// Tabla administrable con búsqueda, rows-per-page nativo y acciones.
/// `fetch(AdminQuery)` debe devolver `AdminPage(items, total)`.
class AdminDataTable<T> extends StatefulWidget {
  final List<AdminColumn<T>> columns;
  final Future<AdminPage<T>> Function(AdminQuery q) fetch;
  final Widget Function(T item)? trailingBuilder;
  final void Function(T item)? onRowTap;

  final List<int> pageSizes;
  final int initialPageSize;
  final String searchHint;
  final List<Widget>? actions; // botones extra (Nuevo, Exportar, etc.)

  const AdminDataTable({
    super.key,
    required this.columns,
    required this.fetch,
    this.trailingBuilder,
    this.onRowTap,
    this.pageSizes = const [10, 25, 50],
    this.initialPageSize = 10,
    this.searchHint = 'Buscar...',
    this.actions,
  });

  @override
  State<AdminDataTable<T>> createState() => _AdminDataTableState<T>();
}

class _AdminDataTableState<T> extends State<AdminDataTable<T>> {
  final _searchCtl = TextEditingController();
  final _focusNode = FocusNode();
  AdminQuery _q = AdminQuery();
  List<T> _items = const [];
  int _total = 0;
  bool _loading = true;

  int _startIndex = 0; // índice global del primer elemento cargado (para DataSource)
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _q = _q.copyWith(limit: widget.initialPageSize, page: 1);
    _load();
    _searchCtl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _q = _q.copyWith(page: 1, q: _searchCtl.text.trim().isEmpty ? null : _searchCtl.text.trim());
        _startIndex = 0;
      });
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final page = await widget.fetch(_q);
      setState(() {
        _items = page.items;
        _total = page.total;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeRowsPerPage(int v) {
    setState(() {
      _q = _q.copyWith(limit: v, page: 1);
      _startIndex = 0;
    });
    _load();
  }

  void _changePage(int newStartIndex) {
    // newStartIndex lo provee PaginatedDataTable (índice global)
    final newPage = (newStartIndex ~/ _q.limit) + 1; // 1-based
    setState(() {
      _startIndex = newStartIndex;
      _q = _q.copyWith(page: newPage);
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final header = Row(
      children: [
        // Search
        Expanded(
          child: TextField(
            controller: _searchCtl,
            focusNode: _focusNode,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: widget.searchHint,
              isDense: true,
              border: const OutlineInputBorder(),
              suffixIcon: _searchCtl.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar',
                      onPressed: () {
                        _searchCtl.clear();
                        _onSearchChanged();
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(),
          ),
        ),
        const SizedBox(width: 12),
        // Refresh
        FilledButton.icon(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Actualizar'),
        ),
        const SizedBox(width: 8),
        // Actions extra
        if (widget.actions != null) ...widget.actions!,
      ],
    );

    final src = _AdminDataSource<T>(
      items: _items,
      total: _total,
      startIndex: _startIndex,
      cols: widget.columns,
      onRowTap: widget.onRowTap,
      trailingBuilder: widget.trailingBuilder,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            header,
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              PaginatedDataTable(
                columns: [
                  for (final c in widget.columns)
                    DataColumn(label: Text(c.label), numeric: c.isNumeric),
                  if (widget.trailingBuilder != null)
                    const DataColumn(label: SizedBox.shrink()),
                ],
                source: src,
                rowsPerPage: _q.limit,
                availableRowsPerPage: widget.pageSizes,
                onRowsPerPageChanged: (v) => v == null ? null : _changeRowsPerPage(v),
                onPageChanged: _changePage,
                showFirstLastButtons: true,
                showCheckboxColumn: false,
                headingRowHeight: 44,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 60,
              ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Mostrando ${_items.isEmpty ? 0 : (_startIndex + 1)}–${_startIndex + _items.length} de $_total',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
