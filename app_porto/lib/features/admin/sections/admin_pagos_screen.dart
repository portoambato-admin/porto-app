import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_scope.dart';

/// Estados posibles de una mensualidad en tu backend
const _kEstados = <String>['pendiente', 'pagado', 'anulado'];

class AdminPagosScreen extends StatefulWidget {
  /// Si vienes desde la ficha del estudiante, puedes filtrar por él
  final int? idEstudiante;
  /// O desde una matrícula específica
  final int? idMatricula;

  const AdminPagosScreen({super.key, this.idEstudiante, this.idMatricula});

  @override
  State<AdminPagosScreen> createState() => _AdminPagosScreenState();
}

class _AdminPagosScreenState extends State<AdminPagosScreen> {
  late dynamic _mensRepo;
  dynamic _estRepo; // por si queremos resolver nombre de estudiante

  bool _loading = false;
  String? _error;

  // Filtros
  final _search = TextEditingController(); // buscar por estudiante/observación (si existiera)
  String? _estado; // null = todos
  int? _idEstudiante;
  int? _idMatricula;

  // Datos
  List<Map<String, dynamic>> _rows = [];
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _idEstudiante = widget.idEstudiante;
    _idMatricula = widget.idMatricula;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppScope.of(context);
    _mensRepo = scope.mensualidades; // asegúrate que existe en AppScope
    try { _estRepo = scope.estudiantes; } catch (_) {}
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String? get _q {
    final s = _search.text.trim();
    return s.isEmpty ? null : s;
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      List<Map<String, dynamic>> data = [];
      // Preferencias de filtro:
      if (_idMatricula != null) {
        data = await _mensRepo.porMatricula(_idMatricula!);
      } else if (_idEstudiante != null) {
        data = await _mensRepo.porEstudiante(_idEstudiante!);
      } else {
        // Si tu repo no tiene list() global, mostramos vacío con hint
        try {
          data = await _mensRepo.list(); // opcional, si existe
        } catch (_) {
          data = [];
        }
      }

      // Filtro por estado si aplica
      if (_estado != null && _estado!.isNotEmpty) {
        data = data.where((e) => (e['estado']?.toString() ?? '').toLowerCase() == _estado).toList();
      }

      // Filtro básico por texto (busca en estudianteNombre, categoriaNombre)
      if (_q != null) {
        final ql = _q!.toLowerCase();
        data = data.where((e) {
          final a = (e['estudianteNombre'] ?? '').toString().toLowerCase();
          final b = (e['categoriaNombre'] ?? '').toString().toLowerCase();
          return a.contains(ql) || b.contains(ql);
        }).toList();
      }

      setState(() {
        _rows = data..sort((a, b) {
          // ordena por creado descendente si existe; si no, por id desc.
          final ca = a['creadoEn']?.toString() ?? '';
          final cb = b['creadoEn']?.toString() ?? '';
          final c = cb.compareTo(ca);
          if (c != 0) return c;
          final ia = (a['id'] as num?)?.toInt() ?? 0;
          final ib = (b['id'] as num?)?.toInt() ?? 0;
          return ib.compareTo(ia);
        });
        _total = _rows.length;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // ===== Acciones =====

  Future<void> _cambiarEstado(Map<String, dynamic> r, String nuevo) async {
    final id = (r['id'] as num?)?.toInt();
    if (id == null) return;
    setState(() => _loading = true);
    try {
      await _mensRepo.cambiarEstado(idMensualidad: id, estado: nuevo);
      _showSnack('Estado actualizado a "$nuevo"');
      await _load();
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _crearMensualidad() async {
    // Diálogo simple para crear manualmente (cuando no vienes desde matrícula)
    final formKey = GlobalKey<FormState>();
    final idMat = TextEditingController(text: _idMatricula?.toString() ?? '');
    final mes = TextEditingController();
    final anio = TextEditingController();
    final valor = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva mensualidad'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: idMat,
                  decoration: const InputDecoration(
                    labelText: 'ID Matrícula',
                    prefixIcon: Icon(Icons.badge),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => (int.tryParse(v ?? '') == null) ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: mes,
                        decoration: const InputDecoration(
                          labelText: 'Mes (1-12)',
                          prefixIcon: Icon(Icons.calendar_month),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final m = int.tryParse(v ?? '');
                          if (m == null || m < 1 || m > 12) return '1-12';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: anio,
                        decoration: const InputDecoration(
                          labelText: 'Año',
                          prefixIcon: Icon(Icons.date_range),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => (int.tryParse(v ?? '') == null) ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: valor,
                  decoration: const InputDecoration(
                    labelText: 'Valor',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]'))],
                  validator: (v) => ((v ?? '').trim().isEmpty) ? 'Requerido' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final idMatricula = int.parse(idMat.text.trim());
                final m = int.parse(mes.text.trim());
                final a = int.parse(anio.text.trim());
                final vStr = valor.text.trim().replaceAll('.', '').replaceAll(',', '.');
                final v = double.parse(vStr);
                await _mensRepo.crear(
                  idMatricula: idMatricula,
                  mes: m,
                  anio: a,
                  valor: v,
                );
                if (mounted) Navigator.pop(ctx);
                await _load();
                _showSnack('Mensualidad creada');
              } catch (e) {
                _showSnack('Error: $e');
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _exportCsv() {
    final csv = StringBuffer()
      ..writeln('ID,Estudiante,Matricula,Mes,Anio,Valor,Estado,Categoria,Creado');
    for (final r in _rows) {
      final id = r['id'] ?? '';
      final est = _csv(r['estudianteNombre'] ?? r['estudiante'] ?? '');
      final mat = r['idMatricula'] ?? '';
      final mes = r['mes'] ?? '';
      final anio = r['anio'] ?? '';
      final val = r['valor']?.toString() ?? '';
      final estd = r['estado'] ?? '';
      final cat = _csv(r['categoriaNombre'] ?? '');
      final cre = r['creadoEn']?.toString().split('T').first ?? '';
      csv.writeln('$id,$est,$mat,$mes,$anio,$val,$estd,$cat,$cre');
    }
    final content = csv.toString();

    if (kIsWeb) {
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final a = html.AnchorElement(href: url)..download = 'mensualidades.csv';
      a.click();
      html.Url.revokeObjectUrl(url);
    } else {
      _showCsvDialog(content, 'mensualidades.csv');
    }
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
              _showSnack('Copiado al portapapeles');
            },
            child: const Text('Copiar'),
          ),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagos / Mensualidades')),
      body: LayoutBuilder(
        builder: (ctx, c) {
          final isNarrow = c.maxWidth < 800;
          const maxW = 1200.0;
          final width = c.maxWidth > maxW ? maxW : c.maxWidth;

          final header = _buildHeader(isNarrow);
          final body = _buildBody(isNarrow);

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    const SizedBox(height: 12),
                    Expanded(child: body),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: (_idMatricula != null)
          ? FloatingActionButton.extended(
              onPressed: _crearMensualidad,
              icon: const Icon(Icons.add),
              label: const Text('Nueva mensualidad'),
            )
          : null,
    );
  }

  Widget _buildHeader(bool isNarrow) {
    final searchField = TextField(
      controller: _search,
      decoration: InputDecoration(
        hintText: 'Buscar por estudiante o categoría...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          tooltip: 'Limpiar',
          icon: const Icon(Icons.clear),
          onPressed: () { _search.clear(); _load(); },
        ),
      ),
      onSubmitted: (_) => _load(),
    );

    final estado = DropdownButtonFormField<String?>(
      value: _estado,
      decoration: const InputDecoration(prefixIcon: Icon(Icons.filter_alt), labelText: 'Estado'),
      items: <DropdownMenuItem<String?>>[
        const DropdownMenuItem(value: null, child: Text('Todos')),
        ..._kEstados.map((e) => DropdownMenuItem(value: e, child: Text(e))),
      ],
      onChanged: (v) { setState(() => _estado = v); _load(); },
    );

    final exportBtn = OutlinedButton.icon(
      onPressed: _rows.isEmpty ? null : _exportCsv,
      icon: const Icon(Icons.download),
      label: const Text('Exportar'),
    );

    final filtrosExtra = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_idEstudiante != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(label: Text('Estudiante: $_idEstudiante')),
          ),
        if (_idMatricula != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(label: Text('Matrícula: $_idMatricula')),
          ),
      ],
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: double.infinity, child: searchField),
          const SizedBox(height: 8),
          estado,
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [filtrosExtra, exportBtn]),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: searchField),
        const SizedBox(width: 8),
        SizedBox(width: 220, child: estado),
        const Spacer(),
        filtrosExtra,
        exportBtn,
      ],
    );
  }

  Widget _buildBody(bool isNarrow) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_rows.isEmpty) {
      return Center(
        child: Text(_idEstudiante == null && _idMatricula == null
            ? 'No hay datos.\nSugerencia: entra desde un Estudiante o una Matrícula para ver sus mensualidades.'
            : 'Sin mensualidades que coincidan con los filtros.'),
      );
    }
    return isNarrow ? _cards() : _table();
  }

  Widget _table() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Estudiante')),
          DataColumn(label: Text('Matrícula')),
          DataColumn(label: Text('Mes')),
          DataColumn(label: Text('Año')),
          DataColumn(label: Text('Valor')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Categoría')),
          DataColumn(label: Text('Creado')),
          DataColumn(label: Text('Acciones')),
        ],
        rows: _rows.map((r) {
          final id = (r['id'] as num?)?.toInt() ?? 0;
          final estado = (r['estado'] ?? '').toString();
          return DataRow(cells: [
            DataCell(Text('$id')),
            DataCell(Text(r['estudianteNombre']?.toString() ?? r['estudiante']?.toString() ?? '')),
            DataCell(Text('${r['idMatricula'] ?? ''}')),
            DataCell(Text('${r['mes'] ?? ''}')),
            DataCell(Text('${r['anio'] ?? ''}')),
            DataCell(Text(_fmtMoney(r['valor']))),
            DataCell(_estadoPill(estado)),
            DataCell(Text(r['categoriaNombre']?.toString() ?? '')),
            DataCell(Text(r['creadoEn']?.toString().split('T').first ?? '')),
            DataCell(_accionesFila(r)),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _cards() {
    return ListView.separated(
      itemCount: _rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final r = _rows[i];
        final estado = (r['estado'] ?? '').toString();
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(ctx).dividerColor)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('ID ${r['id'] ?? ''}', style: Theme.of(ctx).textTheme.titleMedium),
                    const Spacer(),
                    _estadoPill(estado),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Estudiante: ${r['estudianteNombre'] ?? r['estudiante'] ?? '—'}'),
                Text('Matrícula: ${r['idMatricula'] ?? '—'}'),
                Text('Periodo: ${r['mes'] ?? '—'}/${r['anio'] ?? '—'}'),
                Text('Categoría: ${r['categoriaNombre'] ?? '—'}'),
                Text('Valor: ${_fmtMoney(r['valor'])}'),
                Text('Creado: ${r['creadoEn']?.toString().split('T').first ?? ''}'),
                const SizedBox(height: 8),
                _accionesFila(r, dense: true),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _accionesFila(Map<String, dynamic> r, {bool dense = false}) {
    final estado = (r['estado'] ?? '').toString();
    return Wrap(
      spacing: dense ? 4 : 8,
      children: [
        PopupMenuButton<String>(
          tooltip: 'Cambiar estado',
          onSelected: (v) => _cambiarEstado(r, v),
          itemBuilder: (ctx) => _kEstados.map((e) => PopupMenuItem(value: e, child: Text(e))).toList(),
          child: OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.autorenew),
            label: Text('Estado: $estado'),
          ),
        ),
      ],
    );
  }

  Widget _estadoPill(String s) {
    Color bg;
    switch (s) {
      case 'pagado': bg = Colors.green.withOpacity(.15); break;
      case 'anulado': bg = Colors.red.withOpacity(.15); break;
      default: bg = Colors.orange.withOpacity(.15);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(s.isEmpty ? '—' : s),
    );
  }

  String _fmtMoney(dynamic v) {
    if (v == null) return '—';
    final s = v.toString();
    final norm = s.replaceAll('.', '').replaceAll(',', '.');
    final d = double.tryParse(norm) ?? double.tryParse(s);
    if (d == null) return s;
    return d.toStringAsFixed(2);
  }
}
