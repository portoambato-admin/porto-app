import 'dart:async'; // Necesario para el Timer (Debounce)
import 'package:app_porto/core/services/session_token_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:characters/characters.dart';
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
  Timer? _debounce; // Timer para la búsqueda en tiempo real

  bool _loading = false;
  String? _error;

  int _page = 1;
  int _pageSize = 10;
  String _sort = 'id_profesor';
  String _order = 'desc';
  int _total = 0;
  List<Map<String, dynamic>> _rows = [];

  // Preferencias visuales
  _ViewMode _viewMode = _ViewMode.cards;
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
    _debounce?.cancel(); // Cancelar timer si se cierra
    super.dispose();
  }

  // ====== Lógica de Debounce (Búsqueda suave) ======
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _page = 1);
      _load();
    });
  }

  // ====== Carga de datos ======
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await SessionTokenProvider.instance.readToken();
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
    // 1. Guardar estado anterior por si hay error
    final bool wasActive = r['activo'] == true;
    final int targetIndex = _rows.indexOf(r);

    // 2. ACTUALIZACIÓN OPTIMISTA (Visual inmediata)
    setState(() {
      r['activo'] = !wasActive; // Cambiamos el valor localmente al instante
    });

    try {
      final token = await SessionTokenProvider.instance.readToken();
      if (token == null) throw Exception('Sesión expirada');
      final id = (r['id_profesor'] as num).toInt();

      // 3. Llamada silenciosa a la API
      if (wasActive) {
        await ApiService.deleteProfesor(token: token, idProfesor: id); // Desactivar
      } else {
        await ApiService.activarProfesor(token: token, idProfesor: id); // Activar
      }
      
      // Feedback sutil (opcional, a veces no es necesario si es obvio)
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(wasActive ? 'Profesor desactivado' : 'Profesor activado'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        width: 200, // Snack pequeño flotante
      ));

    } catch (e) {
      // 4. ROLLBACK (Si falla, volvemos al estado anterior)
      if (!mounted) return;
      setState(() {
        if (targetIndex != -1 && targetIndex < _rows.length) {
           _rows[targetIndex]['activo'] = wasActive;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al cambiar estado: $e'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  Future<void> _openEdit(Map<String, dynamic> data) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ProfesorDialog(data: data),
    );
    if (ok == true) _load();
  }

  // ========= Detalle con Animación HERO =========
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
    final initialsText = _getInitials(nombre);
    final avatarColor = _getAvatarColor('$nombre$doc');

    final header = ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Hero(
        tag: 'prof_avatar_${r['id_profesor']}', // Tag para animación
        child: CircleAvatar(
          radius: 30,
          backgroundColor: avatarColor.withOpacity(0.2),
          backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
          child: avatar.isEmpty 
            ? Text(initialsText, style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold, fontSize: 20))
            : null,
        ),
      ),
      title: Text(
        nombre.isEmpty ? '(Sin nombre)' : nombre,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (correo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: InkWell(
                onTap: () => _copy(context, 'Correo', correo),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mail_outline, size: 14, color: cs.primary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        correo,
                        style: TextStyle(color: cs.primary, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: activo ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activo ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3))
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8, color: activo ? Colors.green : Colors.red),
            const SizedBox(width: 6),
            Text(activo ? "ACTIVO" : "INACTIVO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: activo ? Colors.green.shade700 : Colors.red.shade700)),
          ],
        ),
      ),
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Divider(color: cs.outlineVariant.withOpacity(0.5)),
        const SizedBox(height: 12),

        _kvIcon(context, 'Cédula', doc, Icons.badge_outlined,
            copyable: doc != 'Sin identificar', copyLabel: 'Cédula'),
        _kvIcon(context, 'Especialidad', esp.isEmpty ? '—' : esp, Icons.school_outlined),
        _kvIcon(context, 'Teléfono', tel.isEmpty ? '—' : tel, Icons.phone_outlined,
            copyable: tel.isNotEmpty, copyLabel: 'Teléfono'),
        _kvIcon(context, 'Dirección', dir.isEmpty ? '—' : dir, Icons.location_on_outlined,
            copyable: dir.isNotEmpty, copyLabel: 'Dirección'),

        const SizedBox(height: 12),

        if (doc == 'Sin identificar')
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange[800]),
                const SizedBox(width: 12),
                Expanded(child: Text('Este profesor no tiene cédula registrada.', style: TextStyle(color: Colors.orange[900]))),
              ],
            ),
          ),
      ],
    );

    final actions = [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
      FilledButton.icon(
        onPressed: () { Navigator.pop(context); _openEdit(r); },
        icon: const Icon(Icons.edit, size: 18),
        label: const Text('Editar'),
      ),
    ];

    // Responsive Dialog
    final width = MediaQuery.of(context).size.width;
    if (width < 640) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: cs.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  header,
                  content,
                  const SizedBox(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Información del profesor'),
          content: SizedBox(width: 500, child: Column(mainAxisSize: MainAxisSize.min, children: [header, content])),
          actions: actions,
        ),
      );
    }
  }

  // ========= UI PRINCIPAL =========
  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 820;

    final coreContent = _loading && _rows.isEmpty
        ? _LoadingPlaceholder(isNarrow: isNarrow, viewMode: _viewMode, dense: _dense)
        : (_error != null
            ? _ErrorView(error: _error!, onRetry: _load)
            : (_rows.isEmpty
                ? const _EmptyState(
                    title: 'Sin profesores',
                    subtitle: 'Ajusta la búsqueda o crea un nuevo profesor.',
                    primary: ('Refrescar', null),
                  )
                : RefreshIndicator( // Pull to refresh nativo
                    onRefresh: _load,
                    child: _viewMode == _ViewMode.cards
                        ? _cards(context, _rows)
                        : _table(context, _rows),
                  )));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Cabecera Moderna Unificada
        _buildModernHeader(context),
        
        // 2. Contenido con Loading superpuesto discreto
        Expanded(
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: coreContent,
              ),
              if (_loading && _rows.isNotEmpty)
                Positioned(
                  top: 16, 
                  left: 0, 
                  right: 0, 
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.inverseSurface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0,2))]
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onInverseSurface)),
                          const SizedBox(width: 10),
                          Text('Actualizando...', style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface, fontSize: 12)),
                        ],
                      ),
                    ),
                  )
                ),
            ],
          ),
        ),

        // 3. Paginador
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5))),
            color: Theme.of(context).colorScheme.surface,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  // ====== Widget Header Moderno ======
  Widget _buildModernHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.3))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Búsqueda tipo Píldora
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged, // Debounce activado
                  decoration: InputDecoration(
                    hintText: 'Buscar profesor...',
                    hintStyle: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.search, color: cs.primary),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: cs.primary.withOpacity(0.5), width: 1)),
                    suffixIcon: _searchCtrl.text.isNotEmpty 
                      ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: (){ _searchCtrl.clear(); _onSearchChanged(''); })
                      : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Toggle View
              Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.grid_view_rounded, color: _viewMode == _ViewMode.cards ? cs.primary : cs.onSurfaceVariant),
                      tooltip: 'Tarjetas',
                      onPressed: () => setState(() => _viewMode = _ViewMode.cards),
                    ),
                    Container(width: 1, height: 20, color: cs.outlineVariant),
                    IconButton(
                      icon: Icon(Icons.table_rows_rounded, color: _viewMode == _ViewMode.table ? cs.primary : cs.onSurfaceVariant),
                      tooltip: 'Tabla',
                      onPressed: () => setState(() => _viewMode = _ViewMode.table),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              
              // Exportar
              IconButton(
                icon: const Icon(Icons.download_rounded),
                tooltip: 'Exportar CSV',
                onPressed: _rows.isEmpty ? null : _exportCsv,
              ),
            ],
          ),
          // Filtro de tamaño de página (opcional, expandible)
          if (_loading) const SizedBox(height: 2) else const SizedBox.shrink(),
        ],
      ),
    );
  }

  // ====== Vista TABLA (Zebra Striped) ======
  Widget _table(BuildContext context, List<Map<String, dynamic>> rows) {
    final cs = Theme.of(context).colorScheme;
    final textStyle = _dense ? Theme.of(context).textTheme.bodySmall : Theme.of(context).textTheme.bodyMedium;

    String doc(Map r) {
      final v = r['cedula'] ?? r['dni'] ?? r['numero_cedula'] ?? '';
      return '$v'.trim().isEmpty ? '—' : '$v';
    }

     return Center( 
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card( // Tarjeta contenedora de la tabla
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cs.outlineVariant.withOpacity(0.4))),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(cs.surfaceContainerHighest.withOpacity(0.5)),
            headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface),
            dataRowMinHeight: _dense ? 36 : 48,
            dataRowMaxHeight: _dense ? 48 : 60,
            columnSpacing: 24,
            horizontalMargin: 20,
            columns: [
              DataColumn(label: const Text('Cédula'), onSort: (_,__) => _toggleSort('id_profesor')),
              DataColumn(label: const Text('Nombre'), onSort: (_,__) => _toggleSort('nombre_usuario')),
              const DataColumn(label: Text('Teléfono')),
              DataColumn(label: const Text('Correo'), onSort: (_,__) => _toggleSort('correo')),
              const DataColumn(label: Text('Estado')),
              const DataColumn(label: Text('Acciones')),
            ],
            // Zebra Striping Logic
            rows: rows.asMap().entries.map((entry) {
              final index = entry.key;
              final r = entry.value;
              final bool activo = r['activo'] == true;
              final isEven = index % 2 == 0;

              return DataRow(
                color: MaterialStateProperty.resolveWith<Color?>((states) {
                  return isEven ? Colors.transparent : cs.surfaceContainerHighest.withOpacity(0.2);
                }),
                cells: [
                  DataCell(Text(doc(r), style: textStyle)),
                  DataCell(Text((r['nombre_usuario'] ?? r['nombre'] ?? '').toString(), style: textStyle?.copyWith(fontWeight: FontWeight.w500))),
                  DataCell(Text('${r['telefono'] ?? '—'}', style: textStyle)),
                  DataCell(Text('${r['correo'] ?? ''}', style: textStyle)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: activo ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        activo ? 'Activo' : 'Inactivo',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: activo ? Colors.green : Colors.red),
                      ),
                    )
                  ),
                  DataCell(_rowActions(r: r, activo: activo, dense: true)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    )
    );
  }
  // ====== Vista TARJETAS (Modern Card) ======
  Widget _cards(BuildContext context, List<Map<String, dynamic>> rows) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Padding extra abajo para el FAB si lo hubiera
      itemCount: rows.length,
      itemBuilder: (_, i) {
        final r = rows[i];
        final activo = r['activo'] == true;
        final nombre = (r['nombre_usuario'] ?? r['nombre'] ?? '').toString();
        final telefono = r['telefono']?.toString() ?? '—';
        final cedula = r['cedula']?.toString() ?? '—';
        final initialsText = _getInitials(nombre);
        final color = _getAvatarColor('$nombre$cedula');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Material( // Material para el efecto Ripple
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openDetails(r),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar con Hero Animation
                    Hero(
                      tag: 'prof_avatar_${r['id_profesor']}',
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: color.withOpacity(0.15),
                        child: Text(
                          initialsText,
                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Info Central
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  nombre.isEmpty ? 'Sin nombre' : nombre,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Pill de estado
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: activo ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: activo ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3))
                                ),
                                child: Text(
                                  activo ? "ACTIVO" : "INACTIVO", 
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: activo ? Colors.green[700] : Colors.grey[700])
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              _iconText(context, Icons.badge_outlined, cedula),
                              if (telefono != '—') _iconText(context, Icons.phone_outlined, telefono),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Botón menú contextual
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: IconButton(
                        icon: Icon(Icons.more_vert, color: Theme.of(context).hintColor),
                        onPressed: () => _openDetails(r),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _iconText(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).hintColor),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor)),
      ],
    );
  }

  // ===== Utils =====
  String _getInitials(String? nombre) {
    final n = (nombre ?? '').trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (n.isEmpty) return '👤';
    final i1 = n.first.characters.first;
    final i2 = n.length > 1 ? n[1].characters.first : '';
    return (i1 + i2).toUpperCase();
  }

  Color _getAvatarColor(String seed) {
    final colors = [
      Colors.blue, Colors.teal, Colors.indigo, Colors.purple, 
      Colors.deepOrange, Colors.pink, Colors.green
    ];
    return colors[seed.hashCode.abs() % colors.length];
  }

  Widget _rowActions({required Map<String, dynamic> r, required bool activo, bool dense = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Editar',
          iconSize: 20,
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _openEdit(r),
        ),
        IconButton(
          tooltip: activo ? 'Desactivar' : 'Activar',
          iconSize: 20,
          icon: Icon(activo ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          color: activo ? Colors.grey : Colors.green,
          onPressed: () => _toggleActivo(r),
        ),
      ],
    );
  }

  Widget _kvIcon(BuildContext context, String label, String value, IconData icon, {bool copyable = false, String? copyLabel}) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              onPressed: () => _copy(context, copyLabel ?? label, value),
            )
        ],
      ),
    );
  }

  void _copy(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copiado'), behavior: SnackBarBehavior.floating));
  }

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
    _showCsvDialog(csv.toString(), 'profesores_export.csv');
  }

  static String _csv(Object? v) {
    final s = v?.toString() ?? '';
    if (s.contains(',') || s.contains('"') || s.contains('\n')) return '"${s.replaceAll('"', '""')}"';
    return s;
  }

  Future<void> _showCsvDialog(String data, String filename) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('CSV: $filename'),
        content: SizedBox(width: 600, height: 360, child: SelectableText(data)),
        actions: [
          TextButton(onPressed: () async {
            await Clipboard.setData(ClipboardData(text: data));
            if (mounted) Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copiado')));
          }, child: const Text('Copiar')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }
}

// =================== WIDGETS AUXILIARES ===================

class _Paginator extends StatelessWidget {
  const _Paginator({required this.page, required this.pageSize, required this.total, required this.onPage});
  final int page, pageSize, total;
  final void Function(int) onPage;

  @override
  Widget build(BuildContext context) {
    final to = (page * pageSize > total) ? total : (page * pageSize);
    final from = (total == 0) ? 0 : ((page - 1) * pageSize + 1);
    return Row(
      children: [
        Text('$from-$to de $total', style: const TextStyle(fontWeight: FontWeight.w500)),
        const Spacer(),
        IconButton.filledTonal(
          onPressed: page > 1 ? () => onPage(page - 1) : null,
          icon: const Icon(Icons.chevron_left),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: (to < total) ? () => onPage(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title, subtitle;
  final (String, VoidCallback?) primary;
  const _EmptyState({required this.title, required this.subtitle, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 80, color: Theme.of(context).disabledColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor)),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: primary.$2, icon: const Icon(Icons.refresh), label: Text(primary.$1)),
        ],
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text('Ocurrió un error', style: Theme.of(context).textTheme.titleMedium),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(error, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).hintColor)),
          ),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  final bool isNarrow, dense;
  final _ViewMode viewMode;
  const _LoadingPlaceholder({required this.isNarrow, required this.viewMode, required this.dense});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_,__) => const SizedBox(height: 12),
      itemBuilder: (_, i) => Container(
        height: viewMode == _ViewMode.cards ? 100 : 50,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _ProfesorDialog extends StatefulWidget {
  const _ProfesorDialog({required this.data});
  final Map<String, dynamic> data;
  @override
  State<_ProfesorDialog> createState() => _ProfesorDialogState();
}

class _ProfesorDialogState extends State<_ProfesorDialog> {
  final _formKey = GlobalKey<FormState>();
  // Controladores para los campos editables
  final _espCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _dirCtrl = TextEditingController();
  bool _activo = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Inicializar valores existentes
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
      final token = await SessionTokenProvider.instance.readToken();
      if (token == null) throw Exception('Sesión expirada');

      // Enviar solo los campos que la API espera para update
      await ApiService.putProfesor(
        token: token,
        idProfesor: (widget.data['id_profesor'] as num).toInt(),
        especialidad: _espCtrl.text.trim().isEmpty ? null : _espCtrl.text.trim(),
        telefono: _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
        direccion: _dirCtrl.text.trim().isEmpty ? null : _dirCtrl.text.trim(),
        activo: _activo,
      );

      if (mounted) Navigator.of(context).pop(true); // Retorna true si guardó
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Preparar datos de solo lectura
    final nombre = (widget.data['nombre_usuario'] ?? widget.data['nombre'] ?? '').toString();
    final correo = (widget.data['correo'] ?? '').toString();
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Editar profesor'),
      scrollable: true, // Hace que el contenido sea scrolleable si es muy alto
      content: SizedBox(
        width: 420, // Un poco más ancho para la dirección
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Campo de solo lectura (Nombre y Correo restaurados)
              TextFormField(
                initialValue: '$nombre\n$correo',
                enabled: false,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Usuario (Solo lectura)',
                  prefixIcon: Icon(Icons.person_outline, color: cs.onSurfaceVariant),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12)
                ),
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Campos editables con iconos
              TextFormField(
                controller: _espCtrl,
                decoration: const InputDecoration(
                  labelText: 'Especialidad',
                  prefixIcon: Icon(Icons.school_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
  controller: _telCtrl,
  keyboardType: TextInputType.phone,
  decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone_outlined), border: OutlineInputBorder()),
  // AGREGAR ESTO:
  validator: (value) {
    if (value != null && value.isNotEmpty) {
      if (value.length < 7) return 'Número muy corto';
      // Regex simple para permitir solo números, espacios y guiones
      if (!RegExp(r'^[0-9\-\+\s]+$').hasMatch(value)) return 'Caracteres no válidos';
    }
    return null;
  },
),
              const SizedBox(height: 16),
              // Campo de Dirección RESTAURADO
              TextFormField(
  controller: _dirCtrl,
  maxLines: 2,
  decoration: const InputDecoration(labelText: 'Dirección', prefixIcon: Icon(Icons.location_on_outlined), border: OutlineInputBorder()),
  // AGREGAR ESTO:
  validator: (value) {
    if (value == null || value.trim().isEmpty) return 'La dirección es obligatoria';
    return null;
  },
),
              const SizedBox(height: 16),
              
              // Switch de Activo estilizado
              Container(
                decoration: BoxDecoration(
                  color: _activo ? cs.primaryContainer.withOpacity(0.2) : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _activo ? cs.primary.withOpacity(0.3) : cs.outlineVariant)
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  value: _activo,
                  onChanged: (v) => setState(() => _activo = v),
                  title: Text('Usuario Activo', style: TextStyle(fontWeight: FontWeight.w600, color: _activo ? cs.primary : cs.onSurface)),
                  secondary: Icon(Icons.check_circle_outline, color: _activo ? cs.primary : cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
          label: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
        ),
      ],
    );
  }
}