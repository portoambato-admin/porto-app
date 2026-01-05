import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Ajusta estas importaciones según la estructura real de tu proyecto
import 'package:app_porto/app/app_scope.dart';
import 'package:app_porto/core/services/session_token_provider.dart';
import '../data/pagos_repository.dart';
import '../../../core/constants/endpoints.dart';

// ======================= HELPERS GLOBALES =======================

double _asDouble(dynamic v) =>
    (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;

int _asInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

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

final _fmtMoney = NumberFormat.currency(locale: 'es_EC', symbol: r'$');

/// Helper para animaciones suaves en diálogos
Future<T?> showAnimatedDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, anim1, anim2) => builder(ctx),
    transitionBuilder: (ctx, anim1, anim2, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: child,
        ),
      );
    },
  );
}

// ======================= PANTALLA PRINCIPAL =======================

class AdminPagosScreen extends StatefulWidget {
  final bool embedded;
  const AdminPagosScreen({super.key, this.embedded = false});

  @override
  State<AdminPagosScreen> createState() => _AdminPagosScreenState();
}

class _AdminPagosScreenState extends State<AdminPagosScreen> {
  // --- Repos desde AppScope ---
  AppScope get _scope => AppScope.of(context);
  dynamic get _mensRepo => _scope.mensualidades;
  PagosRepository get _pagosRepo => _scope.pagos;
  dynamic get _estRepo => _scope.estudiantes;
  dynamic get _matriculasRepo => _scope.matriculas;

  // --- Estado Auth ---
  bool _authChecked = false;
  bool _isAuth = false;

  // --- Estado UI / Estudiantes ---
  final _qCtl = TextEditingController();
  final _leftScrollCtl = ScrollController();
  final _rightScrollCtl = ScrollController();
  Timer? _debounce;

  bool _loadingEsts = true;
  String? _errorEsts;

  List<Map<String, dynamic>> _estudiantes = [];
  Map<String, dynamic>? _estudiante;
  static const _MAX_FETCH = 1000;

  // --- Filtros Mensualidades ---
  String _estado = 'Todos'; // Todos | pendiente | pagado | anulado
  int? _anioFiltro;
  bool _soloPendiente = false;

  // --- Datos Mensualidades ---
  bool _loadingMens = false;
  List<Map<String, dynamic>> _mensualidades = []; // vista filtrada
  List<int> _aniosDisponibles = [];
  bool _generandoMens = false;

  // --- NUEVO: mensualidades sin filtros (para evitar duplicados al generar) ---
  List<Map<String, dynamic>> _mensualidadesAll = [];

  // --- Totales globales ---
  double _totValor = 0, _totPagado = 0, _totPendiente = 0;

  // --- Cache ---
  final Map<int, Map<String, dynamic>> _resumenCache = {};
  final Map<int, List<Map<String, dynamic>>> _pagosCache = {};

  // init seguro para InheritedWidgets
  bool _didInitDeps = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitDeps) return;
    _didInitDeps = true;
    _checkAuthAndLoad();
  }

  @override
  void dispose() {
    _qCtl.dispose();
    _leftScrollCtl.dispose();
    _rightScrollCtl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ======================= AUTH & HELPERS HTTP =======================

  Future<void> _checkAuthAndLoad() async {
    try {
      final t = await SessionTokenProvider.instance.readToken();

      if (!mounted) return;
      setState(() {
        _authChecked = true;
        _isAuth = (t != null && t.isNotEmpty);
      });

      if (_isAuth) {
        await _cargarEstudiantes();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _authChecked = true;
        _isAuth = false;
      });
    }
  }

  bool get _blocked => !_authChecked || !_isAuth;

  void _goToLogin() {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      Navigator.of(context).pushNamed('/login');
    }
  }

  Future<Map<String, String>> _buildAuthHeaders() async {
    final token = await SessionTokenProvider.instance.readToken();
    if (token != null && token.isNotEmpty) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }

  Future<dynamic> _safeGet(String url) async {
    final headers = await _buildAuthHeaders();
    final res = await _scope.http.get(url, headers: headers);
    return res;
  }

  Future<dynamic> _safePost(String url, Map<String, dynamic> body) async {
    final headers = await _buildAuthHeaders();
    final res = await _scope.http.post(
      url,
      body: body,
      headers: headers,
    );
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
          (res['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
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

  // ======================= ESTUDIANTES =======================

  String get _filtro => _qCtl.text.trim().toLowerCase();

  void _onSearchChanged(String v) {
    if (_blocked) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      if (!mounted || _blocked) return;
      final q = v.trim();
      if (q.isEmpty || q.length >= 2) {
        await _cargarEstudiantes(query: q);
      }
    });
  }

  Iterable<Map<String, dynamic>> _filtrarEstudiantesLocal() sync* {
    if (_filtro.isEmpty) {
      yield* _estudiantes;
      return;
    }
    for (final e in _estudiantes) {
      final nombre = (e['nombreCompleto'] ?? '').toString().toLowerCase();
      final id = '${e['id'] ?? ''}';
      final cedula = '${e['cedula'] ?? e['dni'] ?? e['documento'] ?? ''}';
      if (nombre.contains(_filtro) ||
          id.contains(_filtro) ||
          cedula.contains(_filtro)) {
        yield e;
      }
    }
  }

  Future<void> _cargarEstudiantes({String? query}) async {
    if (!mounted || _blocked) return;
    final q = (query ?? '').trim();
    final qLower = q.toLowerCase();

    setState(() {
      _loadingEsts = true;
      _errorEsts = null;
    });

    dynamic res;

    // ---------------------------------------------------------
    // CASO 1: LISTADO GENERAL (Sin búsqueda)
    // ---------------------------------------------------------
    if (q.isEmpty) {
      // Intentos con repositorio
      try {
        res = await _estRepo.paged(page: 1, pageSize: _MAX_FETCH);
      } catch (_) {}

      // Fallback HTTP
      if (res == null) {
        final base = Endpoints.estudiantes;
        final urls = [
          '$base/paged?page=1&limit=$_MAX_FETCH',
          '$base?limit=$_MAX_FETCH',
          '$base/listar',
          '$base/activos'
        ];
        for (final u in urls) {
          try {
            final r = await _safeGet(u);
            if (_coerceList(r).isNotEmpty) {
              res = r;
              break;
            }
          } catch (_) {}
        }
      }
    }
    // ---------------------------------------------------------
    // CASO 2: BÚSQUEDA (POR CÉDULA O NOMBRE)
    // ---------------------------------------------------------
    else {
      // 1) Repositorio
      try {
        res = await _estRepo.buscar(q);
      } catch (_) {}

      if (res == null) {
        try {
          res = await _estRepo.search(q);
        } catch (_) {}
      }

      // 2) Fallback HTTP por query (?q=...)
      if (res == null) {
        final base = Endpoints.estudiantes;
        final urls = [
          '$base/buscar?q=$q',
          '$base/search?q=$q',
          '$base?q=$q',
          '$base?filter=$q',
          '$base/paged?page=1&limit=$_MAX_FETCH&q=$q',
          '$base?cedula=$q',
          '$base?nombre=$q',
        ];

        for (final u in urls) {
          try {
            final r = await _safeGet(u);
            if (r is Map && r.containsKey('error')) continue;

            final list = _coerceList(r);
            if (list.isNotEmpty) {
              res = list;
              break;
            }
          } catch (_) {}
        }
      }
    }

    // ---------------------------------------------------------
    // PROCESAMIENTO Y FILTRADO FINAL
    // ---------------------------------------------------------
    try {
      List<Map<String, dynamic>> items = _coerceList(res);

      // fallback local si ya teníamos lista cargada
      if (items.isEmpty && q.isNotEmpty && _estudiantes.isNotEmpty) {
        items = List.from(_estudiantes);
      }

      final List<Map<String, dynamic>> procesados = [];

      for (final s in items) {
        final id =
            _asInt(s['id'] ?? s['id_estudiante'] ?? s['estudiante_id'], 0);
        if (id <= 0) continue;

        s['id'] = id;
        final n = (s['nombres'] ?? '').toString();
        final a = (s['apellidos'] ?? '').toString();
        s['nombreCompleto'] = s['nombreCompleto'] ?? ('$n $a').trim();

        final cedula =
            (s['cedula'] ?? s['dni'] ?? s['documento'] ?? '').toString();
        s['cedula'] = cedula;

        if (q.isNotEmpty) {
          final matchNombre =
              s['nombreCompleto'].toString().toLowerCase().contains(qLower);
          final matchCedula = cedula.toLowerCase().contains(qLower);

          if (!matchNombre && !matchCedula) {
            continue;
          }
        }

        procesados.add(s);
      }

      procesados.sort((a, b) => (a['nombreCompleto'] ?? '')
          .toString()
          .toLowerCase()
          .compareTo((b['nombreCompleto'] ?? '').toString().toLowerCase()));

      if (!mounted) return;
      setState(() {
        _estudiantes = procesados;
        _loadingEsts = false;
        _errorEsts = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorEsts = 'Error al procesar: $e';
        _loadingEsts = false;
      });
    }
  }

  Future<void> _seleccionarEst(Map<String, dynamic> est) async {
    if (_blocked) {
      _showLoginSnack();
      return;
    }
    setState(() {
      _estudiante = est;
      _estado = 'Todos';
      _anioFiltro = null;
      _soloPendiente = false;
      _mensualidades = [];
      _mensualidadesAll = [];
      _resumenCache.clear();
      _pagosCache.clear();
      _totValor = 0;
      _totPagado = 0;
      _totPendiente = 0;
    });
    await _cargarMensualidades();
  }

  void _showLoginSnack() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debes iniciar sesión para usar Finanzas.'),
      ),
    );
  }

  // ======================= MENSUALIDADES & TOTALES =======================

  Future<void> _cargarMensualidades() async {
    if (_estudiante == null || _blocked) return;
    setState(() => _loadingMens = true);

    try {
      final idEst = _asInt(_estudiante!['id'], 0);
      if (idEst <= 0) return;

      dynamic list;
      try {
        list = await _mensRepo.porEstudiante(idEst);
      } catch (_) {}

      // Fallback básico
      if (list == null) {
        final base = Endpoints.mensualidades;
        final res = await _safeGet('$base/por-estudiante/$idEst');
        list = _coerceList(res);
      }

      List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(
        (list ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
      );

      for (final m in data) {
        m['id'] =
            _asInt(m['id'] ?? m['id_mensualidad'] ?? m['mensualidad_id'], 0);
        m['estado'] = (m['estado'] ?? 'pendiente').toString();
        m['valor'] = _asDouble(m['valor']);
        m['mes'] = _asInt(m['mes'] ?? m['month'], 0);
        m['anio'] = _asInt(m['anio'] ?? m['year'], 0);
      }

      // --- Guardamos copia SIN FILTROS ---
      final all = List<Map<String, dynamic>>.from(
        data.map((e) => Map<String, dynamic>.from(e)),
      );

      // Años disponibles (desde ALL)
      final aniosSet =
          all.map((m) => _asInt(m['anio'], 0)).where((y) => y > 0).toSet();
      final aniosLista = aniosSet.toList()..sort();

      // --- Vista filtrada ---
      List<Map<String, dynamic>> view = List<Map<String, dynamic>>.from(all);

      if (_estado != 'Todos') {
        view = view.where((m) => (m['estado'] ?? '') == _estado).toList();
      }
      if (_anioFiltro != null) {
        view =
            view.where((m) => _asInt(m['anio'], 0) == _anioFiltro).toList();
      }
      if (_soloPendiente) {
        view = view.where((m) => (m['estado'] ?? '') != 'pagado').toList();
      }

      if (!mounted) return;
      setState(() {
        _mensualidadesAll = all; // sin filtros
        _mensualidades = view; // filtradas
        _aniosDisponibles = aniosLista;
      });

      await _recalcularTotales();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar mensualidades: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingMens = false);
    }
  }

  Future<void> _recalcularTotales() async {
    if (_mensualidades.isEmpty || _blocked) {
      if (!mounted) return;
      setState(() {
        _totValor = 0;
        _totPagado = 0;
        _totPendiente = 0;
      });
      return;
    }

    try {
      final futures =
          _mensualidades.map((m) => _cargarResumen(_asInt(m['id'], 0)));
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
    if (_blocked || idM <= 0) return null;
    if (_resumenCache.containsKey(idM)) return _resumenCache[idM];
    try {
      final r = await _pagosRepo.resumen(idM);
      if (r != null) _resumenCache[idM] = r;
      return r;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _cargarPagos(int idM) async {
    if (_blocked || idM <= 0) return [];
    if (_pagosCache.containsKey(idM)) return _pagosCache[idM]!;
    try {
      final l = await _pagosRepo.porMensualidad(idM);
      _pagosCache[idM] = l;
      return l;
    } catch (_) {
      return [];
    }
  }

  // ======================= ACCIONES PAGOS =======================

  Future<void> _registrarPago(Map<String, dynamic> m) async {
    if (_blocked) {
      _showLoginSnack();
      return;
    }

    final idMens = _asInt(m['id'], 0);
    if (idMens <= 0) return;

    final resumen = await _cargarResumen(idMens);
    final restante = _asDouble(resumen?['pendiente'] ?? m['valor']);

    final ok = await showAnimatedDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PagoDialog(
        pagosRepo: _pagosRepo,
        idMensualidad: idMens,
        restante: restante,
      ),
    );

    if (ok == true) {
      _resumenCache.remove(idMens);
      _pagosCache.remove(idMens);
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

    final idMens = _asInt(mensualidad['id'], 0);
    if (idMens <= 0) return;

    final resumen = await _cargarResumen(idMens);

    final ok = await showAnimatedDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PagoDialog(
        pagosRepo: _pagosRepo,
        idMensualidad: idMens,
        restante: _asDouble(resumen?['pendiente'] ?? mensualidad['valor']),
        pagoExistente: pago,
      ),
    );

    if (ok == true) {
      _resumenCache.remove(idMens);
      _pagosCache.remove(idMens);
      await _cargarMensualidades();
    }
  }

  Future<void> _anularPago(int idPago, int idMens) async {
    if (_blocked) {
      _showLoginSnack();
      return;
    }

    final confirm = await showAnimatedDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AnularDialog(),
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

  // ======================= GENERAR MENSUALIDADES =======================

  Future<void> _onTapRegistrarMensualidadesPorSubcategoria() async {
    if (_blocked) {
      _showLoginSnack();
      return;
    }

    final didCreate = await showAnimatedDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BulkMensualidadesSubcategoriaDialog(
        mensRepo: _mensRepo,
        fmtMoney: _fmtMoney,
      ),
    );

    if (didCreate == true && mounted) {
      if (_estudiante != null) {
        await _cargarMensualidades();
      }
    }
  }

  // NUEVO: mapa (anio -> set meses existentes) con lista SIN FILTROS
  Map<int, Set<int>> _buildMesesYaPorAnio(List<Map<String, dynamic>> items) {
    final map = <int, Set<int>>{};
    for (final m in items) {
      final y = _asInt(m['anio'], 0);
      final mes = _asInt(m['mes'], 0);
      if (y <= 0 || mes < 1 || mes > 12) continue;
      (map[y] ??= <int>{}).add(mes);
    }
    return map;
  }

  Future<void> _onTapGenerarHastaDiciembre() async {
    if (_blocked) {
      _showLoginSnack();
      return;
    }
    if (_estudiante == null) return;

    final anioSugerido = _anioFiltro ?? DateTime.now().year;

    final cfg = await showAnimatedDialog<_GenMensConfig>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GenerarMensualidadesDialog(
        anioInicial: anioSugerido,
        fmtMoney: _fmtMoney,
        mesesYaPorAnio: _buildMesesYaPorAnio(_mensualidadesAll), // clave
      ),
    );

    if (cfg == null) return;

    setState(() => _generandoMens = true);
    try {
      final idEst = _asInt(_estudiante!['id'], 0);
      if (idEst <= 0) return;

      List<Map<String, dynamic>> mats = [];
      try {
        mats = await _matriculasRepo.porEstudiante(idEst);
      } catch (_) {}

      if (mats.isEmpty) {
        final res =
            await _safeGet('${Endpoints.matriculas}/por-estudiante/$idEst');
        mats = _coerceList(res);
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
        return 0;
      });

      final int? idMatricula = (mats.first['id'] as num?)?.toInt() ??
          (mats.first['id_matricula'] as num?)?.toInt();

      if (idMatricula == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pude identificar la matrícula.')),
        );
        return;
      }

      // IMPORTANTE: existentes desde la lista SIN FILTROS
      final existentes = _mensualidadesAll
          .where((m) => _asInt(m['anio'], 0) == cfg.anio)
          .map<int>((m) => _asInt(m['mes'], 0))
          .where((m) => m >= 1 && m <= 12)
          .toSet();

      final mesesObjetivo = cfg.meses
          .where((m) => m >= 1 && m <= 12 && !existentes.contains(m))
          .toList()
        ..sort();

      if (mesesObjetivo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Los meses seleccionados ya tienen mensualidades generadas.'),
          ),
        );
        return;
      }

      final valorMensualRedondeado =
          double.parse(cfg.valorMensual.toStringAsFixed(2));

      int creados = 0, fallidos = 0;
      for (final mes in mesesObjetivo) {
        try {
          bool ok = false;
          try {
            await _mensRepo.crear(
              idMatricula: idMatricula,
              mes: mes,
              anio: cfg.anio,
              valor: valorMensualRedondeado,
              estado: 'pendiente',
            );
            ok = true;
          } catch (_) {
            final body = {
              'id_matricula': idMatricula,
              'mes': mes,
              'anio': cfg.anio,
              'valor': valorMensualRedondeado,
              'estado': 'pendiente',
            };
            await _safePost(Endpoints.mensualidades, body);
            ok = true;
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

      final total = valorMensualRedondeado * creados;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ Generadas $creados mensualidades '
            '${fallidos > 0 ? '($fallidos fallidas) ' : ''}'
            '· Total generado: ${_fmtMoney.format(total)}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _generandoMens = false);
    }
  }

  // ======================= UI: BUILD =======================

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    if (!_authChecked) {
      return Scaffold(
        appBar: widget.embedded ? null : AppBar(title: const Text('Gestión de Pagos')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuth) {
      return Scaffold(
        appBar: widget.embedded ? null : AppBar(title: const Text('Gestión de Pagos')),
        body: _buildLoginRequest(),
      );
    }

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text(
                'Gestión de Pagos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.surface,
              actions: [
                // ✅ Labels en web/desktop y sin el ícono de asignación.
                
                 

                // ✅ Refresh con label cuando hay espacio
                if (w >= 1100)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton.icon(
                      onPressed: () async {
                        if (_blocked) {
                          _showLoginSnack();
                          return;
                        }
                        await _cargarEstudiantes(query: _qCtl.text);
                        if (_estudiante != null) {
                          await _cargarMensualidades();
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refrescar'),
                    ),
                  )
                else
                  IconButton(
                    tooltip: 'Refrescar',
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      if (_blocked) {
                        _showLoginSnack();
                        return;
                      }
                      await _cargarEstudiantes(query: _qCtl.text);
                      if (_estudiante != null) {
                        await _cargarMensualidades();
                      }
                    },
                  ),
              ],
            ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          if (constraints.maxWidth > 900) {
            return Row(
              children: [
                SizedBox(width: 350, child: _buildStudentListPanel()),
                const VerticalDivider(width: 1),
                Expanded(child: _buildDetailPanel()),
              ],
            );
          } else {
            if (_estudiante == null) {
              return _buildStudentListPanel();
            }
            return PopScope(
              canPop: false,
              onPopInvoked: (didPop) {
                if (!didPop) {
                  setState(() => _estudiante = null);
                }
              },
              child: _buildDetailPanel(showBack: true),
            );
          }
        },
      ),
    );
  }

  Widget _buildLoginRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Debes iniciar sesión para acceder a Finanzas.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _goToLogin,
              icon: const Icon(Icons.login),
              label: const Text('Ir al Login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentListPanel() {
    final showHint = !_loadingEsts &&
        _estudiantes.isEmpty &&
        _qCtl.text.trim().isEmpty;
    final lista = _filtrarEstudiantesLocal().toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SizedBox(
            width: double.infinity,
            // ✅ Se quitó el ícono de asignación: ahora es botón con label (texto) sin icono
            child: FilledButton.tonal(
              onPressed:
                  _blocked ? null : _onTapRegistrarMensualidadesPorSubcategoria,
              child: const Text('Crear mensualidades subcategoría'),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Acción masiva: genera mensualidades para varios estudiantes dentro de una subcategoría.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: TextField(
            controller: _qCtl,
            onChanged: _onSearchChanged,
            onSubmitted: (v) {
              if (_blocked) return;
              _cargarEstudiantes(query: v);
            },
            decoration: InputDecoration(
              hintText: 'Buscar estudiante...',
              labelText: 'Buscar estudiante',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Refrescar listado',
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  if (_blocked) {
                    _showLoginSnack();
                    return;
                  }
                  _cargarEstudiantes(query: _qCtl.text);
                },
              ),
              filled: true,
              fillColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (_errorEsts != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_errorEsts!, style: const TextStyle(color: Colors.red)),
          ),
        if (showHint)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Escribe un nombre, cédula o ID.'),
          ),
        Expanded(
          child: _loadingEsts
              ? const Center(child: CircularProgressIndicator())
              : _estudiantes.isEmpty
                  ? const Center(child: Text('Sin estudiantes'))
                  : lista.isEmpty && _qCtl.text.isNotEmpty
                      ? const Center(child: Text('Sin resultados'))
                      : ListView.separated(
                          controller: _leftScrollCtl,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: lista.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final e = lista[i];
                            final selected = _estudiante != null &&
                                _estudiante!['id'] == e['id'];
                            final nombre = (e['nombreCompleto'] ?? '').toString();
                            final cedula =
                                e['cedula'] ?? e['dni'] ?? 'Sin documento';

                            return Card(
                              elevation: 0,
                              color: selected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: Theme.of(context).dividerColor),
                              ),
                              child: ListTile(
                                title: Text(
                                  nombre,
                                  style: TextStyle(
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text('C.I.: $cedula'),
                                leading: CircleAvatar(
                                  backgroundColor: selected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                  foregroundColor: selected
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                  child: Text(nombre.isNotEmpty ? nombre[0] : 'E'),
                                ),
                                onTap: () => _seleccionarEst(e),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildDetailPanel({bool showBack = false}) {
    if (_estudiante == null) {
      return const Center(child: Text('Selecciona un estudiante'));
    }

    final aniosSet = _aniosDisponibles.toSet();
    if (_anioFiltro != null) aniosSet.add(_anioFiltro!);
    final anios = aniosSet.toList()..sort();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              Row(
                children: [
                  if (showBack)
                    IconButton(
                      tooltip: 'Volver',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _estudiante = null),
                    ),
                  CircleAvatar(
                    radius: 24,
                    child: Text(
                      (_estudiante!['nombreCompleto'] ?? 'E')
                          .toString()
                          .substring(0, 1),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _estudiante!['nombreCompleto'] ?? 'Estudiante',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _estudiante!['cedula'] ?? 'Sin documento',
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // ✅ Se quitó el ícono de asignación: botón con label sin icono
                      
                      FilledButton.icon(
                        onPressed:
                            _generandoMens ? null : _onTapGenerarHastaDiciembre,
                        icon: _generandoMens
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.calendar_month),
                        label: const Text('Generar meses'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildKPI('Total', _totValor, Icons.monetization_on, Colors.blue),
                  const SizedBox(width: 12),
                  _buildKPI('Pagado', _totPagado, Icons.check_circle, Colors.green),
                  const SizedBox(width: 12),
                  _buildKPI(
                    'Pendiente',
                    _totPendiente,
                    Icons.warning,
                    _totPendiente > 0 ? Colors.orange : Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ✅ Labels para filtros (Estado / Año) usando DropdownButtonFormField
        Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    value: _estado,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                      isDense: true,
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
                const SizedBox(width: 12),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<int?>(
                    value: _anioFiltro,
                    decoration: const InputDecoration(
                      labelText: 'Año',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                      ...anios.map(
                        (a) => DropdownMenuItem<int?>(
                          value: a,
                          child: Text('$a'),
                        ),
                      ),
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
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('Solo pendientes'),
                  selected: _soloPendiente,
                  onSelected: (v) async {
                    if (_blocked) {
                      _showLoginSnack();
                      return;
                    }
                    setState(() => _soloPendiente = v);
                    await _cargarMensualidades();
                  },
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refrescar mensualidades',
                  onPressed: _cargarMensualidades,
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: _loadingMens
              ? const Center(child: CircularProgressIndicator())
              : _mensualidades.isEmpty
                  ? const Center(child: Text('Sin mensualidades'))
                  : ListView.builder(
                      controller: _rightScrollCtl,
                      padding: const EdgeInsets.all(12),
                      itemCount: _mensualidades.length,
                      itemBuilder: (ctx, i) =>
                          _buildMensualidadCard(_mensualidades[i]),
                    ),
        ),
      ],
    );
  }

  Widget _buildKPI(String label, double value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _fmtMoney.format(value),
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMensualidadCard(Map<String, dynamic> m) {
    final estado = (m['estado'] ?? 'pendiente').toString();
    final esPagado = estado == 'pagado';
    final esAnulado = estado == 'anulado';

    Color color;
    if (esPagado) {
      color = Colors.green;
    } else if (esAnulado) {
      color = Colors.red;
    } else {
      color = Colors.orange;
    }

    final valor = _asDouble(m['valor']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(esPagado ? Icons.check : Icons.attach_money, color: color),
        ),
        title: Text(
          '${_mesNombre(_asInt(m['mes'], 0))} ${_asInt(m['anio'], 0)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle:
            Text(esPagado ? 'Pagado' : 'Pendiente: ${_fmtMoney.format(valor)}'),
        trailing: Chip(
          label: Text(
            estado.toUpperCase(),
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 10),
          ),
          backgroundColor: color.withOpacity(0.1),
          side: BorderSide.none,
        ),
        children: [
          _buildDetallePagos(m),
        ],
      ),
    );
  }

  Widget _buildDetallePagos(Map<String, dynamic> m) {
    final idMens = _asInt(m['id'], 0);

    return FutureBuilder<Map<String, dynamic>?>(
      future: _cargarResumen(idMens),
      builder: (context, snapR) {
        final r = snapR.data;
        final valor = _asDouble(r?['valor'] ?? m['valor']);
        final pagado = _asDouble(r?['pagado'] ?? 0);
        final pendiente = _asDouble(r?['pendiente'] ?? (valor - pagado));
        final progress = valor > 0 ? (pagado / valor).clamp(0.0, 1.0) : 0.0;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (valor > 0) ...[
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.green,
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pagado: ${_fmtMoney.format(pagado)}'),
                    Text(
                      'Restante: ${_fmtMoney.format(pendiente)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(),
              ],
              Text('Historial de pagos',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _cargarPagos(idMens),
                builder: (context, snapP) {
                  if (snapP.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }
                  final pagos = snapP.data ?? [];
                  if (pagos.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Sin pagos registrados',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                    );
                  }
                  return Column(
                    children: pagos.map((p) {
                      final activo = p['activo'] == true;
                      final monto = _asDouble(p['monto']);
                      String fechaStr = (p['fecha'] ?? '').toString();
                      if (fechaStr.isNotEmpty) {
                        try {
                          final d = DateTime.parse(fechaStr);
                          fechaStr = DateFormat('dd/MM/yyyy HH:mm').format(d);
                        } catch (_) {}
                      }

                      final idPago = _asInt(p['id'], 0);

                      return Card(
                        color: activo
                            ? null
                            : Theme.of(context)
                                .colorScheme
                                .errorContainer
                                .withOpacity(0.25),
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
                                  decoration: activo
                                      ? null
                                      : TextDecoration.lineThrough,
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
                              if (fechaStr.isNotEmpty) Text('Fecha: $fechaStr'),
                              if ((p['referencia'] ?? '').toString().isNotEmpty)
                                Text('Ref: ${p['referencia']}'),
                              if ((p['notas'] ?? '').toString().isNotEmpty)
                                Text('Notas: ${p['notas']}'),
                              if (!activo &&
                                  (p['motivoAnulacion'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                Text(
                                  'Anulado: ${p['motivoAnulacion']}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
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
                                  onPressed: (idPago <= 0 || idMens <= 0)
                                      ? null
                                      : () => _anularPago(idPago, idMens),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 12),
              if (pendiente > 0.01)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _registrarPago(m),
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar pago'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ======================= DIÁLOGOS MODERNIZADOS =======================

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
  final _formKey = GlobalKey<FormState>();
  final _montoCtl = TextEditingController();
  final _fechaCtl = TextEditingController();
  final _refCtl = TextEditingController();
  final _notasCtl = TextEditingController();

  DateTime _fecha = DateTime.now();
  String _metodo = 'efectivo';
  bool _saving = false;

  final _fmtInput =
      NumberFormat.simpleCurrency(locale: 'es_EC', name: '', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    if (widget.pagoExistente != null) {
      final p = widget.pagoExistente!;
      _montoCtl.text = _fmtInput.format(double.tryParse('${p['monto']}') ?? 0.0);
      _fecha = DateTime.tryParse('${p['fecha']}') ?? DateTime.now();
      _metodo = (p['metodo'] ?? 'efectivo') as String;
      _refCtl.text = p['referencia']?.toString() ?? '';
      _notasCtl.text = p['notas']?.toString() ?? '';
    } else {
      _montoCtl.text =
          _fmtInput.format(widget.restante.clamp(0, double.infinity));
    }
    _fechaCtl.text = DateFormat('dd/MM/yyyy HH:mm').format(_fecha);
  }

  @override
  void dispose() {
    _montoCtl.dispose();
    _fechaCtl.dispose();
    _refCtl.dispose();
    _notasCtl.dispose();
    super.dispose();
  }

  double _parseMonto(String s) {
    s = s
        .trim()
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

  String? _validateMonto(String? _) {
    final monto = _parseMonto(_montoCtl.text);
    if (monto <= 0) return 'Ingresa un monto válido';
    if (widget.pagoExistente == null && monto > widget.restante + 0.0001) {
      return 'Sobrepago. Máximo: ${_fmtInput.format(widget.restante)}';
    }
    return null;
  }

  Future<void> _pickFechaHora() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Selecciona la fecha',
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fecha),
      helpText: 'Selecciona la hora',
    );

    final next = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime?.hour ?? now.hour,
      pickedTime?.minute ?? now.minute,
    );

    setState(() {
      _fecha = next;
      _fechaCtl.text = DateFormat('dd/MM/yyyy HH:mm').format(_fecha);
    });
  }

  Future<void> _onSubmit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _saving = true);
    try {
      final monto = _parseMonto(_montoCtl.text);
      final montoRedondeado = double.parse(monto.toStringAsFixed(2));

      final referencia =
          _refCtl.text.trim().isEmpty ? null : _refCtl.text.trim();
      final notas = _notasCtl.text.trim().isEmpty ? null : _notasCtl.text.trim();

      if (widget.pagoExistente == null) {
        await widget.pagosRepo.crear(
          idMensualidad: widget.idMensualidad,
          monto: montoRedondeado,
          fecha: _fecha,
          metodoPago: _metodo,
          referencia: referencia,
          notas: notas,
        );
      } else {
        final idPago = _asInt(widget.pagoExistente!['id'], 0);
        await widget.pagosRepo.actualizar(
          idPago: idPago,
          monto: montoRedondeado,
          fecha: _fecha,
          metodoPago: _metodo,
          referencia: referencia,
          notas: notas,
        );
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.pagoExistente != null;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(isEdit ? Icons.edit_note : Icons.add_card,
                      color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? 'Editar Pago' : 'Registrar Pago',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (!isEdit)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Saldo pendiente:'),
                            Text(
                              r'$' + _fmtInput.format(widget.restante),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _montoCtl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Monto *',
                              prefixText: '\$ ',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 16),
                            ),
                            validator: _validateMonto,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _metodo,
                            decoration: const InputDecoration(
                              labelText: 'Método',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 16),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'efectivo', child: Text('Efectivo')),
                              DropdownMenuItem(
                                  value: 'transferencia', child: Text('Transf.')),
                              DropdownMenuItem(
                                  value: 'tarjeta', child: Text('Tarjeta')),
                            ],
                            onChanged: (v) =>
                                setState(() => _metodo = v ?? 'efectivo'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fechaCtl,
                      readOnly: true,
                      onTap: _pickFechaHora,
                      decoration: const InputDecoration(
                        labelText: 'Fecha y Hora',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _refCtl,
                      decoration: const InputDecoration(
                        labelText: 'Referencia (Opcional)',
                        prefixIcon: Icon(Icons.tag),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notasCtl,
                      decoration: const InputDecoration(
                        labelText: 'Notas (Opcional)',
                        prefixIcon: Icon(Icons.notes),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _saving ? null : _onSubmit,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ))
                        : const Icon(Icons.save),
                    label: Text(_saving ? 'Guardando...' : 'Guardar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnularDialog extends StatefulWidget {
  const _AnularDialog();
  @override
  State<_AnularDialog> createState() => _AnularDialogState();
}

class _AnularDialogState extends State<_AnularDialog> {
  final _ctl = TextEditingController();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 10),
          Text('Anular pago'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              'Esta acción es irreversible. El pago quedará registrado como anulado.'),
          const SizedBox(height: 16),
          TextField(
            controller: _ctl,
            decoration: const InputDecoration(
              labelText: 'Motivo de anulación *',
              border: OutlineInputBorder(),
              hintText: 'Ej: Error de digitación',
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            if (_ctl.text.trim().isEmpty) return;
            Navigator.pop(context, _ctl.text.trim());
          },
          child: const Text('Confirmar Anulación'),
        ),
      ],
    );
  }
}

class _GenMensConfig {
  final int anio;
  final double valorMensual;
  final List<int> meses;

  _GenMensConfig({
    required this.anio,
    required this.valorMensual,
    required this.meses,
  });
}

// ======================= DIALOGO GENERAR MENSUALIDADES (CON AÑO) =======================

class _GenerarMensualidadesDialog extends StatefulWidget {
  final int anioInicial;
  final NumberFormat fmtMoney;

  // NUEVO: meses existentes por año
  final Map<int, Set<int>> mesesYaPorAnio;

  const _GenerarMensualidadesDialog({
    required this.anioInicial,
    required this.fmtMoney,
    required this.mesesYaPorAnio,
  });

  @override
  State<_GenerarMensualidadesDialog> createState() =>
      _GenerarMensualidadesDialogState();
}

class _GenerarMensualidadesDialogState extends State<_GenerarMensualidadesDialog> {
  late int _anio;
  final TextEditingController _valorCtl = TextEditingController(text: '40.00');
  late Set<int> _mesesSeleccionados;
  String? _error;

  @override
  void initState() {
    super.initState();
    _anio = widget.anioInicial;
    _mesesSeleccionados = _computeAllDisponibles();
  }

  @override
  void dispose() {
    _valorCtl.dispose();
    super.dispose();
  }

  Set<int> _mesesYaDelAnio(int anio) =>
      Set<int>.from(widget.mesesYaPorAnio[anio] ?? <int>{});

  int _mesActualSiCorresponde() {
    final hoy = DateTime.now();
    return (_anio == hoy.year) ? hoy.month : 1;
  }

  Set<int> _computeAllDisponibles() {
    final desde = _mesActualSiCorresponde();
    final ya = _mesesYaDelAnio(_anio);

    final next = <int>{};
    for (int m = desde; m <= 12; m++) {
      if (!ya.contains(m)) next.add(m);
    }
    return next;
  }

  void _setAnio(int v) {
    setState(() {
      _anio = v;
      _error = null;
      _mesesSeleccionados = _computeAllDisponibles();
    });
  }

  double _getValor() {
    var t = _valorCtl.text.trim().replaceAll(' ', '').replaceAll('\$', '');
    if (t.contains(',') && t.contains('.')) {
      t = t.replaceAll('.', '').replaceAll(',', '.');
    } else if (t.contains(',')) {
      t = t.replaceAll(',', '.');
    }
    return double.tryParse(t) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final years = <int>{
      DateTime.now().year - 1,
      DateTime.now().year,
      DateTime.now().year + 1,
      DateTime.now().year + 2,
      widget.anioInicial,
      ...widget.mesesYaPorAnio.keys,
    }.toList()
      ..sort();

    final count = _mesesSeleccionados.length;
    final total = _getValor() * count;

    final desde = _mesActualSiCorresponde();
    final yaDelAnio = _mesesYaDelAnio(_anio);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Generar Mensualidades',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<int>(
                      value: _anio,
                      items: years
                          .map((y) => DropdownMenuItem(
                                value: y,
                                child: Text('$y'),
                              ))
                          .toList(),
                      decoration: const InputDecoration(
                        labelText: 'Año',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) {
                        if (v == null) return;
                        _setAnio(v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _valorCtl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Valor mensual (USD)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Selecciona los meses:', style: theme.textTheme.titleMedium),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _mesesSeleccionados = _computeAllDisponibles();
                      });
                    },
                    child: const Text('Seleccionar posibles'),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(12, (index) {
                      final mes = index + 1;
                      final yaExiste = yaDelAnio.contains(mes);
                      final esPasado = mes < desde;
                      final habilitado = !yaExiste && !esPasado;
                      final seleccionado = _mesesSeleccionados.contains(mes);

                      return FilterChip(
                        label: Text(_mesNombre(mes).substring(0, 3)),
                        selected: seleccionado,
                        onSelected: habilitado
                            ? (v) {
                                setState(() {
                                  _error = null;
                                  if (v) {
                                    _mesesSeleccionados.add(mes);
                                  } else {
                                    _mesesSeleccionados.remove(mes);
                                  }
                                });
                              }
                            : null,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        selectedColor: theme.colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          fontWeight:
                              seleccionado ? FontWeight.bold : FontWeight.normal,
                        ),
                        avatar: yaExiste
                            ? const Icon(Icons.check_circle,
                                size: 16, color: Colors.grey)
                            : null,
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$count meses seleccionados'),
                    Text(
                      widget.fmtMoney.format(total),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child:
                      Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () {
                      final val = _getValor();
                      if (val <= 0) {
                        setState(() => _error = 'Ingresa un valor válido (> 0).');
                        return;
                      }
                      if (_mesesSeleccionados.isEmpty) {
                        setState(() => _error = 'Selecciona al menos un mes.');
                        return;
                      }

                      Navigator.pop(
                        context,
                        _GenMensConfig(
                          anio: _anio,
                          valorMensual: val,
                          meses: _mesesSeleccionados.toList()..sort(),
                        ),
                      );
                    },
                    child: const Text('Generar'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ======================= BULK POR SUBCATEGORIA =======================

class _BulkMensualidadesSubcategoriaDialog extends StatefulWidget {
  final dynamic mensRepo;
  final NumberFormat fmtMoney;

  const _BulkMensualidadesSubcategoriaDialog({
    required this.mensRepo,
    required this.fmtMoney,
  });

  @override
  State<_BulkMensualidadesSubcategoriaDialog> createState() =>
      _BulkMensualidadesSubcategoriaDialogState();
}

class _BulkMensualidadesSubcategoriaDialogState
    extends State<_BulkMensualidadesSubcategoriaDialog> {
  int _step = 0;

  bool _loadingSubcats = true;
  String? _errorSubcats;
  List<Map<String, dynamic>> _subcats = [];
  Map<String, dynamic>? _subcat;

  bool _loadingEsts = false;
  String? _errorEsts;
  List<Map<String, dynamic>> _estudiantes = [];
  Set<int> _selectedIds = {};

  final _qEstCtl = TextEditingController();

  int _anio = DateTime.now().year;
  int _mes = DateTime.now().month;
  final TextEditingController _valorCtl = TextEditingController(text: '40.00');

  // Preview
  int _dupCount = 0;
  int _toCreateCount = 0;

  // Submit
  bool _submitting = false;
  String? _submitError;
  Map<String, dynamic>? _result;
  int _dupCountClient = 0;

  @override
  void initState() {
    super.initState();
    _loadSubcategorias();
  }

  @override
  void dispose() {
    _valorCtl.dispose();
    _qEstCtl.dispose();
    super.dispose();
  }

  int _subcatId(Map<String, dynamic> m) =>
      _asInt(m['id_subcategoria'] ?? m['idSubcategoria'] ?? m['id'], 0);

  String _subcatNombre(Map<String, dynamic> m) =>
      (m['nombre_subcategoria'] ??
              m['subcategoria'] ??
              m['nombre'] ??
              m['nombreSubcategoria'] ??
              'Subcategoría')
          .toString();

  int _estId(Map<String, dynamic> m) =>
      _asInt(m['id_estudiante'] ?? m['idEstudiante'] ?? m['id'], 0);

  String _estNombre(Map<String, dynamic> m) {
    final n = (m['nombres'] ?? m['nombre'] ?? '').toString().trim();
    final a = (m['apellidos'] ?? '').toString().trim();
    final full = ('$n $a').trim();
    return full.isEmpty ? 'Estudiante' : full;
  }

  String _estCedula(Map<String, dynamic> m) =>
      (m['cedula'] ?? m['dni'] ?? m['documento'] ?? '').toString();

  List<int> _mesesExistentes(Map<String, dynamic> m) {
    final raw = m['meses_existentes'] ?? m['mesesExistentes'];
    if (raw is List) {
      return raw.map((e) => _asInt(e, 0)).where((x) => x > 0).toList();
    }
    return const [];
  }

  double? _asDoubleLocal(String s) {
    var t = s.trim();
    if (t.isEmpty) return null;
    t = t.replaceAll(RegExp(r'[^0-9,.\-]'), '');
    if (t.isEmpty) return null;

    if (t.contains('.') && t.contains(',')) {
      t = t.replaceAll('.', '').replaceAll(',', '.');
    } else if (t.contains(',')) {
      t = t.replaceAll(',', '.');
    }
    return double.tryParse(t);
  }

  String _friendlyErr(Object e) {
    var s = e.toString();
    s = s.replaceFirst('Exception: ', '').trim();
    if (s.isEmpty) return 'Error desconocido.';
    if (s.contains('SocketException')) {
      return 'No hay conexión con el servidor. Verifica tu red o el backend.';
    }
    if (s.toLowerCase().contains('timeout')) {
      return 'La solicitud tardó demasiado (timeout). Intenta nuevamente.';
    }
    if (s.contains('401') || s.toLowerCase().contains('unauthorized')) {
      return 'No autorizado. Vuelve a iniciar sesión.';
    }
    if (s.contains('403') || s.toLowerCase().contains('forbidden')) {
      return 'No tienes permisos para realizar esta acción.';
    }
    return s;
  }

  Future<void> _loadSubcategorias() async {
    setState(() {
      _loadingSubcats = true;
      _errorSubcats = null;
      _subcats = [];
      _subcat = null;
    });

    try {
      final res = await widget.mensRepo.obtenerSubcategoriasBulk();
      final list = List<Map<String, dynamic>>.from(res ?? const []);
      list.sort((a, b) => _subcatNombre(a).compareTo(_subcatNombre(b)));
      if (!mounted) return;
      setState(() {
        _subcats = list;
        _loadingSubcats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingSubcats = false;
        _errorSubcats = _friendlyErr(e);
      });
    }
  }

  Future<void> _loadEstudiantes({bool preserveSelection = true}) async {
    if (_subcat == null) return;

    final prevSelected = Set<int>.from(_selectedIds);

    setState(() {
      _loadingEsts = true;
      _errorEsts = null;
      _estudiantes = [];
      _selectedIds = {};
    });

    final idSubcat = _subcatId(_subcat!);

    try {
      final res = await widget.mensRepo.obtenerEstudiantesPorSubcategoria(
        idSubcategoria: idSubcat,
        anio: _anio,
      );
      final list = List<Map<String, dynamic>>.from(res ?? const []);
      list.sort((a, b) => _estNombre(a).compareTo(_estNombre(b)));

      final ids = list.map(_estId).where((x) => x > 0).toSet();
      final nextSelected =
          preserveSelection ? prevSelected.intersection(ids) : <int>{};

      if (!mounted) return;
      setState(() {
        _estudiantes = list;
        _selectedIds = nextSelected.isNotEmpty ? nextSelected : ids;
        _loadingEsts = false;
      });

      _recalcPreview();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingEsts = false;
        _errorEsts = _friendlyErr(e);
      });
    }
  }

  void _recalcPreview() {
    if (_subcat == null || _estudiantes.isEmpty) {
      setState(() {
        _dupCount = 0;
        _toCreateCount = 0;
      });
      return;
    }

    int dup = 0;
    int ok = 0;

    for (final est in _estudiantes) {
      final id = _estId(est);
      if (!_selectedIds.contains(id)) continue;

      final meses = _mesesExistentes(est);
      if (meses.contains(_mes)) {
        dup++;
      } else {
        ok++;
      }
    }

    setState(() {
      _dupCount = dup;
      _toCreateCount = ok;
    });
  }

  bool get _isDone => _result != null;

  void _cancel() => Navigator.of(context).pop(false);

  void _back() {
    if (_submitting) return;
    if (_step == 0) return _cancel();
    setState(() => _step -= 1);
  }

  void _continue() {
    if (_submitting) return;

    switch (_step) {
      case 0:
        if (_subcat == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selecciona una subcategoría.')),
          );
          return;
        }
        _loadEstudiantes().then((_) {
          if (!mounted) return;
          if (_errorEsts == null) setState(() => _step = 1);
        });
        return;

      case 1:
        if (_loadingEsts) return;
        if (_errorEsts != null) return;
        if (_selectedIds.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selecciona al menos un estudiante.')),
          );
          return;
        }
        setState(() => _step = 2);
        return;

      case 2:
        final v = _asDoubleLocal(_valorCtl.text);
        if (v == null || v <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ingresa un valor válido (> 0).')),
          );
          return;
        }
        _recalcPreview();
        setState(() => _step = 3);
        return;

      case 3:
        setState(() => _step = 4);
        return;

      default:
        return;
    }
  }

  Future<void> _submit() async {
    if (_submitting || _subcat == null) return;

    final valor = _asDoubleLocal(_valorCtl.text);
    if (valor == null || valor <= 0) {
      setState(() => _submitError = 'Ingresa un valor válido (> 0).');
      return;
    }

    final idSubcat = _subcatId(_subcat!);
    final toCreateIds = <int>[];
    int dupClient = 0;

    for (final est in _estudiantes) {
      final id = _estId(est);
      if (!_selectedIds.contains(id)) continue;

      final meses = _mesesExistentes(est);
      if (meses.contains(_mes)) {
        dupClient++;
      } else {
        toCreateIds.add(id);
      }
    }

    setState(() {
      _submitting = true;
      _submitError = null;
      _result = null;
      _dupCountClient = dupClient;
    });

    try {
      if (toCreateIds.isEmpty) {
        if (!mounted) return;
        setState(() {
          _result = {
            'ok': true,
            'total_creadas': 0,
            'total_saltadas': 0,
            'total_intentadas': 0,
            'errores': const [],
          };
        });
        return;
      }

      final res = await widget.mensRepo.crearMensualidadesBulk(
        idSubcategoria: idSubcat,
        anio: _anio,
        meses: <int>[_mes],
        valor: double.parse(valor.toStringAsFixed(2)),
        estudiantesIds: toCreateIds,
      );

      if (!mounted) return;
      setState(() {
        _result = Map<String, dynamic>.from(res);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitError = _friendlyErr(e);
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final years = <int>{
      DateTime.now().year - 1,
      DateTime.now().year,
      DateTime.now().year + 1,
    }.toList()
      ..sort();

    if (!years.contains(_anio)) years.add(_anio);
    years.sort();

    final q = _qEstCtl.text.trim().toLowerCase();

    final estFiltrados = q.isEmpty
        ? _estudiantes
        : _estudiantes.where((e) {
            final n = _estNombre(e).toLowerCase();
            final d = _estCedula(e).toLowerCase();
            return n.contains(q) || d.contains(q);
          }).toList();

    final previewToCreate = <Map<String, dynamic>>[];
    final previewDup = <Map<String, dynamic>>[];

    if (_subcat != null && _estudiantes.isNotEmpty && _selectedIds.isNotEmpty) {
      for (final est in _estudiantes) {
        final id = _estId(est);
        if (!_selectedIds.contains(id)) continue;

        final meses = _mesesExistentes(est);
        if (meses.contains(_mes)) {
          previewDup.add(est);
        } else {
          previewToCreate.add(est);
        }
      }
    }

    final previewToCreateShown = (previewToCreate.length > 40)
        ? previewToCreate.sublist(0, 40)
        : previewToCreate;
    final previewDupShown =
        (previewDup.length > 40) ? previewDup.sublist(0, 40) : previewDup;

    final steps = <Step>[
      Step(
        title: const Text('Subcategoría'),
        isActive: _step >= 0,
        state: _subcat != null ? StepState.complete : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loadingSubcats)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
            if (_errorSubcats != null) ...[
              Text(_errorSubcats!, style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _loadSubcategorias,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ),
            ],
            if (!_loadingSubcats && _errorSubcats == null) ...[
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _subcat,
                items: _subcats
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(_subcatNombre(s))))
                    .toList(),
                decoration: const InputDecoration(
                  labelText: 'Selecciona una subcategoría',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  setState(() {
                    _subcat = v;
                    _estudiantes = [];
                    _selectedIds = {};
                    _errorEsts = null;
                    _result = null;
                    _submitError = null;
                    _dupCountClient = 0;
                    _dupCount = 0;
                    _toCreateCount = 0;
                    _qEstCtl.clear();
                  });
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Se cargarán los estudiantes de la subcategoría seleccionada.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      Step(
        title: const Text('Estudiantes'),
        isActive: _step >= 1,
        state: (_estudiantes.isNotEmpty && _selectedIds.isNotEmpty)
            ? StepState.complete
            : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loadingEsts)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
            if (_errorEsts != null) ...[
              Text(_errorEsts!, style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _loadEstudiantes,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ),
            ],
            if (!_loadingEsts && _errorEsts == null) ...[
              Row(
                children: [
                  Text(
                      'Total: ${_estudiantes.length} | Seleccionados: ${_selectedIds.length}'),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      final all = _estudiantes.map(_estId).toSet();
                      setState(() {
                        _selectedIds =
                            _selectedIds.length == all.length ? {} : all;
                      });
                      _recalcPreview();
                    },
                    icon: Icon(
                      _selectedIds.length == _estudiantes.length
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                    ),
                    label: const Text('Todos'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _qEstCtl,
                decoration: const InputDecoration(
                  labelText: 'Buscar dentro de la subcategoría',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              if (_estudiantes.isEmpty)
                const Text('No hay estudiantes en esta subcategoría.')
              else
                SizedBox(
                  height: 260,
                  child: ListView.separated(
                    itemCount: estFiltrados.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final e = estFiltrados[i];
                      final id = _estId(e);
                      final name = _estNombre(e);
                      final doc = _estCedula(e);
                      final exist = _asInt(e['mensualidades_existentes'], 0);
                      return CheckboxListTile(
                        dense: true,
                        value: _selectedIds.contains(id),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedIds.add(id);
                            } else {
                              _selectedIds.remove(id);
                            }
                          });
                          _recalcPreview();
                        },
                        title: Text(name),
                        subtitle: Text(
                            '${doc.isEmpty ? 'Sin documento' : doc} · Mensualidades $_anio: $exist'),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
      Step(
        title: const Text('Mes, año y valor'),
        isActive: _step >= 2,
        state: StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _mes,
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                          value: i + 1, child: Text(_mesNombre(i + 1))),
                    ),
                    decoration: const InputDecoration(
                        labelText: 'Mes', border: OutlineInputBorder()),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _mes = v);
                      _recalcPreview();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _anio,
                    items: years
                        .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                        .toList(),
                    decoration: const InputDecoration(
                        labelText: 'Año', border: OutlineInputBorder()),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _anio = v);
                      _loadEstudiantes(preserveSelection: true);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valorCtl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Valor de la mensualidad',
                prefixText: '${widget.fmtMoney.currencySymbol} ',
                border: const OutlineInputBorder(),
                helperText: 'Se aplicará el mismo valor a todos los seleccionados.',
              ),
              onChanged: (_) => _recalcPreview(),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                Chip(label: Text('Se crearán: $_toCreateCount')),
                Chip(label: Text('Duplicados: $_dupCount')),
              ],
            ),
          ],
        ),
      ),
      Step(
        title: const Text('Resumen'),
        isActive: _step >= 3,
        state: StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subcategoría: ${_subcat == null ? '-' : _subcatNombre(_subcat!)}'),
            const SizedBox(height: 6),
            Text('Mes / Año: ${_mesNombre(_mes)} $_anio'),
            const SizedBox(height: 6),
            Text('Estudiantes seleccionados: ${_selectedIds.length}'),
            const SizedBox(height: 6),
            Text('Se crearán: $_toCreateCount'),
            Text('Omitidas por duplicado: $_dupCount'),
            const SizedBox(height: 10),
            ExpansionTile(
              title: Text('Se crearán para ($_toCreateCount)'),
              children: [
                if (previewToCreate.isEmpty)
                  const ListTile(dense: true, title: Text('No hay estudiantes a crear.'))
                else
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      itemCount: previewToCreateShown.length,
                      itemBuilder: (ctx, i) {
                        final e = previewToCreateShown[i];
                        final doc = _estCedula(e);
                        return ListTile(
                          dense: true,
                          title: Text(_estNombre(e)),
                          subtitle: Text(doc.isEmpty ? 'Sin documento' : doc),
                        );
                      },
                    ),
                  ),
                if (previewToCreate.length > previewToCreateShown.length)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Mostrando ${previewToCreateShown.length} de ${previewToCreate.length}.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
            ExpansionTile(
              title: Text('Omitidas por duplicado ($_dupCount)'),
              children: [
                if (previewDup.isEmpty)
                  const ListTile(dense: true, title: Text('No hay duplicados detectados.'))
                else
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      itemCount: previewDupShown.length,
                      itemBuilder: (ctx, i) {
                        final e = previewDupShown[i];
                        final name = _estNombre(e);
                        final doc = _estCedula(e);
                        return ListTile(
                          dense: true,
                          title: Text(name),
                          subtitle: Text(
                              '${doc.isEmpty ? 'Sin documento' : doc} · Ya existe mensualidad para este mes/año.'),
                        );
                      },
                    ),
                  ),
                if (previewDup.length > previewDupShown.length)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Mostrando ${previewDupShown.length} de ${previewDup.length}.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Nota: se evita crear duplicados para (estudiante + mes + año).',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      Step(
        title: const Text('Confirmar'),
        isActive: _step >= 4,
        state: _isDone ? StepState.complete : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Se registrarán mensualidades para $_toCreateCount estudiante(s).'),
            const SizedBox(height: 6),
            Text('Omitidas por duplicado (cliente): $_dupCount'),
            const SizedBox(height: 12),
            if (_submitError != null) ...[
              Text(_submitError!, style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 8),
            ],
            if (_submitting) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Registrando mensualidades...'),
            ],
            if (_isDone) ...[
              const Divider(height: 24),
              _buildResultSummary(theme),
            ],
          ],
        ),
      ),
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 800),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  // ✅ Se quitó el ícono de asignación
                  Icon(Icons.calendar_month,
                      size: 28, color: theme.colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text('Generación Masiva por Subcategoría',
                        style: theme.textTheme.headlineSmall),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: _cancel,
                    icon: const Icon(Icons.close),
                  )
                ],
              ),
            ),
            const Divider(height: 32),
            Expanded(
              child: Stepper(
                type: StepperType.horizontal,
                elevation: 0,
                currentStep: _step,
                onStepContinue: _continue,
                onStepCancel: _back,
                steps: steps
                    .map((s) => Step(
                          title: Text((s.title as Text).data!.split(' ').first),
                          content: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: s.content,
                          ),
                          isActive: s.isActive,
                          state: s.state,
                        ))
                    .toList(),
                controlsBuilder: (context, details) {
                  final isLast = _step == steps.length - 1;

                  if (isLast) {
                    if (_isDone) {
                      final created = _asInt(_result?['total_creadas'], 0);
                      return Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Row(
                          children: [
                            TextButton(
                              onPressed: _submitting
                                  ? null
                                  : () {
                                      Navigator.of(context).pop(created > 0);
                                    },
                              child: const Text('Cerrar'),
                            ),
                          ],
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: _submitting ? null : _cancel,
                            child: const Text('Cancelar'),
                          ),
                          const Spacer(),
                          OutlinedButton(
                            onPressed: _submitting ? null : _back,
                            child: const Text('Atrás'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed:
                                (_submitting || _subcat == null) ? null : _submit,
                            icon: const Icon(Icons.check),
                            label: const Text('Confirmar'),
                          ),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: _submitting ? null : _cancel,
                          child: const Text('Cancelar'),
                        ),
                        const Spacer(),
                        if (_step > 0)
                          OutlinedButton(
                            onPressed: _submitting ? null : _back,
                            child: const Text('Atrás'),
                          ),
                        if (_step > 0) const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _submitting ? null : _continue,
                          child: const Text('Siguiente'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSummary(ThemeData theme) {
    final created = _asInt(_result?['total_creadas'], 0);
    final skippedBackend = _asInt(_result?['total_saltadas'], 0);
    final attempted = _asInt(_result?['total_intentadas'], 0);
    final errors = (_result?['errores'] is List)
        ? List<Map<String, dynamic>>.from(_result!['errores'])
        : <Map<String, dynamic>>[];

    final failed = errors.length;
    final omitDup = _dupCountClient;
    final omitOther = skippedBackend;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resultado', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _chip('Creadas', '$created'),
            _chip('Omitidas (duplicado)', '$omitDup'),
            _chip('Omitidas (backend)', '$omitOther'),
            _chip('Fallidas', '$failed'),
            _chip('Intentadas', '$attempted'),
          ],
        ),
        if (errors.isNotEmpty) ...[
          const SizedBox(height: 12),
          ExpansionTile(
            title: Text('Ver detalles de fallos (${errors.length})'),
            children: [
              SizedBox(
                height: 180,
                child: ListView.separated(
                  itemCount: errors.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final e = errors[i];
                    final msg = (e['message'] ??
                            e['mensaje'] ??
                            e['error'] ??
                            e['detalle'] ??
                            e.toString())
                        .toString();
                    final idEst =
                        e['id_estudiante'] ?? e['idEstudiante'] ?? e['estudianteId'];
                    return ListTile(
                      dense: true,
                      title: Text('Estudiante: ${idEst ?? '-'}'),
                      subtitle: Text(msg),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Al cerrar, el listado actual se refrescará automáticamente si corresponde.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _chip(String label, String value) {
    return Chip(label: Text('$label: $value'));
  }
}
