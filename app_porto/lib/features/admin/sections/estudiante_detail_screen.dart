import 'dart:convert';
import 'dart:typed_data';

import 'package:app_porto/core/services/session_token_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// --- Imports Adicionales (traídos desde AdminPagosScreen) ---
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:app_porto/core/constants/endpoints.dart'; // Asegúrate que esta ruta sea correcta
import 'package:app_porto/features/admin/data/pagos_repository.dart'; // Asegúrate que esta ruta sea correcta
// --- Fin Imports Adicionales ---

import 'package:app_porto/app/app_scope.dart';

// ===== Export helpers =====
import 'package:cross_file/cross_file.dart';
import 'package:file_selector/file_selector.dart';
import 'package:excel/excel.dart' as xls;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Import para cargar fuentes .ttf manualmente
import 'package:flutter/services.dart' show rootBundle;
// Import para las fuentes de Google (si usas el paquete)
// import 'package:pdf_google_fonts/pdf_google_fonts.dart';

// =========================================================
// ===== HELPER FUNCTIONS (Top-level) =====
// =========================================================
double _asDouble(dynamic v) =>
    (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;

String _mesNombre(int? m) {
  const meses = [
    '',
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
  if (m == null || m < 1 || m > 12) return '-';
  return meses[m];
}
// =========================================================
// =========================================================

class EstudianteDetailScreen extends StatefulWidget {
  final int id;
  const EstudianteDetailScreen({super.key, required this.id});

  @override
  State<EstudianteDetailScreen> createState() => _EstudianteDetailScreenState();
}

class _EstudianteDetailScreenState extends State<EstudianteDetailScreen>
    with SingleTickerProviderStateMixin {
  // ===== Repos de Info =====
  late dynamic _est;
  late dynamic _mat;
  late dynamic _asig;
  late dynamic _cats;
  late dynamic _subs;
  bool _canViewPagos = true;

  String _roleFromJwt(String token) {
    try {
      var t = token.trim();
      if (t.toLowerCase().startsWith('bearer ')) {
        t = t.substring(7).trim();
      }

      final parts = t.split('.');
      if (parts.length != 3) return '';

      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final jsonMap = jsonDecode(payload);

      if (jsonMap is! Map<String, dynamic>) return '';

      dynamic rol = jsonMap['rol'] ?? jsonMap['role'] ?? jsonMap['Rol'];

      // Soporta: rol: "profesor"
      if (rol is String) return rol.trim();

      // Soporta: rol: { nombre: "profesor" } o { name: "profesor" }
      if (rol is Map) {
        final m = Map<String, dynamic>.from(rol as Map);
        return (m['nombre'] ?? m['name'] ?? '').toString().trim();
      }

      return rol?.toString().trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  // ===== Repos de Pagos (NUEVO - traído de AdminPagosScreen) =====
  dynamic get _mensRepo => AppScope.of(context).mensualidades;
  PagosRepository get _pagosRepo => AppScope.of(context).pagos;
  dynamic get _matriculasRepo => AppScope.of(context).matriculas;
  dynamic get _http => AppScope.of(context).http;

  final _fmtMoney = NumberFormat.currency(locale: 'es_EC', symbol: r'$');

  // Tabs
  late final TabController _tab = TabController(length: 2, vsync: this);
  final _rightScrollCtl = ScrollController(); // Para la lista de pagos

  // ===== Estado (info) =====
  Map<String, dynamic>? _info;
  Map<String, dynamic>? _matricula; // única (si existe)
  List<Map<String, dynamic>> _asignaciones = [];
  List<Map<String, dynamic>> _categorias = [];

  // UI asignación subcategoría
  int? _catForAssign;
  int? _subToAssign;
  List<Map<String, dynamic>> _subsDeCat = [];

  bool _loading = true; // Carga inicial de Info
  String? _error;

  // ===== Estado (pagos - NUEVO - traído de AdminPagosScreen) =====
  bool _loadingMens = false;
  String? _pagosError;
  List<Map<String, dynamic>> _mensualidades = [];
  final Map<int, Map<String, dynamic>> _resumenCache = {};
  final Map<int, List<Map<String, dynamic>>> _pagosCache = {};
  bool _generandoMens = false;
  double _totValor = 0, _totPagado = 0, _totPendiente = 0;

  // Filtros de pagos
  String _estado = 'Todos'; // Todos | pendiente | pagado | anulado
  int? _anioFiltro; // null = todos
  bool _soloPendiente = false;
  final Set<int> _openYears = <int>{};

  // ===== Auth gate (NUEVO - traído de AdminPagosScreen) =====
  bool _authChecked = false; // ya verifiqué token
  bool _isAuth = false; // hay token válido
  bool get _blocked => !_authChecked || !_isAuth;

  @override
  void initState() {
    super.initState();

    // ===== FIX DEFINITIVO =====
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scope = AppScope.of(context);

      _est = scope.estudiantes;
      _mat = scope.matriculas;
      _asig = scope.subcatEst;
      _cats = scope.categorias;
      _subs = scope.subcategorias;

      _checkAuthAndLoad();
    });
    // ==========================

    _tab.addListener(() {
      setState(() {});
      if (_tab.index == 1) _cargarMensualidades();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _rightScrollCtl.dispose();
    super.dispose();
  }

  // ===== Lógica de Auth (NUEVO) =====
  Future<void> _checkAuthAndLoad() async {
    try {
      final tp = SessionTokenProvider.instance;
      final t = await tp.readToken();

      if (!mounted) return;

      final hasToken = (t != null && t.isNotEmpty);

      final rol = hasToken ? _roleFromJwt(t!) : '';

      // ✅ LISTA BLANCA: solo estos roles ven pagos
      final allowedToViewPagos = <String>{'admin', 'representante'};
      final canViewPagos =
          hasToken && allowedToViewPagos.contains(rol.toLowerCase());

      setState(() {
        _authChecked = true;
        _isAuth = hasToken;
        _canViewPagos =
            canViewPagos; // ❗ ahora por defecto NO ve pagos si rol viene vacío
      });

      if (_isAuth) {
        await _loadAll();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _authChecked = true;
        _isAuth = false;
        _canViewPagos = false;
        _error = 'Error de autenticación: $e';
        _loading = false;
      });
    }
  }

  void _goToLogin() {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      Navigator.of(context).pushNamed('/login');
    }
  }

  void _showLoginSnack() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debes iniciar sesión para esta acción.')),
    );
  }

  // ===== Carga de Datos =====

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await _est.byId(widget.id);
      final mats = await _mat.porEstudiante(widget.id);
      final unica = (mats.isNotEmpty) ? mats.first : null;
      final asign = await _asig.porEstudiante(widget.id);
      final cats = await _fetchCategorias();

      setState(() {
        _info = info;
        _matricula = unica;
        _asignaciones = asign;
        _categorias = cats;
        _loadingMens = false;
        _pagosError = null;
        _mensualidades = [];
        _resumenCache.clear();
        _pagosCache.clear();
        _totValor = 0;
        _totPagado = 0;
        _totPendiente = 0;
        _openYears.clear();
      });

      if (_tab.index == 1) {
        await _cargarMensualidades();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- Helpers de formato (para Info) ----------
  String _fmt(Object? v) => (v == null || '$v'.trim().isEmpty) ? '—' : '$v';

  String _fmtDate(Object? v) {
    if (v == null) return '—';
    final s = v.toString();
    try {
      final d = DateTime.parse(s);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return s.isEmpty ? '—' : s;
    }
  }

  String _categoriaLabel(Map<String, dynamic>? m) {
    if (m == null) return '—';
    final byName = m['categoriaNombre'];
    if (byName != null && byName.toString().trim().isNotEmpty) return '$byName';

    final id = m['idCategoria'] ?? m['id_categoria'];
    if (id == null) return '—';

    final match = _categorias.firstWhere(
      (c) => ((c['id_categoria'] ?? c['id']).toString() == '$id'),
      orElse: () => const {},
    );
    return (match['nombre_categoria'] ?? match['nombre'] ?? '—').toString();
  }

  // ---------- Helpers repos (para Info) ----------
  Future<List<Map<String, dynamic>>> _fetchCategorias() async {
    final dyn = _cats as dynamic;
    try {
      final r = await dyn.activas();
      return List<Map<String, dynamic>>.from(r);
    } catch (_) {}
    try {
      final r = await dyn.todas();
      return List<Map<String, dynamic>>.from(r);
    } catch (_) {}
    try {
      final r = await dyn.listar();
      return List<Map<String, dynamic>>.from(r);
    } catch (_) {}
    try {
      final r = await dyn.getAll();
      return List<Map<String, dynamic>>.from(r);
    } catch (_) {}
    return const <Map<String, dynamic>>[];
  }

  Future<void> _loadSubsForCat(int idCat) async {
    final dyn = _subs as dynamic;
    try {
      final r = await dyn.porCategoria(idCat);
      setState(() {
        _subsDeCat = List<Map<String, dynamic>>.from(r);
        _subToAssign = null;
      });
      return;
    } catch (_) {}
    try {
      final all = await dyn.todas();
      final list = List<Map<String, dynamic>>.from(all).where((e) {
        final a = e['id_categoria'] ?? e['idCategoria'];
        return a?.toString() == '$idCat';
      }).toList();
      setState(() {
        _subsDeCat = list;
        _subToAssign = null;
      });
    } catch (_) {
      setState(() {
        _subsDeCat = [];
        _subToAssign = null;
      });
    }
  }

  Future<void> _updateMatriculaFlexible({
    required int idMatricula,
    int? idCategoria,
    String? ciclo,
    String? fechaISO, // yyyy-MM-dd
  }) async {
    final dyn = _mat as dynamic;
    final Map<String, dynamic> dataSnake = {
      if (idCategoria != null) 'id_categoria': idCategoria,
      if (ciclo != null) 'ciclo': ciclo,
      if (fechaISO != null) 'fecha_matricula': fechaISO,
    };
    final Map<String, dynamic> dataCamel = {
      if (idCategoria != null) 'idCategoria': idCategoria,
      if (ciclo != null) 'ciclo': ciclo,
      if (fechaISO != null) 'fechaMatricula': fechaISO,
    };

    try {
      await dyn.update(
        idMatricula: idMatricula,
        idCategoria: idCategoria,
        ciclo: ciclo,
        fechaISO: fechaISO,
      );
      return;
    } catch (_) {}
    try {
      await dyn.actualizar(idMatricula, dataSnake);
      return;
    } catch (_) {}
    try {
      await dyn.patch(idMatricula, dataSnake);
      return;
    } catch (_) {}
    try {
      await dyn.update(idMatricula, dataSnake);
      return;
    } catch (_) {}
    try {
      await dyn.actualizar({'id_matricula': idMatricula, ...dataSnake});
      return;
    } catch (_) {}
    try {
      await dyn.actualizar({'idMatricula': idMatricula, ...dataCamel});
      return;
    } catch (_) {}
    try {
      final payload = Map<String, dynamic>.from(dataSnake);
      payload['id_matricula'] = idMatricula;
      await dyn.update(payload);
      return;
    } catch (_) {}

    throw 'Tu MatriculasRepository no expone un método de actualización compatible.';
  }

  Future<void> _createMatriculaFlexible({
    required int idEstudiante,
    required int idCategoria,
    String? ciclo,
    String? fechaISO, // yyyy-MM-dd
  }) async {
    final dyn = _mat as dynamic;
    try {
      await dyn.crear(
        idEstudiante: idEstudiante,
        idCategoria: idCategoria,
        ciclo: ciclo,
        fechaISO: fechaISO,
      );
      return;
    } catch (_) {}
    try {
      await dyn.crear(
        id_estudiante: idEstudiante,
        id_categoria: idCategoria,
        ciclo: ciclo,
        fecha_matricula: fechaISO,
      );
      return;
    } catch (_) {}
    final bodySnake = {
      'id_estudiante': idEstudiante,
      'id_categoria': idCategoria,
      if (ciclo != null && ciclo.isNotEmpty) 'ciclo': ciclo,
      if (fechaISO != null) 'fecha_matricula': fechaISO,
    };
    final bodyCamel = {
      'idEstudiante': idEstudiante,
      'idCategoria': idCategoria,
      if (ciclo != null && ciclo.isNotEmpty) 'ciclo': ciclo,
      if (fechaISO != null) 'fechaMatricula': fechaISO,
    };
    try {
      await dyn.crear(bodySnake);
      return;
    } catch (_) {}
    try {
      await dyn.crear(bodyCamel);
      return;
    } catch (_) {}

    throw 'Tu MatriculasRepository no expone un método de creación compatible.';
  }

  // ======== EXPORT: helpers guardar (Genérico) ========
  Future<String?> _pickSavePath({
    required String suggestedName,
    required List<String> extensions,
    String? label,
    List<String>? mimeTypes,
  }) async {
    if (kIsWeb) return suggestedName;
    final location = await getSaveLocation(
      acceptedTypeGroups: [
        XTypeGroup(
          label: label ?? 'Archivo',
          extensions: extensions,
          mimeTypes: mimeTypes,
        ),
      ],
      suggestedName: suggestedName,
    );
    return location?.path;
  }

  Future<void> _saveBytes(
    Uint8List bytes, {
    required String defaultFileName,
    required List<String> extensions,
    String? mimeType,
  }) async {
    try {
      if (kIsWeb) {
        final xf = XFile.fromData(
          bytes,
          name: defaultFileName,
          mimeType: mimeType,
        );
        await xf.saveTo(defaultFileName);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Descarga iniciada: $defaultFileName')),
        );
        return;
      }

      final path = await _pickSavePath(
        suggestedName: defaultFileName,
        extensions: extensions,
        mimeTypes: mimeType == null ? null : [mimeType],
      );

      if (path == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardado cancelado')),
        );
        return;
      }

      final xf = XFile.fromData(
        bytes,
        name: defaultFileName,
        mimeType: mimeType,
      );
      await xf.saveTo(path);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Archivo guardado en: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $e')),
      );
    }
  }

  // =======================================================================
  // ===== INICIO: MÉTODO _buildInfoPdfBytes (CORREGIDO) =====
  // =======================================================================

  Future<Uint8List> _buildInfoPdfBytes() async {
    final doc = pw.Document();

    // --- Cargar fuentes desde assets ---
    final robotoData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final robotoFont = pw.Font.ttf(robotoData);
    final materialData =
        await rootBundle.load('assets/fonts/MaterialIcons-Regular.ttf');
    final materialFont = pw.Font.ttf(materialData);

    final nombre = '${_fmt(_info?['nombres'])} ${_fmt(_info?['apellidos'])}'
        .trim();
    final titulo = nombre.isEmpty ? 'Estudiante ${widget.id}' : nombre;

    // Colores profesionales
    const baseColor = PdfColors.blueGrey800;
    const accentColor = PdfColors.blueGrey100;
    const lightColor = PdfColors.grey100;

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
          orientation: pw.PageOrientation.portrait,
          theme: pw.ThemeData.withFont(base: robotoFont),
        ),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'FICHA DE ESTUDIANTE',
                  style: pw.TextStyle(
                    color: baseColor,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  titulo,
                  style: const pw.TextStyle(
                    color: PdfColors.grey700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            pw.Divider(color: PdfColors.grey400, height: 8),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generado el: ${_fmtDate(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
        build: (context) => [
          _buildSectionHeader(
            'Datos Personales',
            Icons.person,
            baseColor,
            materialFont,
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              children: [
                _buildInfoRow(
                  Icons.badge,
                  'Nombre:',
                  '${_fmt(_info?['nombres'])} ${_fmt(_info?['apellidos'])}',
                  materialFont,
                ),
                _buildInfoRow(
                  Icons.cake,
                  'Nacimiento:',
                  _fmtDate(_info?['fechaNacimiento'] ??
                      _info?['fecha_nacimiento']),
                  materialFont,
                ),
                _buildInfoRow(
                  Icons.phone,
                  'Teléfono:',
                  _fmt(_info?['telefono']),
                  materialFont,
                ),
                _buildInfoRow(
                  Icons.home,
                  'Dirección:',
                  _fmt(_info?['direccion']),
                  materialFont,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          _buildSectionHeader(
            'Inscripción',
            Icons.assignment_turned_in,
            baseColor,
            materialFont,
          ),
          pw.SizedBox(height: 6),
          if (_matricula == null)
            pw.Text('Sin inscripción registrada.',
                style: const pw.TextStyle(fontSize: 10))
          else
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip(
                  'Categoría',
                  _categoriaLabel(_matricula),
                  Icons.category,
                  accentColor,
                  materialFont,
                ),
                _buildChip(
                  'Ciclo',
                  _fmt(_matricula?['ciclo']),
                  Icons.repeat,
                  accentColor,
                  materialFont,
                ),
                _buildChip(
                  'Fecha',
                  _fmtDate(_matricula?['fecha'] ?? _matricula?['fecha_matricula']),
                  Icons.event,
                  accentColor,
                  materialFont,
                ),
                _buildChip(
                  _matricula?['activo'] == true ? 'Activa' : 'Inactiva',
                  '',
                  _matricula?['activo'] == true
                      ? Icons.check_circle
                      : Icons.cancel,
                  _matricula?['activo'] == true
                      ? PdfColors.green100
                      : PdfColors.red100,
                  materialFont,
                ),
              ],
            ),
          pw.SizedBox(height: 16),
          _buildSectionHeader(
            'Subcategorías Asignadas',
            Icons.legend_toggle_outlined,
            baseColor,
            materialFont,
          ),
          pw.SizedBox(height: 6),
          if (_asignaciones.isEmpty)
            pw.Text('Sin subcategorías asignadas.',
                style: const pw.TextStyle(fontSize: 10))
          else
            pw.Table.fromTextArray(
              headers: ['Subcategoría', 'Categoría', 'Unión'],
              data: _asignaciones
                  .map((r) => [
                        _fmt(r['subcategoria']),
                        _fmt(r['categoria']),
                        _fmtDate(r['fechaUnion']),
                      ])
                  .toList(),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(color: baseColor),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
              },
              oddRowDecoration: const pw.BoxDecoration(color: lightColor),
            ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _buildSectionHeader(
    String title,
    IconData icon,
    PdfColor color,
    pw.Font materialFont,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: const pw.BorderRadius.only(
          topLeft: pw.Radius.circular(4),
          topRight: pw.Radius.circular(4),
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Icon(
            pw.IconData(icon.codePoint),
            font: materialFont,
            color: PdfColors.white,
            size: 16,
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    pw.Font materialFont,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Icon(
            pw.IconData(icon.codePoint),
            font: materialFont,
            color: PdfColors.grey600,
            size: 16,
          ),
          pw.SizedBox(width: 12),
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildChip(
    String label,
    String? value,
    IconData icon,
    PdfColor color,
    pw.Font materialFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Icon(
            pw.IconData(icon.codePoint),
            font: materialFont,
            size: 12,
            color: PdfColors.black,
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            value == null || value.isEmpty ? label : '$label: ${value.trim()}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
          ),
        ],
      ),
    );
  }

  Future<void> _exportInfoPdf() async {
    final bytes = await _buildInfoPdfBytes();
    await _saveBytes(
      bytes,
      defaultFileName: 'estudiante_${widget.id}_info.pdf',
      extensions: const ['pdf'],
      mimeType: 'application/pdf',
    );
  }

  // ======== Helper para getters opcionales ========
  T? _maybe<T>(T Function() fn) {
    try {
      return fn();
    } catch (_) {
      return null;
    }
  }

  // ======== COMIENZA CÓDIGO DE PAGOS ========

  Future<dynamic> _safeGet(String url) async {
    final res = await _http.get(url, headers: const {});
    return res;
  }

  Future<dynamic> _safePost(String url, Map<String, dynamic> body) async {
    final res = await _http.post(url, body: body, headers: const {});
    return res;
  }

  List<Map<String, dynamic>> _coerceList(dynamic res) {
    if (res is List) {
      return List<Map<String, dynamic>>.from(
        res.map((e) => Map<String, dynamic>.from(e as Map)),
      );
    }
    if (res is Map) {
      if (res['data'] is List) {
        return List<Map<String, dynamic>>.from(
          (res['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
        );
      }
      if (res['items'] is List) {
        return List<Map<String, dynamic>>.from(
          (res['items'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );
      }
      if (res['rows'] is List) {
        return List<Map<String, dynamic>>.from(
          (res['rows'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
        );
      }
    }
    return const [];
  }

  // ===== Mensualidades =====
  Future<void> _cargarMensualidades() async {
    if (_blocked) return;
    setState(() {
      _loadingMens = true;
      _pagosError = null;
    });

    try {
      final idEst = widget.id;
      dynamic list;

      try {
        list = await _mensRepo.porEstudiante(idEst);
      } catch (_) {}
      list ??= await (() async {
        try {
          return await _mensRepo.listar(estudianteId: idEst);
        } catch (_) {}
        return null;
      })();
      list ??= await (() async {
        try {
          return await _mensRepo.listarPorEstudiante(idEst);
        } catch (_) {}
        return null;
      })();

      if (list == null) {
        final base = Endpoints.mensualidades;
        final urls = [
          '$base?id_estudiante=$idEst',
          '$base?estudianteId=$idEst',
          '$base/estudiante/$idEst',
          '$base/por-estudiante/$idEst',
        ];
        for (final u in urls) {
          final res = _coerceList(await _safeGet(u));
          if (res.isNotEmpty) {
            list = res;
            break;
          }
        }
      }

      List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(
        (list ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
      );

      for (final m in data) {
        m['id'] = m['id'] ?? m['id_mensualidad'] ?? m['mensualidad_id'];
        m['estado'] = (m['estado'] ?? 'pendiente').toString();
        m['valor'] = _asDouble(m['valor']);
        m['mes'] = m['mes'] ?? m['month'];
        m['anio'] = m['anio'] ?? m['year'];
      }

      if (_estado != 'Todos') {
        data = data.where((m) => (m['estado'] ?? '') == _estado).toList();
      }
      if (_anioFiltro != null) {
        data = data.where((m) => m['anio'] == _anioFiltro).toList();
      }
      if (_soloPendiente) {
        data = data.where((m) => (m['estado'] ?? '') != 'pagado').toList();
      }

      if (!mounted) return;
      setState(() => _mensualidades = data);

      await _recalcularTotales();
    } catch (e) {
      if (mounted) {
        setState(() => _pagosError = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingMens = false);
    }
  }

  Future<void> _recalcularTotales() async {
    if (_mensualidades.isEmpty || _blocked) {
      if (!mounted) return;
      setState(() {
        _totValor = _totPagado = _totPendiente = 0;
      });
      return;
    }

    try {
      final futures = _mensualidades.map((m) => _cargarResumen(m['id'] as int));
      final res = await Future.wait(futures);
      double v = 0, p = 0, pe = 0;
      for (var i = 0; i < res.length; i++) {
        final r = res[i];
        final local = _mensualidades[i];
        final valor = _asDouble(r?['valor'] ?? local['valor']);
        final pagado = _asDouble(r?['pagado'] ?? 0);
        final pendiente = _asDouble(r?['pendiente'] ?? (valor - pagado));
        v += valor;
        p += pagado;
        pe += pendiente;
      }
      if (!mounted) return;
      setState(() {
        _totValor = v;
        _totPagado = p;
        _totPendiente = pe;
      });
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _cargarResumen(int idM) async {
    if (_blocked) return null;
    if (_resumenCache.containsKey(idM)) return _resumenCache[idM];
    final r = await _pagosRepo.resumen(idM);
    if (r != null) _resumenCache[idM] = r;
    return r;
  }

  Future<List<Map<String, dynamic>>> _cargarPagos(int idM) async {
    if (_blocked) return const [];
    if (_pagosCache.containsKey(idM)) return _pagosCache[idM]!;
    final list = await _pagosRepo.porMensualidad(idM);
    _pagosCache[idM] = list;
    return list;
  }

  Future<void> _registrarPago(Map<String, dynamic> m) async {
    if (_blocked) {
      _showLoginSnack();
      return;
    }
    final resumen = await _cargarResumen(m['id'] as int);
    final restante = _asDouble(resumen?['pendiente'] ?? m['valor']);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _PagoDialog(
        pagosRepo: _pagosRepo,
        idMensualidad: m['id'] as int,
        restante: restante,
      ),
    );

    if (ok == true) {
      _resumenCache.remove(m['id']);
      _pagosCache.remove(m['id']);
      await _cargarMensualidades();
    }
  }

  Future<void> _editarPago(
    Map<String, dynamic> mensualidad,
    Map<String, dynamic> pago,
  ) async {
    if (_blocked) {
      _showLoginSnack();
      return;
    }
    final resumen = await _cargarResumen(mensualidad['id'] as int);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _PagoDialog(
        pagosRepo: _pagosRepo,
        idMensualidad: mensualidad['id'] as int,
        restante: _asDouble(resumen?['pendiente'] ?? mensualidad['valor']),
        pagoExistente: pago,
      ),
    );
    if (ok == true) {
      _resumenCache.remove(mensualidad['id']);
      _pagosCache.remove(mensualidad['id']);
      await _cargarMensualidades();
    }
  }

  Future<void> _anularPago(int idPago, int idMens) async {
    if (_blocked) {
      _showLoginSnack();
      return;
    }
    final motivoCtl = TextEditingController();

    final confirm = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Anular pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️ Esta acción no se puede deshacer'),
            const SizedBox(height: 12),
            TextField(
              controller: motivoCtl,
              decoration: const InputDecoration(
                labelText: 'Motivo *',
                border: OutlineInputBorder(),
                hintText: 'Ej: Pago duplicado, Error en el monto',
              ),
              maxLines: 2,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final motivo = motivoCtl.text.trim();
              if (motivo.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El motivo es obligatorio')),
                );
                return;
              }
              Navigator.pop(context, motivo);
            },
            child: const Text('Anular pago'),
          ),
        ],
      ),
    );

    if (confirm == null || confirm.isEmpty) return;

    try {
      final ok = await _pagosRepo.anular(idPago: idPago, motivo: confirm);

      if (ok) {
        _resumenCache.remove(idMens);
        _pagosCache.remove(idMens);
        await _cargarMensualidades();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Pago anulado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al anular: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ===== Acciones para generar mensualidades =====
  Future<void> _onTapGenerarHastaDiciembre() async {
    if (_blocked) {
      _showLoginSnack();
      return;
    }

    final anioSugerido = _anioFiltro ?? DateTime.now().year;

    final cfg = await showDialog<_GenMensConfig>(
      context: context,
      builder: (_) => _GenerarMensualidadesDialog(
        anioInicial: anioSugerido,
        fmtMoney: _fmtMoney,
        mesesYa: _mensualidades
            .where((m) => m['anio'] == anioSugerido)
            .map<int>((m) => (m['mes'] as num?)?.toInt() ?? 0)
            .where((m) => m >= 1 && m <= 12)
            .toSet(),
      ),
    );

    if (cfg == null) return;

    setState(() => _generandoMens = true);
    try {
      final idEst = widget.id;

      List<Map<String, dynamic>> mats = [];
      try {
        mats = await _matriculasRepo.porEstudiante(idEst);
      } catch (_) {}
      if (mats.isEmpty) {
        final base = Endpoints.matriculas;
        final urls = [
          '$base?estudianteId=$idEst',
          '$base/estudiante/$idEst',
          '$base/por-estudiante/$idEst',
        ];
        for (final u in urls) {
          final res = _coerceList(await _safeGet(u));
          if (res.isNotEmpty) {
            mats = res;
            break;
          }
        }
      }

      if (mats.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El estudiante no tiene matrícula.')),
        );
        return;
      }

      mats.sort((a, b) {
        final actA = (a['activo'] == true) ? 1 : 0;
        final actB = (b['activo'] == true) ? 1 : 0;
        final cmpAct = actB.compareTo(actA);
        if (cmpAct != 0) return cmpAct;

        DateTime parseDate(dynamic v) {
          if (v is DateTime) return v;
          if (v is String && v.isNotEmpty) {
            try {
              return DateTime.parse(v);
            } catch (_) {}
          }
          return DateTime.fromMillisecondsSinceEpoch(0);
        }

        final da = parseDate(a['fecha_matricula'] ?? a['creado_en']);
        final db = parseDate(b['fecha_matricula'] ?? b['creado_en']);
        return db.compareTo(da);
      });

      final int? idMatricula = (mats.first['id'] as num?)?.toInt() ??
          (mats.first['id_matricula'] as num?)?.toInt();

      if (idMatricula == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pude identificar la matrícula.')),
        );
        return;
      }

      final ahora = DateTime.now();
      final mesDesde = (cfg.anio == ahora.year) ? ahora.month : 1;
      final existentes = _mensualidades
          .where((m) => m['anio'] == cfg.anio)
          .map<int>((m) => (m['mes'] as num?)?.toInt() ?? 0)
          .toSet();

      final mesesObjetivo = <int>[];
      for (int m = mesDesde; m <= 12; m++) {
        if (!existentes.contains(m)) mesesObjetivo.add(m);
      }

      if (mesesObjetivo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay meses faltantes hasta diciembre.')),
        );
        return;
      }

      int creados = 0, fallidos = 0;
      for (final mes in mesesObjetivo) {
        try {
          bool ok = false;
          try {
            await _mensRepo.crear(
              idMatricula: idMatricula,
              mes: mes,
              anio: cfg.anio,
              valor: cfg.valorMensual,
              estado: 'pendiente',
            );
            ok = true;
          } catch (_) {
            final body = {
              'id_matricula': idMatricula,
              'mes': mes,
              'anio': cfg.anio,
              'valor': cfg.valorMensual,
              'estado': 'pendiente',
            };
            final base = Endpoints.mensualidades;
            final urls = <String>[base, '$base/crear'];
            for (final u in urls) {
              try {
                await _safePost(u, body);
                ok = true;
                break;
              } catch (_) {}
            }
          }
          if (ok) {
            creados++;
          } else {
            fallidos++;
          }
        } catch (_) {
          fallidos++;
        }
      }

      await _cargarMensualidades();

      final total = cfg.valorMensual * creados;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ Generadas $creados mensualidades ' +
                (fallidos > 0 ? '($fallidos fallidas) ' : '') +
                '· Total: ${_fmtMoney.format(total)}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _generandoMens = false);
    }
  }

  // ======== FIN CÓDIGO DE PAGOS ========

  // ======== INICIO LÓGICA DE EXPORTACIÓN (MANUAL) ========

  Future<List<Map<String, dynamic>>> _fetchPagosData() async {
    final dynScope = AppScope.of(context) as dynamic;

    final repos = <dynamic>[
      _maybe(() => dynScope.pagos),
      _maybe(() => dynScope.mensualidades),
      _maybe(() => dynScope.estadoMensualidad),
      _maybe(() => dynScope.pagosMensualidad),
      _maybe(() => dynScope.pagosMensualidades),
    ].whereType<dynamic>().toList();

    for (final repo in repos) {
      try {
        final r = await repo.porEstudiante(widget.id);
        return List<Map<String, dynamic>>.from(r);
      } catch (_) {}
      try {
        final r = await repo.por_estudiante(widget.id);
        return List<Map<String, dynamic>>.from(r);
      } catch (_) {}
      try {
        final r = await repo.listarPorEstudiante(widget.id);
        return List<Map<String, dynamic>>.from(r);
      } catch (_) {}
      try {
        final r = await repo.byEstudiante(widget.id);
        return List<Map<String, dynamic>>.from(r);
      } catch (_) {}
      try {
        final r = await repo.byStudent(widget.id);
        return List<Map<String, dynamic>>.from(r);
      } catch (_) {}
      try {
        final r = await repo.listByStudent(widget.id);
        return List<Map<String, dynamic>>.from(r);
      } catch (_) {}
      try {
        final r = await repo.estadoPorEstudiante(widget.id);
        return List<Map<String, dynamic>>.from(r);
      } catch (_) {}
    }
    return _mensualidades;
  }

  int? _extractYear(Map r) {
    final yearStr = _pickStr(r, [
      'anio',
      'año',
      'anio_pago',
      'ano',
      'year',
      'Year',
    ]);
    final y1 = int.tryParse(yearStr);
    if (y1 != null && y1 >= 1900 && y1 <= 2100) return y1;

    final f = _pickStr(r, [
      'fechaPago',
      'fecha_pago',
      'pagado_en',
      'fecha',
      'Fecha',
    ]);
    if (f.isNotEmpty) {
      try {
        return DateTime.parse(f).year;
      } catch (_) {}
    }
    return null;
  }

  List<Map<String, dynamic>> _rowsFilteredByOpenYears(List<Map<String, dynamic>> all) {
    if (_openYears.isEmpty) return all;
    return all.where((r) {
      final y = _extractYear(r);
      return y != null && _openYears.contains(y);
    }).toList();
  }

  xls.CellValue _cv(dynamic v) {
    if (v == null) return xls.TextCellValue('');
    if (v is bool) return xls.BoolCellValue(v);
    if (v is int) return xls.IntCellValue(v);
    if (v is double) return xls.DoubleCellValue(v);
    final s = '$v';
    final n = double.tryParse(s);
    return (n != null) ? xls.DoubleCellValue(n) : xls.TextCellValue(s);
  }

  String _pickStr(Map r, List<String> keys) {
    for (final k in keys) {
      final v = r[k];
      if (v != null && '$v'.isNotEmpty) return '$v';
    }
    return '';
  }

  Future<void> _exportPagosExcel() async {
    final allPagos = await _fetchPagosData();
    final rows = _rowsFilteredByOpenYears(allPagos);

    final book = xls.Excel.createExcel();
    final sheet = book['Pagos'];
    sheet.appendRow([
      xls.TextCellValue('Mes'),
      xls.TextCellValue('Año'),
      xls.TextCellValue('Estado'),
      xls.TextCellValue('Monto'),
      xls.TextCellValue('Fecha pago'),
      xls.TextCellValue('Observación'),
    ]);
    for (final r in rows) {
      final mes = _mesNombre(int.tryParse(_pickStr(r, ['mes', 'Mes'])));
      final anio = _pickStr(r, ['anio', 'año', 'anio_pago', 'ano', 'year']);
      final est = _pickStr(r, ['estado', 'status']);
      final monto = _pickStr(r, ['monto', 'valor', 'importe', 'total', 'pago']);
      final fpago = _fmtDate(_pickStr(r, ['fechaPago', 'fecha_pago', 'pagado_en', 'fecha']));
      final obs = _pickStr(r, ['observacion', 'observación', 'nota', 'comentario']);

      sheet.appendRow([_cv(mes), _cv(anio), _cv(est), _cv(monto), _cv(fpago), _cv(obs)]);
    }
    final encoded = book.encode()!;
    final bytes = Uint8List.fromList(encoded);
    await _saveBytes(
      bytes,
      defaultFileName: 'estudiante_${widget.id}_pagos.xlsx',
      extensions: const ['xlsx'],
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  Future<Uint8List> _buildPagosPdfBytes() async {
    final allPagos = await _fetchPagosData();
    final rows = _rowsFilteredByOpenYears(allPagos);

    final robotoData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final robotoFont = pw.Font.ttf(robotoData);
    final materialData = await rootBundle.load('assets/fonts/MaterialIcons-Regular.ttf');
    final materialFont = pw.Font.ttf(materialData);

    final doc = pw.Document();
    final nombre = '${_fmt(_info?['nombres'])} ${_fmt(_info?['apellidos'])}'.trim();
    final titulo = nombre.isEmpty ? 'Estudiante ${widget.id}' : nombre;

    const baseColor = PdfColors.blueGrey800;
    const lightColor = PdfColors.grey100;

    double totalFiltrado = 0.0;
    for (final r in rows) {
      final montoStr = _pickStr(r, ['monto', 'valor', 'importe', 'total', 'pago']);
      final estado = _pickStr(r, ['estado', 'status']).toLowerCase();
      if (estado != 'anulado') totalFiltrado += _asDouble(montoStr);
    }

    pw.Widget buildCell(
      String text, {
      pw.Alignment alignment = pw.Alignment.centerLeft,
      bool isHeader = false,
      PdfColor? background,
    }) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(6),
        color: background,
        alignment: alignment,
        child: pw.Text(
          text,
          style: isHeader
              ? pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10,
                )
              : const pw.TextStyle(fontSize: 10),
        ),
      );
    }

    final List<pw.TableRow> tableRows = [];

    tableRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: baseColor),
        children: [
          buildCell('Mes', isHeader: true, alignment: pw.Alignment.center),
          buildCell('Año', isHeader: true, alignment: pw.Alignment.center),
          buildCell('Estado', isHeader: true, alignment: pw.Alignment.center),
          buildCell('Monto', isHeader: true, alignment: pw.Alignment.centerRight),
          buildCell('Fecha pago', isHeader: true, alignment: pw.Alignment.center),
          buildCell('Observación', isHeader: true),
        ],
      ),
    );

    for (int i = 0; i < rows.length; i++) {
      final r = rows[i];
      final background = i % 2 == 0 ? lightColor : null;
      final estado = _pickStr(r, ['estado', 'status']).toLowerCase();
      final monto = _pickStr(r, ['monto', 'valor', 'importe', 'total', 'pago']);

      PdfColor statusColor;
      IconData statusIcon;
      switch (estado) {
        case 'pagado':
          statusColor = PdfColors.green100;
          statusIcon = Icons.check_circle;
          break;
        case 'anulado':
          statusColor = PdfColors.red100;
          statusIcon = Icons.cancel;
          break;
        default:
          statusColor = PdfColors.yellow100;
          statusIcon = Icons.pending;
      }

      tableRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: background),
          children: [
            buildCell(_mesNombre(int.tryParse(_pickStr(r, ['mes', 'Mes']))),
                alignment: pw.Alignment.center),
            buildCell(_pickStr(r, ['anio', 'año', 'anio_pago', 'ano', 'year']),
                alignment: pw.Alignment.center),
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              color: background,
              alignment: pw.Alignment.center,
              child: _buildChip(estado, '', statusIcon, statusColor, materialFont),
            ),
            buildCell(_fmtMoney.format(_asDouble(monto)),
                alignment: pw.Alignment.centerRight),
            buildCell(
              _fmtDate(_pickStr(r, ['fechaPago', 'fecha_pago', 'pagado_en', 'fecha'])),
              alignment: pw.Alignment.center,
            ),
            buildCell(_pickStr(r, ['observacion', 'observación', 'nota', 'comentario'])),
          ],
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(base: robotoFont),
        ),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'REPORTE DE PAGOS',
                  style: pw.TextStyle(
                    color: baseColor,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  titulo,
                  style: const pw.TextStyle(
                    color: PdfColors.grey700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            pw.Divider(color: PdfColors.grey400, height: 8),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generado el: ${_fmtDate(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
        build: (context) => [
          _buildSectionHeader('Pagos Filtrados', Icons.receipt_long, baseColor, materialFont),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.8),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(1.8),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1.8),
              5: const pw.FlexColumnWidth(3.0),
            },
            children: tableRows,
          ),
          pw.Divider(color: PdfColors.grey300, height: 24, thickness: 1.5),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 250,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'TOTAL (SEGÚN FILTRO)',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _fmtMoney.format(totalFiltrado),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 18,
                      color: baseColor,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    _openYears.isEmpty
                        ? 'Mostrando todos los registros.'
                        : 'Mostrando años: ${_openYears.join(', ')}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  Future<void> _exportPagosPdf() async {
    final bytes = await _buildPagosPdfBytes();
    await _saveBytes(
      bytes,
      defaultFileName: 'estudiante_${widget.id}_pagos.pdf',
      extensions: const ['pdf'],
      mimeType: 'application/pdf',
    );
  }

  // ---------- UI Principal ----------
  @override
  Widget build(BuildContext context) {
    final title = _info == null
        ? 'Estudiante'
        : '${_info!['nombres'] ?? ''} ${_info!['apellidos'] ?? ''}'.trim();

    if (!_authChecked) {
      return Scaffold(
        appBar: AppBar(title: Text(title.isEmpty ? 'Estudiante' : title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuth) {
      return Scaffold(
        appBar: AppBar(title: Text(title.isEmpty ? 'Estudiante' : title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 42),
                const SizedBox(height: 12),
                const Text(
                  'Debes iniciar sesión para acceder a los datos.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _goToLogin,
                  icon: const Icon(Icons.login),
                  label: const Text('Iniciar sesión'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title.isEmpty ? 'Estudiante' : title),
        bottom: _canViewPagos
            ? TabBar(
                controller: _tab,
                tabs: const [
                  Tab(text: 'Información'),
                  Tab(text: 'Pagos'),
                ],
              )
            : null,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Exportar',
            onSelected: (v) async {
              try {
                switch (v) {
                  case 'info.pdf':
                    await _exportInfoPdf();
                    break;
                  case 'pagos.xlsx':
                    await _exportPagosExcel();
                    break;
                  case 'pagos.pdf':
                    await _exportPagosPdf();
                    break;
                  case 'preview.info':
                    final b = await _buildInfoPdfBytes();
                    await Printing.layoutPdf(onLayout: (_) async => b);
                    break;
                  case 'preview.pagos':
                    final b = await _buildPagosPdfBytes();
                    await Printing.layoutPdf(onLayout: (_) async => b);
                    break;
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al exportar: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'info.pdf',
                enabled: _info != null,
                child: const ListTile(
                  leading: Icon(Icons.picture_as_pdf),
                  title: Text('Exportar información (PDF)'),
                ),
              ),
              if (_canViewPagos) ...[
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'pagos.xlsx',
                  child: const ListTile(
                    leading: Icon(Icons.grid_on),
                    title: Text('Exportar pagos (Excel)'),
                    subtitle: Text('Usa solo los años abiertos'),
                  ),
                ),
                PopupMenuItem(
                  value: 'pagos.pdf',
                  child: const ListTile(
                    leading: Icon(Icons.picture_as_pdf),
                    title: Text('Exportar pagos (PDF)'),
                    subtitle: Text('Usa solo los años abiertos'),
                  ),
                ),
              ],
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'preview.info',
                child: const ListTile(
                  leading: Icon(Icons.print),
                  title: Text('Vista previa Info'),
                ),
              ),
              if (_canViewPagos)
                PopupMenuItem(
                  value: 'preview.pagos',
                  child: const ListTile(
                    leading: Icon(Icons.print),
                    title: Text('Vista previa Pagos'),
                  ),
                ),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(Icons.download),
            ),
          ),
          IconButton(
            tooltip: 'Refrescar',
            onPressed: _loading ? null : _loadAll,
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? Center(child: Text(_error!))
              : (_canViewPagos
                  ? TabBarView(
                      controller: _tab,
                      children: [_tabInformacion(), _buildMensPane()],
                    )
                  : _tabInformacion()),
    );
  }

  // ---------- UI Tab Información ----------
  Widget _tabInformacion() {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    Widget _dataRow(String label, String value, IconData icon) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: cs.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: txt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  Text(
                    value,
                    style: txt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    Icons.person,
                    size: 150,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      Hero(
                        tag: 'avatar_${widget.id}',
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child: Text(
                            (_info?['nombres'] ?? 'E')[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 22,
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${_fmt(_info?['nombres'])} ${_fmt(_info?['apellidos'])}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Cédula: ${_fmt(_info?['cedula'] ?? _info?['id_doc'])}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DATOS DE CONTACTO',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _dataRow(
                    'Fecha de Nacimiento',
                    _fmtDate(_info?['fechaNacimiento'] ?? _info?['fecha_nacimiento']),
                    Icons.cake_rounded,
                  ),
                  _dataRow('Teléfono', _fmt(_info?['telefono']), Icons.phone_rounded),
                  _dataRow('Dirección', _fmt(_info?['direccion']), Icons.location_on_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'INSCRIPCIÓN ACTUAL',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (_matricula != null)
                        SizedBox(
                          height: 32,
                          child: FilledButton.tonalIcon(
                            onPressed: _editarInscripcionDialog,
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Editar'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 32,
                          child: FilledButton.icon(
                            onPressed: _crearInscripcionDialog,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Crear'),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_matricula == null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'No hay información de matrícula registrada.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _infoChip(Icons.category_outlined, 'Categoría',
                            _categoriaLabel(_matricula), Colors.blue),
                        _infoChip(Icons.repeat, 'Ciclo', _fmt(_matricula?['ciclo']), Colors.purple),
                        _infoChip(Icons.event_available, 'Fecha',
                            _fmtDate(_matricula?['fecha'] ?? _matricula?['fecha_matricula']), Colors.orange),
                        _statusChip(_matricula?['activo'] == true),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ASIGNACIONES DE ENTRENAMIENTO',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAsignacionUI(txt),
                  const Divider(height: 32),
                  if (_asignaciones.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'No está asignado a ninguna subcategoría.',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _asignaciones.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final r = _asignaciones[i];
                        final idSub = (r['idSubcategoria'] as num?)?.toInt();

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cs.outline.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.class_outlined,
                                    color: Colors.deepPurple.shade700, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_fmt(r['subcategoria']),
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(
                                      'Categoría: ${_fmt(r['categoria'])}',
                                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              if (idSub != null)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () async {
                                    try {
                                      await _asig.eliminar(
                                        idEstudiante: widget.id,
                                        idSubcategoria: idSub,
                                      );
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Asignación eliminada')),
                                      );
                                      await _loadAll();
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: color)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(bool active) {
    final color = active ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(active ? Icons.check_circle : Icons.cancel, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            active ? 'ACTIVA' : 'INACTIVA',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
          ),
        ],
      ),
    );
  }

  // ---------- UI Tab Pagos ----------
  Widget _buildMensPane() {
    if (_pagosError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error al cargar pagos: $_pagosError'),
        ),
      );
    }

    return Column(
      children: [
        Padding(padding: const EdgeInsets.all(12.0), child: _buildFilters()),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: _buildResumen(),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: _buildAccionesGeneracion(),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loadingMens
              ? const Center(child: CircularProgressIndicator())
              : _mensualidades.isEmpty
                  ? const Center(child: Text('Sin mensualidades'))
                  : Scrollbar(
                      controller: _rightScrollCtl,
                      child: _buildAgrupadoPorAnio(),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final anios =
        _mensualidades.map((m) => m['anio']).whereType<int>().toSet().toList()
          ..sort();

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String>(
            value: _estado,
            decoration: const InputDecoration(
              labelText: 'Estado',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: 'Todos', child: Text('Todos')),
              DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
              DropdownMenuItem(value: 'pagado', child: Text('Pagado')),
              DropdownMenuItem(value: 'anulado', child: Text('Anulado')),
            ],
            onChanged: (v) async {
              if (_blocked) {
                _showLoginSnack();
                return;
              }
              setState(() => _estado = v ?? 'Todos');
              await _cargarMensualidades();
            },
          ),
        ),
        SizedBox(
          width: 140,
          child: DropdownButtonFormField<int?>(
            value: _anioFiltro,
            decoration: const InputDecoration(
              labelText: 'Año',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
              ...anios.map((a) => DropdownMenuItem<int?>(value: a, child: Text('$a'))),
            ],
            onChanged: (v) async {
              if (_blocked) {
                _showLoginSnack();
                return;
              }
              setState(() => _anioFiltro = v);
              await _cargarMensualidades();
            },
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Solo pendientes'),
            Switch(
              value: _soloPendiente,
              onChanged: (v) async {
                if (_blocked) {
                  _showLoginSnack();
                  return;
                }
                setState(() => _soloPendiente = v);
                await _cargarMensualidades();
              },
            ),
          ],
        ),
        Tooltip(
          message: 'Limpiar filtros',
          child: IconButton(
            onPressed: () async {
              if (_blocked) {
                _showLoginSnack();
                return;
              }
              setState(() {
                _estado = 'Todos';
                _anioFiltro = null;
                _soloPendiente = false;
              });
              await _cargarMensualidades();
            },
            icon: const Icon(Icons.filter_alt_off),
          ),
        ),
      ],
    );
  }

  Widget _buildResumen() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          _chip('Total', _fmtMoney.format(_totValor), Icons.attach_money),
          _chip('Pagado', _fmtMoney.format(_totPagado), Icons.check_circle, Colors.green),
          _chip(
            'Pendiente',
            _fmtMoney.format(_totPendiente),
            Icons.pending,
            _totPendiente > 0 ? Colors.orange : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildAccionesGeneracion() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ElevatedButton.icon(
            onPressed: _generandoMens ? null : _onTapGenerarHastaDiciembre,
            icon: const Icon(Icons.calendar_month),
            label: _generandoMens ? const Text('Generando...') : const Text('Generar hasta diciembre'),
          ),
        ],
      ),
    );
  }

  Widget _buildAgrupadoPorAnio() {
    final porAnio = <int, List<Map<String, dynamic>>>{};
    for (final m in _mensualidades) {
      final a = (m['anio'] as num?)?.toInt() ?? 0;
      porAnio.putIfAbsent(a, () => []).add(m);
    }
    final anios = porAnio.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.separated(
      controller: _rightScrollCtl,
      padding: const EdgeInsets.all(12),
      itemCount: anios.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, idx) {
        final anio = anios[idx];
        final ms = porAnio[anio]!
          ..sort((a, b) => ((b['mes'] as int?) ?? 0).compareTo((a['mes'] as int?) ?? 0));

        final total = ms.fold<double>(0, (acc, e) => acc + _asDouble(e['valor']));
        final pagados = ms.where((e) => (e['estado'] ?? '') == 'pagado').length;

        return Card(
          child: ExpansionTile(
            title: Text('Año $anio', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$pagados/${ms.length} pagados · ${_fmtMoney.format(total)}'),
            initiallyExpanded: _openYears.contains(anio),
            onExpansionChanged: (v) => setState(() {
              if (v) {
                _openYears.add(anio);
              } else {
                _openYears.remove(anio);
              }
            }),
            children: ms.map((m) => _mensTile(m)).toList(),
          ),
        );
      },
    );
  }

  Widget _mensTile(Map<String, dynamic> m) {
    final cs = Theme.of(context).colorScheme;
    final estado = (m['estado'] ?? 'pendiente').toString();
    final valor = _asDouble(m['valor']);

    Color estadoColor;
    switch (estado) {
      case 'pagado':
        estadoColor = cs.primaryContainer;
        break;
      case 'anulado':
        estadoColor = cs.errorContainer;
        break;
      default:
        estadoColor = cs.secondaryContainer;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: estadoColor,
          child: Text('${m['mes'] ?? ''}'),
        ),
        title: Text(
          '${_mesNombre(m['mes'])} ${m['anio']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Valor: ${_fmtMoney.format(valor)}'),
        trailing: Chip(
          label: Text(estado.toUpperCase()),
          backgroundColor: estadoColor,
        ),
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _cargarResumen(m['id'] as int),
            builder: (context, snapR) {
              final r = snapR.data;
              final valorR = _asDouble(r?['valor'] ?? valor);
              final pagado = _asDouble(r?['pagado'] ?? 0);
              final pendiente = _asDouble(r?['pendiente'] ?? (valorR - pagado));

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _chip('Valor', _fmtMoney.format(valorR), Icons.attach_money),
                        _chip('Pagado', _fmtMoney.format(pagado), Icons.check_circle, Colors.green),
                        _chip(
                          'Pendiente',
                          _fmtMoney.format(pendiente),
                          Icons.pending,
                          pendiente > 0 ? Colors.orange : Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: pendiente > 0 ? () => _registrarPago(m) : null,
                          icon: const Icon(Icons.add),
                          label: const Text('Registrar pago'),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Refrescar',
                          onPressed: () async {
                            if (_blocked) {
                              _showLoginSnack();
                              return;
                            }
                            _resumenCache.remove(m['id']);
                            _pagosCache.remove(m['id']);
                            setState(() {});
                          },
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text('Historial de pagos', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _cargarPagos(m['id'] as int),
                      builder: (context, snapP) {
                        final pagos = snapP.data ?? [];
                        if (snapP.connectionState == ConnectionState.waiting) {
                          return const LinearProgressIndicator();
                        }
                        if (pagos.isEmpty) {
                          return const Text('Sin pagos registrados');
                        }
                        return Column(
                          children: pagos.map((p) {
                            final activo = p['activo'] == true;
                            final monto = _asDouble(p['monto']);
                            return Card(
                              color: activo ? null : cs.errorContainer.withOpacity(0.25),
                              child: ListTile(
                                dense: true,
                                leading: Icon(
                                  activo ? Icons.check_circle : Icons.cancel,
                                  color: activo ? Colors.green : Colors.red,
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      _fmtMoney.format(monto),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        decoration: activo ? null : TextDecoration.lineThrough,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Chip(
                                      label: Text(p['metodo'] ?? ''),
                                      labelStyle: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Fecha: ${p['fecha'] ?? ''}'),
                                    if ((p['referencia'] ?? '').toString().isNotEmpty)
                                      Text('Ref: ${p['referencia']}'),
                                    if ((p['notas'] ?? '').toString().isNotEmpty)
                                      Text('Notas: ${p['notas']}'),
                                    if (!activo &&
                                        (p['motivoAnulacion'] ?? '').toString().isNotEmpty)
                                      Text(
                                        'Anulado: ${p['motivoAnulacion']}',
                                        style: TextStyle(
                                          color: cs.error,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (activo)
                                      IconButton(
                                        tooltip: 'Editar',
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _editarPago(m, p),
                                      ),
                                    if (activo)
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        tooltip: 'Anular',
                                        onPressed: () => _anularPago(p['id'] as int, m['id'] as int),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, IconData icon, [Color? color]) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ======== UI asignación ========
  Widget _buildAsignacionUI(TextTheme txt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<int>(
                value: _catForAssign,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categorias.map((c) {
                  final id = c['id_categoria'] ?? c['id'];
                  final nombre = c['nombre_categoria'] ?? c['nombre'] ?? '—';
                  return DropdownMenuItem<int>(
                    value: (id is int) ? id : int.tryParse('$id'),
                    child: Text('$nombre'),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    _catForAssign = v;
                    _subsDeCat = [];
                    _subToAssign = null;
                  });
                  if (v != null) _loadSubsForCat(v);
                },
              ),
            ),
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<int>(
                value: _subToAssign,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Subcategoría',
                  prefixIcon: Icon(Icons.label),
                ),
                items: _subsDeCat.map((s) {
                  final id = s['id_subcategoria'] ?? s['id'];
                  final nombre = s['nombre_subcategoria'] ?? s['nombre'] ?? '—';
                  return DropdownMenuItem<int>(
                    value: (id is int) ? id : int.tryParse('$id'),
                    child: Text('$nombre'),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _subToAssign = v),
              ),
            ),
            FilledButton.icon(
              onPressed: (_subToAssign == null)
                  ? null
                  : () async {
                      try {
                        await _asig.asignar(
                          idEstudiante: widget.id,
                          idSubcategoria: _subToAssign!,
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Subcategoría asignada')),
                        );
                        await _loadAll();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
              icon: const Icon(Icons.add),
              label: const Text('Asignar'),
            ),
          ],
        ),
      ],
    );
  }

  // ---------- Diálogos inscripción ----------
  Future<void> _editarInscripcionDialog() async {
    if (_matricula == null) return;

    final formKey = GlobalKey<FormState>();
    int? idCategoria = (_matricula?['idCategoria'] ?? _matricula?['id_categoria']) as int?;
    final cicloCtl = TextEditingController(text: _matricula?['ciclo']?.toString() ?? '');
    DateTime? fechaSel;

    String? fechaStr = (_matricula?['fecha'] ?? _matricula?['fecha_matricula'])?.toString();
    if (fechaStr != null && fechaStr.isNotEmpty) {
      try {
        fechaSel = DateTime.parse(fechaStr);
      } catch (_) {}
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar inscripción'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: idCategoria,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: _categorias.map((c) {
                    final id = c['id_categoria'] ?? c['id'];
                    final nombre = c['nombre_categoria'] ?? c['nombre'] ?? '—';
                    return DropdownMenuItem<int>(
                      value: (id is int) ? id : int.tryParse('$id'),
                      child: Text('$nombre'),
                    );
                  }).toList(),
                  validator: (v) => (v == null) ? 'Seleccione una categoría' : null,
                  onChanged: (v) => idCategoria = v,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: cicloCtl,
                  decoration: const InputDecoration(labelText: 'Ciclo'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Fecha:'),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        final initial = fechaSel ?? now;
                        final sel = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: DateTime(now.year - 5, 1, 1),
                          lastDate: DateTime(now.year + 1, 12, 31),
                        );
                        if (sel != null) setState(() => fechaSel = sel);
                      },
                      child: Text(
                        (fechaSel != null)
                            ? '${fechaSel!.year}-${fechaSel!.month.toString().padLeft(2, '0')}-${fechaSel!.day.toString().padLeft(2, '0')}'
                            : (_fmtDate(fechaStr)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) Navigator.pop(context, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final fechaISO = (fechaSel != null)
        ? '${fechaSel!.year}-${fechaSel!.month.toString().padLeft(2, '0')}-${fechaSel!.day.toString().padLeft(2, '0')}'
        : null;

    try {
      await _updateMatriculaFlexible(
        idMatricula: (_matricula!['id_matricula'] ?? _matricula!['id']) as int,
        idCategoria: idCategoria,
        ciclo: cicloCtl.text.trim().isEmpty ? null : cicloCtl.text.trim(),
        fechaISO: fechaISO,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inscripción actualizada')),
      );
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _crearInscripcionDialog() async {
    final formKey = GlobalKey<FormState>();
    int? idCategoria;
    final cicloCtl = TextEditingController();
    DateTime? fechaSel;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Crear inscripción'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: idCategoria,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: _categorias.map((c) {
                    final id = c['id_categoria'] ?? c['id'];
                    final nombre = c['nombre_categoria'] ?? c['nombre'] ?? '—';
                    return DropdownMenuItem<int>(
                      value: (id is int) ? id : int.tryParse('$id'),
                      child: Text('$nombre'),
                    );
                  }).toList(),
                  validator: (v) => (v == null) ? 'Seleccione una categoría' : null,
                  onChanged: (v) => idCategoria = v,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: cicloCtl,
                  decoration: const InputDecoration(labelText: 'Ciclo'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Fecha:'),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        final sel = await showDatePicker(
                          context: context,
                          initialDate: fechaSel ?? now,
                          firstDate: DateTime(now.year - 5, 1, 1),
                          lastDate: DateTime(now.year + 1, 12, 31),
                        );
                        if (sel != null) setState(() => fechaSel = sel);
                      },
                      child: Text(
                        (fechaSel != null)
                            ? '${fechaSel!.year}-${fechaSel!.month.toString().padLeft(2, '0')}-${fechaSel!.day.toString().padLeft(2, '0')}'
                            : 'Seleccionar',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) Navigator.pop(context, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final fechaISO = (fechaSel != null)
        ? '${fechaSel!.year}-${fechaSel!.month.toString().padLeft(2, '0')}-${fechaSel!.day.toString().padLeft(2, '0')}'
        : null;

    try {
      await _createMatriculaFlexible(
        idEstudiante: widget.id,
        idCategoria: idCategoria!,
        ciclo: cicloCtl.text.trim().isEmpty ? null : cicloCtl.text.trim(),
        fechaISO: fechaISO,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inscripción creada')),
      );
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

// ===== Diálogo para crear/editar pago =====
class _PagoDialog extends StatefulWidget {
  final PagosRepository pagosRepo;
  final int idMensualidad;
  final double restante;
  final Map<String, dynamic>? pagoExistente;

  const _PagoDialog({
    required this.pagosRepo,
    required this.idMensualidad,
    required this.restante,
    this.pagoExistente,
  });

  @override
  State<_PagoDialog> createState() => _PagoDialogState();
}

class _PagoDialogState extends State<_PagoDialog> {
  final _montoCtl = TextEditingController();
  DateTime _fecha = DateTime.now();
  String _metodo = 'efectivo';
  String? _referencia;
  String? _notas;

  bool _saving = false;
  String? _montoError;

  final _fmtInput = NumberFormat.simpleCurrency(
    locale: 'es_EC',
    name: '',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    if (widget.pagoExistente != null) {
      final p = widget.pagoExistente!;
      _montoCtl.text = _fmtInput.format(_asDouble(p['monto']));
      _fecha = DateTime.tryParse('${p['fecha']}') ?? DateTime.now();
      _metodo = (p['metodo'] ?? 'efectivo') as String;
      _referencia = p['referencia']?.toString();
      _notas = p['notas']?.toString();
    } else {
      _montoCtl.text = _fmtInput.format(widget.restante.clamp(0, double.infinity));
    }
  }

  double _parseMonto(String s) {
    s = s.trim();
    if (s.isEmpty) return 0.0;
    s = s
        .replaceAll(' ', '')
        .replaceAll('\$', '')
        .replaceAll('USD', '')
        .replaceAll('usd', '');
    if (s.contains(',') && s.contains('.')) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else if (s.contains(',')) {
      s = s.replaceAll(',', '.');
    }
    return double.tryParse(s) ?? 0.0;
  }

  void _validateMonto() {
    final monto = _parseMonto(_montoCtl.text);
    if (monto <= 0) {
      _montoError = 'Ingresa un monto válido';
    } else if (widget.pagoExistente == null && monto > widget.restante) {
      _montoError = 'Sobrepago. Máximo: ${_fmtInput.format(widget.restante)}';
    } else {
      _montoError = null;
    }
    setState(() {});
  }

  Future<void> _onSubmit() async {
    _validateMonto();
    if (_montoError != null) return;

    setState(() => _saving = true);
    try {
      final monto = _parseMonto(_montoCtl.text);
      if (widget.pagoExistente == null) {
        await widget.pagosRepo.crear(
          idMensualidad: widget.idMensualidad,
          monto: double.parse(monto.toStringAsFixed(2)),
          fecha: _fecha,
          metodoPago: _metodo,
          referencia: _referencia,
          notas: _notas,
        );
      } else {
        final idPago = widget.pagoExistente!['id'] as int;
        await widget.pagosRepo.actualizar(
          idPago: idPago,
          monto: double.parse(monto.toStringAsFixed(2)),
          fecha: _fecha,
          metodoPago: _metodo,
          referencia: _referencia,
          notas: _notas,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.pagoExistente != null;

    return AlertDialog(
      title: Text(isEdit ? 'Editar pago' : 'Registrar pago'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _montoCtl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Monto *',
                  helperText: isEdit
                      ? 'Edición de pago existente'
                      : 'Restante: ${_fmtInput.format(widget.restante)}',
                  errorText: _montoError,
                  prefixText: r'$ ',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => _validateMonto(),
              ),
              const SizedBox(height: 16),
              InputDatePickerFormField(
                firstDate: DateTime(2020, 1, 1),
                lastDate: DateTime(2100, 12, 31),
                initialDate: _fecha,
                fieldLabelText: 'Fecha de pago',
                onDateSubmitted: (d) => setState(() => _fecha = d),
                onDateSaved: (d) => setState(() => _fecha = d),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _metodo,
                decoration: const InputDecoration(
                  labelText: 'Método de pago *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                  DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
                  DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                ],
                onChanged: (v) => setState(() => _metodo = v ?? 'efectivo'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _referencia ?? '',
                decoration: const InputDecoration(
                  labelText: 'Referencia (opcional)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _referencia = v.trim().isEmpty ? null : v.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _notas ?? '',
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                onChanged: (v) => _notas = v.trim().isEmpty ? null : v.trim(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _onSubmit,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Guardar cambios' : 'Registrar'),
        ),
      ],
    );
  }
}

// ===== Diálogo para generar mensualidades =====
class _GenMensConfig {
  final int anio;
  final double valorMensual;
  _GenMensConfig({required this.anio, required this.valorMensual});
}

class _GenerarMensualidadesDialog extends StatefulWidget {
  final int anioInicial;
  final NumberFormat fmtMoney;
  final Set<int> mesesYa;
  const _GenerarMensualidadesDialog({
    required this.anioInicial,
    required this.fmtMoney,
    required this.mesesYa,
  });

  @override
  State<_GenerarMensualidadesDialog> createState() => _GenerarMensualidadesDialogState();
}

class _GenerarMensualidadesDialogState extends State<_GenerarMensualidadesDialog> {
  late int _anio;
  final _valorCtl = TextEditingController(text: '40.00'); // por defecto
  String? _error;

  @override
  void initState() {
    super.initState();
    _anio = widget.anioInicial;
  }

  int _mesActualSiCorresponde() {
    final hoy = DateTime.now();
    return (_anio == hoy.year) ? hoy.month : 1;
  }

  int _mesesACrear() {
    final desde = _mesActualSiCorresponde();
    int c = 0;
    for (int m = desde; m <= 12; m++) {
      if (!widget.mesesYa.contains(m)) c++;
    }
    return c;
  }

  double _toDouble(String s) {
    var t = s.trim().replaceAll(' ', '').replaceAll('\$', '');
    if (t.contains(',') && t.contains('.')) {
      t = t.replaceAll('.', '').replaceAll(',', '.');
    } else if (t.contains(',')) {
      t = t.replaceAll(',', '.');
    }
    return double.tryParse(t) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final desde = _mesActualSiCorresponde();
    final count = _mesesACrear();
    final valor = _toDouble(_valorCtl.text);
    final total = valor * count;

    return AlertDialog(
      title: const Text('Generar mensualidades (hasta diciembre)'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('Año:'),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _anio,
                  items: [
                    for (final y in [
                      DateTime.now().year - 1,
                      DateTime.now().year,
                      DateTime.now().year + 1,
                    ])
                      DropdownMenuItem(value: y, child: Text('$y')),
                  ],
                  onChanged: (v) => setState(() => _anio = v ?? _anio),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valorCtl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Valor mensual (USD) *',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                count == 0
                    ? 'No hay meses faltantes.'
                    : 'Se crearán $count mes(es): ${_mesNombre(desde)}–Diciembre\nTotal a generar: ${widget.fmtMoney.format(total)}',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            final v = _toDouble(_valorCtl.text);
            if (v <= 0) {
              setState(() => _error = 'Ingresa un valor válido (> 0)');
              return;
            }
            Navigator.pop(context, _GenMensConfig(anio: _anio, valorMensual: v));
          },
          child: const Text('Generar'),
        ),
      ],
    );
  }
}
