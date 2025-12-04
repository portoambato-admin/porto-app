// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:characters/characters.dart';

import 'package:cross_file/cross_file.dart';
import 'package:file_selector/file_selector.dart';
import 'package:excel/excel.dart' as xls;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../app/app_scope.dart';

// ===== Helpers UI =====
String _iniciales(String nombres, String apellidos) {
  final n = nombres.trim().isEmpty ? '' : nombres.trim().split(' ').first;
  final a = apellidos.trim().isEmpty ? '' : apellidos.trim().split(' ').first;
  final i1 = n.isEmpty ? '' : n.characters.first;
  final i2 = a.isEmpty ? '' : a.characters.first;
  final r = (i1 + i2).toUpperCase();
  return r.isEmpty ? '👤' : r;
}

int? _toIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v');
}

Color _avatarColor(String seed){
  final h = seed.hashCode & 0xFFFFFF;
  return Color(0xFF000000 | h).withOpacity(1);
}

enum ViewMode { cards, table }
enum SortBy { apellidoAZ, apellidoZA, nombreAZ, reciente }

class SubcategoriaEstudiantesScreen extends StatefulWidget {
  final int idSubcategoria;
  final String nombreSubcategoria;
  final int? idCategoria;

  const SubcategoriaEstudiantesScreen({
    super.key,
    required this.idSubcategoria,
    required this.nombreSubcategoria,
    this.idCategoria,
  });

  @override
  State<SubcategoriaEstudiantesScreen> createState() => _SubcategoriaEstudiantesScreenState();
}

class _SubcategoriaEstudiantesScreenState extends State<SubcategoriaEstudiantesScreen> {
  late final _subcatEst = AppScope.of(context).subcatEst;
  late final _est = AppScope.of(context).estudiantes;
  late final _mat = AppScope.of(context).matriculas;

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  final _qCtrl = TextEditingController();
  bool _soloActivos = true;
  ViewMode _view = ViewMode.cards;
  SortBy _sort = SortBy.apellidoAZ;
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    super.dispose();
  }

  String? _cedulaDe(Map<String, dynamic> m) {
    final v = m['cedula'] ?? m['dni'] ?? m['documento'] ?? m['identificacion'] ?? m['id_doc'];
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final asign = await _subcatEst.porSubcategoria(widget.idSubcategoria);
      final list = <Map<String, dynamic>>[];
      
      for (final a in asign) {
        final idEst = _toIntOrNull(a['idEstudiante'] ?? a['id'] ?? a['id_estudiante']);
        if (idEst == null) continue;

        String? nombres = a['nombres']?.toString();
        String? apellidos = a['apellidos']?.toString();
        String? cedula = _cedulaDe(a);

        if ((nombres == null || apellidos == null) && a['estudiante'] != null) {
          final s = a['estudiante'].toString().trim();
          final parts = s.split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            nombres = parts.sublist(0, parts.length - 1).join(' ');
            apellidos = parts.last;
          } else {
            nombres = s; apellidos = '';
          }
        }

        if (nombres == null || apellidos == null || cedula == null) {
          try {
            final info = await _est.byId(idEst);
            nombres = info?['nombres']?.toString() ?? nombres ?? '—';
            apellidos = info?['apellidos']?.toString() ?? apellidos ?? '';
            cedula ??= _cedulaDe(Map<String, dynamic>.from(info ?? const {}));
          } catch (_) {}
        }

        list.add({
          'id': idEst,
          'nombres': nombres ?? '—',
          'apellidos': apellidos ?? '',
          'cedula': cedula,
          'activo': (a['activo'] is bool) ? a['activo'] : true,
        });
      }

      setState(() {
        _rows = list;
        _selected.clear();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _sortRows(List<Map<String,dynamic>> list) {
    final r = [...list];
    int cmp(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
    switch (_sort) {
      case SortBy.apellidoAZ: r.sort((a,b)=>cmp('${a['apellidos']}','${b['apellidos']}')); break;
      case SortBy.apellidoZA: r.sort((a,b)=>cmp('${b['apellidos']}','${a['apellidos']}')); break;
      case SortBy.nombreAZ:   r.sort((a,b)=>cmp('${a['nombres']}','${b['nombres']}')); break;
      case SortBy.reciente:   r.sort((a,b)=>((b['id']??0) as int).compareTo((a['id']??0) as int)); break;
    }
    return r;
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _qCtrl.text.trim().toLowerCase();
    final base = _rows.where((r) {
      if (_soloActivos && r['activo'] == false) return false;
      if (q.isEmpty) return true;
      final n = (r['nombres'] ?? '').toString().toLowerCase();
      final a = (r['apellidos'] ?? '').toString().toLowerCase();
      final full = ('$n $a').trim();
      final ced = (r['cedula'] ?? '').toString().toLowerCase();
      return n.contains(q) || a.contains(q) || full.contains(q) || ced.contains(q);
    }).toList();
    return _sortRows(base);
  }

  List<Map<String, dynamic>> _selectedOrFiltered() {
    if (_selected.isEmpty) return _filtered;
    return _rows.where((r) => _selected.contains(_toIntOrNull(r['id']) ?? -1)).toList();
  }

  // ===== Export helpers =====
  String _csv(List<Map<String,dynamic>> rows){
    const cols = ['id','nombres','apellidos','cedula','activo'];
    String esc(v){ final s='${v??''}'; return '"${s.replaceAll('"','""')}"'; }
    final header = cols.map(esc).join(',');
    final lines = rows.map((r)=>cols.map((c)=>esc(r[c])).join(','));
    return ([header, ...lines]).join('\n');
  }

  Uint8List _csvBytes(List<Map<String, dynamic>> rows) => Uint8List.fromList(utf8.encode(_csv(rows)));

  Uint8List _excelBytes(List<Map<String, dynamic>> rows) {
    final book = xls.Excel.createExcel();
    final sheet = book['Estudiantes'];
    sheet.appendRow([xls.TextCellValue('ID'), xls.TextCellValue('Nombres'), xls.TextCellValue('Apellidos'), xls.TextCellValue('Cédula'), xls.TextCellValue('Activo')]);
    for (final r in rows) {
      sheet.appendRow([
        xls.TextCellValue('${r['id'] ?? ''}'), xls.TextCellValue('${r['nombres'] ?? ''}'), xls.TextCellValue('${r['apellidos'] ?? ''}'), xls.TextCellValue('${r['cedula'] ?? ''}'), xls.TextCellValue(r['activo'] == true ? 'Activo' : 'Inactivo'),
      ]);
    }
    return Uint8List.fromList(book.encode()!);
  }

  Future<Uint8List> _pdfBytes(List<Map<String, dynamic>> rows) async {
    final doc = pw.Document();
    final headers = ['ID','Nombres','Apellidos','Cédula','Estado'];
    final data = [for (final r in rows) ['${r['id'] ?? ''}', '${r['nombres'] ?? ''}', '${r['apellidos'] ?? ''}', '${r['cedula'] ?? ''}', (r['activo']==true) ? 'Activo' : 'Inactivo']];
    doc.addPage(pw.MultiPage(
      pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(24)),
      header: (ctx) => pw.Text('Estudiantes — ${widget.nombreSubcategoria}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      build: (ctx) => [pw.SizedBox(height: 8), pw.Table.fromTextArray(headers: headers, data: data, headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold), headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200), cellAlignment: pw.Alignment.centerLeft, cellStyle: const pw.TextStyle(fontSize: 10), rowDecoration: const pw.BoxDecoration(), border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400))],
    ));
    return await doc.save();
  }

  Future<void> _saveBytes(Uint8List bytes, {required String defaultFileName, required List<String> extensions, String? mimeType}) async {
    try {
      final path = await getSaveLocation(suggestedName: defaultFileName);
      if (path == null) return;
      final xf = XFile.fromData(bytes, name: defaultFileName, mimeType: mimeType);
      await xf.saveTo(path.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Guardado: $defaultFileName')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ===== Acciones =====
  Future<void> _exportCsvFile() async => await _saveBytes(_csvBytes(_selectedOrFiltered()), defaultFileName: 'estudiantes_${widget.nombreSubcategoria}.csv', extensions: ['csv'], mimeType: 'text/csv');
  Future<void> _exportExcelFile() async => await _saveBytes(_excelBytes(_selectedOrFiltered()), defaultFileName: 'estudiantes_${widget.nombreSubcategoria}.xlsx', extensions: ['xlsx'], mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  Future<void> _exportPdfFile() async => await _saveBytes(await _pdfBytes(_selectedOrFiltered()), defaultFileName: 'estudiantes_${widget.nombreSubcategoria}.pdf', extensions: ['pdf'], mimeType: 'application/pdf');
  Future<void> _previewPdf() async => await Printing.layoutPdf(onLayout: (_) async => await _pdfBytes(_selectedOrFiltered()));

  // ========================= DIÁLOGO INSCRIPCIÓN PREMIUM (MEJORADO) =========================
  Future<void> _inscribir() async {
    final formKey = GlobalKey<FormState>();
    final nombres = TextEditingController();
    final apellidos = TextEditingController();
    final telefono = TextEditingController();
    final direccion = TextEditingController();
    final fecha = TextEditingController();
    int idAcademia = 1;
    
    // Tema azul personalizado
    final bluePrimary = Colors.blue.shade800;
    final blueLight = Colors.blue.shade50;

    // Helper decorativo con validación visual
    InputDecoration deco(String l, IconData i, {String? hint}) => InputDecoration(
      labelText: l, 
      hintText: hint,
      labelStyle: TextStyle(color: Colors.blue.shade700),
      prefixIcon: Icon(i, size: 20, color: Colors.blue.shade600), 
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.transparent)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.blue.shade600, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.red.shade300, width: 1)),
      filled: true, 
      fillColor: Colors.blue.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
    );

    // Función para mostrar el calendario
    Future<void> _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)), // Hace 10 años por defecto
        firstDate: DateTime(1990),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: bluePrimary),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        // Formato YYYY-MM-DD
        final formatted = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        fecha.text = formatted;
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabecera con gradiente azul fuerte
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade900, Colors.blue.shade600], 
                      begin: Alignment.topLeft, 
                      end: Alignment.bottomRight
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Inscribir Estudiante', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('En: ${widget.nombreSubcategoria}', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                ),
                
                // Formulario
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: nombres, 
                          decoration: deco('Nombres', Icons.badge_outlined), 
                          textCapitalization: TextCapitalization.words,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Los nombres son requeridos';
                            if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                            return null;
                          }
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: apellidos, 
                          decoration: deco('Apellidos', Icons.person_outline), 
                          textCapitalization: TextCapitalization.words,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Los apellidos son requeridos';
                            if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                            return null;
                          }
                        ),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(child: TextFormField(
                            controller: telefono, 
                            decoration: deco('Teléfono', Icons.phone_outlined),
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v != null && v.isNotEmpty) {
                                if (!RegExp(r'^[0-9+]+$').hasMatch(v)) return 'Solo números';
                              }
                              return null;
                            },
                          )), 
                          const SizedBox(width: 12), 
                          Expanded(child: TextFormField(
                            controller: fecha, 
                            readOnly: true, // No escribir, solo seleccionar
                            onTap: () => _selectDate(ctx),
                            decoration: deco('Nacimiento', Icons.calendar_today_outlined, hint: 'YYYY-MM-DD'),
                          ))
                        ]),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: direccion, 
                          decoration: deco('Dirección', Icons.location_on_outlined),
                          validator: (v) {
                            if (v != null && v.isNotEmpty && v.length < 5) return 'Dirección muy corta';
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        
                        // Botón de acción
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: bluePrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                            ),
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              try {
                                final nuevo = await _est.crear(nombres: nombres.text, apellidos: apellidos.text, telefono: telefono.text, direccion: direccion.text, fechaNacimiento: fecha.text, idAcademia: idAcademia);
                                final idEst = _toIntOrNull(nuevo['id'] ?? nuevo['id_estudiante']);
                                if (idEst == null) throw Exception('Error ID');
                                if (widget.idCategoria != null) await _mat.crear(idEstudiante: idEst, idCategoria: widget.idCategoria!, ciclo: null);
                                await _subcatEst.asignar(idEstudiante: idEst, idSubcategoria: widget.idSubcategoria);
                                if (mounted) { Navigator.pop(context); _load(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inscrito correctamente'), behavior: SnackBarBehavior.floating)); }
                              } catch (e) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                              }
                            },
                            icon: const Icon(Icons.save_as_rounded),
                            label: const Text('REGISTRAR E INSCRIBIR', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== MENÚ FAB (RESTAURADO) =====
  Future<void> _showFabMenu() async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final size = overlay.size;
    
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(size.width - 80, size.height - 100, 16, 80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      items: [
        const PopupMenuItem(
          value: 'inscribir',
          child: ListTile(
            leading: Icon(Icons.person_add, color: Colors.blue), 
            title: Text('Inscribir estudiante', style: TextStyle(fontWeight: FontWeight.bold)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'export_excel', child: ListTile(leading: Icon(Icons.grid_on), title: Text('Exportar Excel'), contentPadding: EdgeInsets.zero)),
        const PopupMenuItem(value: 'export_pdf', child: ListTile(leading: Icon(Icons.picture_as_pdf), title: Text('Exportar PDF'), contentPadding: EdgeInsets.zero)),
        const PopupMenuItem(value: 'export_csv', child: ListTile(leading: Icon(Icons.table_chart), title: Text('Exportar CSV'), contentPadding: EdgeInsets.zero)),
        const PopupMenuItem(value: 'preview_pdf', child: ListTile(leading: Icon(Icons.print), title: Text('Vista previa PDF'), contentPadding: EdgeInsets.zero)),
      ],
    );

    switch (selected) {
      case 'inscribir':   _inscribir(); break;
      case 'export_excel': _exportExcelFile(); break;
      case 'export_pdf':   _exportPdfFile(); break;
      case 'export_csv':   _exportCsvFile(); break;
      case 'preview_pdf':  _previewPdf(); break;
    }
  }

  // ===== UI Principal =====
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data = _filtered;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          _buildHeader(context),
          if (_selected.isNotEmpty) _buildSelectionBar(context),
          if (_error != null) Container(color: cs.errorContainer, padding: const EdgeInsets.all(8), width: double.infinity, child: Text(_error!, style: TextStyle(color: cs.onErrorContainer), textAlign: TextAlign.center)),
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator()) 
              : data.isEmpty 
                ? _buildEmpty() 
                : _view == ViewMode.cards ? _buildCards(data) : _buildTable(data),
          ),
        ],
      ),
      // FAB RESTAURADO
      floatingActionButton: FloatingActionButton(
        onPressed: _showFabMenu,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    // Contadores KPI
    final total = _rows.length;
    final activos = _rows.where((e) => e['activo'] == true).length;
    final inactivos = total - activos;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: cs.surface, border: Border(bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.3))), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.nombreSubcategoria, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('$total estudiantes', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ])),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: 'Recargar'),
            ],
          ),
          const SizedBox(height: 12),
          // Chips de KPI RESTAURADOS
          Row(
            children: [
              _kpiChip(Icons.people, 'Total: $total', Colors.blue),
              const SizedBox(width: 8),
              _kpiChip(Icons.verified_user, 'Activos: $activos', Colors.green),
              const SizedBox(width: 8),
              _kpiChip(Icons.person_off, 'Inactivos: $inactivos', Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Buscar estudiante...',
                    prefixIcon: Icon(Icons.search, color: cs.primary),
                    filled: true, fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    suffixIcon: _qCtrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _qCtrl.clear())) : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(color: cs.surfaceContainerHighest.withOpacity(0.4), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  IconButton(icon: Icon(Icons.grid_view_rounded, color: _view == ViewMode.cards ? cs.primary : cs.onSurfaceVariant), onPressed: () => setState(() => _view = ViewMode.cards)),
                  IconButton(icon: Icon(Icons.table_rows_rounded, color: _view == ViewMode.table ? cs.primary : cs.onSurfaceVariant), onPressed: () => setState(() => _view = ViewMode.table)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [Icon(icon, size: 14, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color))]),
    );
  }

  Widget _buildSelectionBar(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('${_selected.length} seleccionados', style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
          const Spacer(),
          TextButton.icon(onPressed: () => setState(() => _selected.clear()), icon: const Icon(Icons.close), label: const Text('Limpiar')),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.group_off_outlined, size: 64, color: Theme.of(context).disabledColor), const SizedBox(height: 16), const Text('No se encontraron estudiantes')]));

  Widget _buildCards(List<Map<String, dynamic>> data) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (_, i) {
        final r = data[i];
        final id = r['id'] as int;
        final selected = _selected.contains(id);
        final nombre = '${r['nombres']} ${r['apellidos']}';
        final cedula = r['cedula'] ?? '—';
        final activo = r['activo'] == true;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: selected ? Theme.of(context).primaryColor : Colors.transparent, width: 2)),
          color: selected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : null,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => selected ? _selected.remove(id) : _selected.add(id)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Hero(
                    tag: 'est_$id',
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: _avatarColor(nombre),
                      child: Text(_iniciales(r['nombres'], r['apellidos']), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Cédula: $cedula', style: TextStyle(color: Theme.of(context).hintColor)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: activo ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(activo ? 'Activo' : 'Inactivo', style: TextStyle(color: activo ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                  if (selected) const Icon(Icons.check_circle, color: Colors.blue),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Sel')),
          DataColumn(label: Text('Nombre')),
          DataColumn(label: Text('Cédula')),
          DataColumn(label: Text('Estado')),
        ],
        rows: data.map((r) {
          final id = r['id'] as int;
          return DataRow(
            selected: _selected.contains(id),
            onSelectChanged: (v) => setState(() => v == true ? _selected.add(id) : _selected.remove(id)),
            cells: [
              DataCell(Checkbox(value: _selected.contains(id), onChanged: (v) => setState(() => v == true ? _selected.add(id) : _selected.remove(id)))),
              DataCell(Text('${r['nombres']} ${r['apellidos']}')),
              DataCell(Text(r['cedula'] ?? '—')),
              DataCell(Text(r['activo'] == true ? 'Activo' : 'Inactivo')),
            ],
          );
        }).toList(),
      ),
    );
  }
}