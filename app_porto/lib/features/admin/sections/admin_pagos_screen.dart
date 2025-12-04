import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

// Paquetes externos
import 'package:cross_file/cross_file.dart';
import 'package:file_selector/file_selector.dart';
import 'package:excel/excel.dart' as xls;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:app_porto/app/app_scope.dart';
import 'package:app_porto/core/services/session_token_provider.dart';
import '../data/pagos_repository.dart';
import '../../../core/constants/endpoints.dart';

// ======================= HELPERS GLOBALES =======================

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

final _fmtMoney = NumberFormat.currency(locale: 'es_EC', symbol: r'$');

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
  List<Map<String, dynamic>> _mensualidades = [];
  bool _generandoMens = false;

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
      } else {
        // ignore: avoid_print
        print('[AdminPagosScreen] Sin token, no cargar estudiantes');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[AdminPagosScreen] Error en _checkAuthAndLoad: $e');
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
      final nombre =
          (e['nombreCompleto'] ?? '').toString().toLowerCase();
      final id = '${e['id'] ?? ''}';
      final cedula =
          '${e['cedula'] ?? e['dni'] ?? e['documento'] ?? ''}';
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

    setState(() {
      _loadingEsts = true;
      _errorEsts = null;
    });

    dynamic res;
    try {
      if (q.isEmpty) {
        // Intentos usando el repo
        try {
          res = await _estRepo.paged(page: 1, pageSize: _MAX_FETCH);
        } catch (_) {}
        res ??= await (() async {
          try {
            return await _estRepo.listar();
          } catch (_) {}
          return null;
        })();
        res ??= await (() async {
          try {
            return await _estRepo.list();
          } catch (_) {}
          return null;
        })();
        res ??= await (() async {
          try {
            return await _estRepo.getAll();
          } catch (_) {}
          return null;
        })();
        res ??= await (() async {
          try {
            return await _estRepo.activos();
          } catch (_) {}
          return null;
        })();
        res ??= await (() async {
          try {
            return await _estRepo.listarActivos();
          } catch (_) {}
          return null;
        })();
        res ??= await (() async {
          try {
            return await _estRepo.page(1, _MAX_FETCH);
          } catch (_) {}
          return null;
        })();

        // Fallback HTTP
        if (res == null) {
          final base = Endpoints.estudiantes;
          final urls = [
            '$base/paged?page=1&limit=$_MAX_FETCH',
            '$base?limit=$_MAX_FETCH',
            '$base/all',
          ];
          for (final u in urls) {
            final r = await _safeGet(u);
            final list = _coerceList(r);
            if (list.isNotEmpty) {
              res = list;
              break;
            }
          }
        }
      } else {
        // Búsqueda por texto
        try {
          res = await _estRepo.buscar(q);
        } catch (_) {}
        res ??= await (() async {
          try {
            return await _estRepo.search(q);
          } catch (_) {}
          return null;
        })();
        res ??= await (() async {
          try {
            return await _estRepo.find(q);
          } catch (_) {}
          return null;
        })();
        res ??= await (() async {
          try {
            return await _estRepo.autocomplete(q);
          } catch (_) {}
          return null;
        })();

        // Fallback HTTP
        if (res == null) {
          final base = Endpoints.estudiantes;
          final urls = [
            '$base/paged?page=1&limit=$_MAX_FETCH&q=$q',
            '$base?limit=$_MAX_FETCH&q=$q',
            '$base/search?q=$q',
            '$base/buscar?q=$q',
          ];
          for (final u in urls) {
            final r = await _safeGet(u);
            final list = _coerceList(r);
            if (list.isNotEmpty) {
              res = list;
              break;
            }
          }
        }
      }

      List<Map<String, dynamic>> items = [];
      if (res is List) {
        items = List<Map<String, dynamic>>.from(
          res.map((e) => Map<String, dynamic>.from(e as Map)),
        );
      } else if (res is Map && res['items'] is List) {
        items = List<Map<String, dynamic>>.from(
          (res['items'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );
      } else if (res is Map && res['rows'] is List) {
        items = List<Map<String, dynamic>>.from(
          (res['rows'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );
      }

      for (final s in items) {
        s['id'] = s['id'] ?? s['id_estudiante'] ?? s['estudiante_id'];
        final n = (s['nombres'] ?? '').toString();
        final a = (s['apellidos'] ?? '').toString();
        s['nombreCompleto'] =
            s['nombreCompleto'] ?? ('$n $a').trim();
      }

      items.sort((a, b) => (a['nombreCompleto'] ?? '')
          .toString()
          .toLowerCase()
          .compareTo(
              (b['nombreCompleto'] ?? '').toString().toLowerCase()));

      if (!mounted) return;
      setState(() {
        _estudiantes = items;
        _loadingEsts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorEsts = 'Error: $e';
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
      final idEst = (_estudiante!['id'] as num).toInt();
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
        (list ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );

      for (final m in data) {
        m['id'] = m['id'] ?? m['id_mensualidad'] ?? m['mensualidad_id'];
        m['estado'] = (m['estado'] ?? 'pendiente').toString();
        m['valor'] = _asDouble(m['valor']);
        m['mes'] = m['mes'] ?? m['month'];
        m['anio'] = m['anio'] ?? m['year'];
      }

      if (_estado != 'Todos') {
        data = data
            .where((m) => (m['estado'] ?? '') == _estado)
            .toList();
      }
      if (_anioFiltro != null) {
        data = data
            .where((m) => m['anio'] == _anioFiltro)
            .toList();
      }
      if (_soloPendiente) {
        data = data
            .where((m) => (m['estado'] ?? '') != 'pagado')
            .toList();
      }

      if (!mounted) return;
      setState(() => _mensualidades = data);

      await _recalcularTotales();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
      final futures = _mensualidades
          .map((m) => _cargarResumen(m['id'] as int));
      final res = await Future.wait(futures);

      double v = 0, p = 0, pe = 0;
      for (var i = 0; i < res.length; i++) {
        final r = res[i];
        final local = _mensualidades[i];
        final valor = _asDouble(r?['valor'] ?? local['valor']);
        final pagado = _asDouble(r?['pagado'] ?? 0);
        final pendiente =
            _asDouble(r?['pendiente'] ?? (valor - pagado));
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
    try {
      final r = await _pagosRepo.resumen(idM);
      if (r != null) _resumenCache[idM] = r;
      return r;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _cargarPagos(int idM) async {
    if (_blocked) return [];
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
    final resumen = await _cargarResumen(m['id'] as int);
    final restante =
        _asDouble(resumen?['pendiente'] ?? m['valor']);

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
    final resumen =
        await _cargarResumen(mensualidad['id'] as int);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _PagoDialog(
        pagosRepo: _pagosRepo,
        idMensualidad: mensualidad['id'] as int,
        restante: _asDouble(
          resumen?['pendiente'] ?? mensualidad['valor'],
        ),
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
            const Text(
              'Esta acción no se puede deshacer. El pago quedará marcado como anulado.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motivoCtl,
              decoration: const InputDecoration(
                labelText: 'Motivo de anulación *',
                border: OutlineInputBorder(),
                hintText: 'Ej: Pago duplicado, error en el monto...',
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
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              final motivo = motivoCtl.text.trim();
              if (motivo.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El motivo es obligatorio'),
                  ),
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
      final ok = await _pagosRepo.anular(
        idPago: idPago,
        motivo: confirm,
      );

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

  Future<void> _onTapGenerarHastaDiciembre() async {
    if (_blocked) {
      _showLoginSnack();
      return;
    }
    if (_estudiante == null) return;

    final anioSugerido = _anioFiltro ?? DateTime.now().year;

    final cfg = await showDialog<_GenMensConfig>(
      context: context,
      builder: (_) => _GenerarMensualidadesDialog(
        anioInicial: anioSugerido,
        fmtMoney: _fmtMoney,
        mesesYa: _mensualidades
            .where((m) => m['anio'] == anioSugerido)
            .map<int>(
              (m) => (m['mes'] as num?)?.toInt() ?? 0,
            )
            .where((m) => m >= 1 && m <= 12)
            .toSet(),
      ),
    );

    if (cfg == null) return;

    setState(() => _generandoMens = true);
    try {
      final idEst = (_estudiante!['id'] as num).toInt();

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
          const SnackBar(
            content: Text('El estudiante no tiene matrícula.'),
          ),
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
          const SnackBar(
            content: Text('No pude identificar la matrícula.'),
          ),
        );
        return;
      }

      // Evitar meses ya existentes para ese año
      final existentes = _mensualidades
          .where((m) => m['anio'] == cfg.anio)
          .map<int>((m) => (m['mes'] as num?)?.toInt() ?? 0)
          .toSet();

      final mesesObjetivo = cfg.meses
          .where((m) => m >= 1 && m <= 12 && !existentes.contains(m))
          .toList()
        ..sort();

      if (mesesObjetivo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Los meses seleccionados ya tienen mensualidades generadas.'),
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
    if (!_authChecked) {
      return Scaffold(
        appBar: widget.embedded
            ? null
            : AppBar(
                title: const Text('Gestión de Pagos'),
              ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuth) {
      return Scaffold(
        appBar: widget.embedded
            ? null
            : AppBar(
                title: const Text('Gestión de Pagos'),
              ),
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
              backgroundColor:
                  Theme.of(context).colorScheme.surface,
              actions: [
                PopupMenuButton<String>(
                  tooltip: 'Exportar',
                  enabled: _estudiante != null,
                  onSelected: (v) async {
                    if (_estudiante == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Selecciona un estudiante primero',
                          ),
                        ),
                      );
                      return;
                    }
                    try {
                      switch (v) {
                        case 'pagos.xlsx':
                          await _exportPagosExcel();
                          break;
                        case 'pagos.pdf':
                          await _exportPagosPdf();
                          break;
                        case 'preview.pagos':
                          final b =
                              await _buildPagosPdfBytes();
                          await Printing.layoutPdf(
                            onLayout: (_) async => b,
                          );
                          break;
                      }
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error al exportar: $e',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'pagos.xlsx',
                      child: ListTile(
                        leading: Icon(Icons.grid_on),
                        title: Text('Exportar pagos (Excel)'),
                        subtitle:
                            Text('Usa los filtros activos'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'pagos.pdf',
                      child: ListTile(
                        leading: Icon(Icons.picture_as_pdf),
                        title: Text('Exportar pagos (PDF)'),
                        subtitle:
                            Text('Usa los filtros activos'),
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'preview.pagos',
                      child: ListTile(
                        leading: Icon(Icons.print),
                        title: Text('Vista previa / Imprimir'),
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.download),
                ),
                IconButton(
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
                SizedBox(
                  width: 350,
                  child: _buildStudentListPanel(),
                ),
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

  // ======================= UI: LOGIN REQUEST =======================

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

  // ======================= UI: PANEL IZQUIERDO (ESTUDIANTES) =======================

  Widget _buildStudentListPanel() {
    final showHint = !_loadingEsts &&
        _estudiantes.isEmpty &&
        _qCtl.text.trim().isEmpty;

    final lista = _filtrarEstudiantesLocal().toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
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
            child: Text(
              _errorEsts!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        if (showHint)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Escribe un nombre, cédula o ID y selecciona un estudiante.',
            ),
          ),
        Expanded(
          child: _loadingEsts
              ? const Center(child: CircularProgressIndicator())
              : _estudiantes.isEmpty
                  ? const Center(
                      child: Text('Sin estudiantes'),
                    )
                  : lista.isEmpty && _qCtl.text.isNotEmpty
                      ? const Center(
                          child: Text('Sin resultados'),
                        )
                      : ListView.separated(
                          controller: _leftScrollCtl,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: lista.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final e = lista[i];
                            final selected = _estudiante != null &&
                                _estudiante!['id'] == e['id'];
                            final nombre =
                                (e['nombreCompleto'] ?? '').toString();
                            final cedula = e['cedula'] ??
                                e['dni'] ??
                                'Sin documento';

                            return Card(
                              elevation: 0,
                              color: selected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : null,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Theme.of(context)
                                      .dividerColor,
                                ),
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
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                  foregroundColor: selected
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                  child: Text(
                                    nombre.isNotEmpty
                                        ? nombre[0]
                                        : 'E',
                                  ),
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

  // ======================= UI: PANEL DERECHO (DETALLE) =======================

  Widget _buildDetailPanel({bool showBack = false}) {
    if (_estudiante == null) {
      return const Center(
        child: Text('Selecciona un estudiante'),
      );
    }

    final anios = _mensualidades
        .map((m) => m['anio'])
        .whereType<int>()
        .toSet()
        .toList()
      ..sort();

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
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () =>
                          setState(() => _estudiante = null),
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
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _estudiante!['nombreCompleto'] ??
                              'Estudiante',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _estudiante!['cedula'] ??
                              'Sin documento',
                          style: TextStyle(
                            color:
                                Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _generandoMens
                        ? null
                        : _onTapGenerarHastaDiciembre,
                    icon: _generandoMens
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.calendar_month),
                    label: const Text('Generar meses'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildKPI(
                    'Total',
                    _totValor,
                    Icons.monetization_on,
                    Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _buildKPI(
                    'Pagado',
                    _totPagado,
                    Icons.check_circle,
                    Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _buildKPI(
                    'Pendiente',
                    _totPendiente,
                    Icons.warning,
                    _totPendiente > 0
                        ? Colors.orange
                        : Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Filtro Estado
              DropdownButton<String>(
                value: _estado,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(
                    value: 'Todos',
                    child: Text('Todos'),
                  ),
                  DropdownMenuItem(
                    value: 'pendiente',
                    child: Text('Pendiente'),
                  ),
                  DropdownMenuItem(
                    value: 'pagado',
                    child: Text('Pagado'),
                  ),
                  DropdownMenuItem(
                    value: 'anulado',
                    child: Text('Anulado'),
                  ),
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
              const SizedBox(width: 12),
              // Filtro Año
              DropdownButton<int?>(
                value: _anioFiltro,
                underline: const SizedBox.shrink(),
                hint: const Text('Año'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Todos'),
                  ),
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
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refrescar mensualidades',
                onPressed: _cargarMensualidades,
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingMens
              ? const Center(child: CircularProgressIndicator())
              : _mensualidades.isEmpty
                  ? const Center(
                      child: Text('Sin mensualidades'),
                    )
                  : ListView.builder(
                      controller: _rightScrollCtl,
                      padding: const EdgeInsets.all(12),
                      itemCount: _mensualidades.length,
                      itemBuilder: (ctx, i) =>
                          _buildMensualidadCard(
                        _mensualidades[i],
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildKPI(
    String label,
    double value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
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
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _fmtMoney.format(value),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
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
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(
            esPagado ? Icons.check : Icons.attach_money,
            color: color,
          ),
        ),
        title: Text(
          '${_mesNombre(m['mes'])} ${m['anio']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          esPagado
              ? 'Pagado'
              : 'Pendiente: ${_fmtMoney.format(valor)}',
        ),
        trailing: Chip(
          label: Text(
            estado.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
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
    return FutureBuilder<Map<String, dynamic>?>(

      future: _cargarResumen(m['id'] as int),
      builder: (context, snapR) {
        final r = snapR.data;
        final valor = _asDouble(r?['valor'] ?? m['valor']);
        final pagado = _asDouble(r?['pagado'] ?? 0);
        final pendiente =
            _asDouble(r?['pendiente'] ?? (valor - pagado));
        final progress =
            valor > 0 ? (pagado / valor).clamp(0.0, 1.0) : 0.0;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              if (valor > 0) ...[
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor:
                      Colors.grey.shade200,
                  color: Colors.green,
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pagado: ${_fmtMoney.format(pagado)}',
                    ),
                    Text(
                      'Restante: ${_fmtMoney.format(pendiente)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(),
              ],
              Text(
                'Historial de pagos',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium,
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _cargarPagos(m['id'] as int),
                builder: (context, snapP) {
                  if (snapP.connectionState ==
                      ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }
                  final pagos = snapP.data ?? [];
                  if (pagos.isEmpty) {
                    return const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Sin pagos registrados',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: pagos.map((p) {
                      final activo = p['activo'] == true;
                      final monto = _asDouble(p['monto']);
                      String fechaStr =
                          (p['fecha'] ?? '').toString();
                      if (fechaStr.isNotEmpty) {
                        try {
                          final d =
                              DateTime.parse(fechaStr);
                          fechaStr =
                              DateFormat('dd/MM/yyyy HH:mm')
                                  .format(d);
                        } catch (_) {}
                      }

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
                            activo
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: activo
                                ? Colors.green
                                : Colors.red,
                          ),
                          title: Row(
                            children: [
                              Text(
                                _fmtMoney.format(monto),
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  decoration: activo
                                      ? null
                                      : TextDecoration
                                          .lineThrough,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  p['metodo'] ?? '',
                                ),
                                labelStyle:
                                    const TextStyle(
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              if (fechaStr.isNotEmpty)
                                Text('Fecha: $fechaStr'),
                              if ((p['referencia'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                Text(
                                  'Ref: ${p['referencia']}',
                                ),
                              if ((p['notas'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                Text(
                                  'Notas: ${p['notas']}',
                                ),
                              if (!activo &&
                                  (p['motivoAnulacion'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                Text(
                                  'Anulado: ${p['motivoAnulacion']}',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .error,
                                    fontStyle:
                                        FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              if (activo)
                                IconButton(
                                  tooltip: 'Editar',
                                  icon: const Icon(
                                      Icons.edit),
                                  onPressed: () =>
                                      _editarPago(m, p),
                                ),
                              if (activo)
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Anular',
                                  onPressed: () =>
                                      _anularPago(
                                    p['id'] as int,
                                    m['id'] as int,
                                  ),
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

  // ======================= EXPORTACIÓN (EXCEL / PDF) =======================

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

  String _pickStr(Map r, List<String> keys) {
    for (final k in keys) {
      final v = r[k];
      if (v != null && '$v'.isNotEmpty) return '$v';
    }
    return '';
  }

  xls.CellValue _cv(dynamic v) {
    if (v == null) return xls.TextCellValue('');
    if (v is bool) return xls.BoolCellValue(v);
    if (v is int) return xls.IntCellValue(v);
    if (v is double) return xls.DoubleCellValue(v);
    final s = '$v';
    final n = double.tryParse(s);
    return (n != null)
        ? xls.DoubleCellValue(n)
        : xls.TextCellValue(s);
  }

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
          SnackBar(
            content: Text('Descarga iniciada: $defaultFileName'),
          ),
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
        SnackBar(
          content: Text('Archivo guardado en: $path'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar: $e'),
        ),
      );
    }
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
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

  pw.Widget _buildChipPdf(
    String label,
    String? value,
    IconData icon,
    PdfColor color,
    pw.Font materialFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
          horizontal: 8, vertical: 5),
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
            value == null || value.isEmpty
                ? label
                : '$label: ${value.trim()}',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPagosExcel() async {
    if (_estudiante == null) {
      throw Exception('No hay estudiante seleccionado');
    }

    final rows = _mensualidades;
    final nombreEst =
        _estudiante!['nombreCompleto'] ?? 'estudiante';

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
      final mes = _mesNombre(
        int.tryParse(_pickStr(r, ['mes', 'Mes'])),
      );
      final anio = _pickStr(
        r,
        ['anio', 'año', 'anio_pago', 'ano', 'year'],
      );
      final est = _pickStr(r, ['estado', 'status']);
      final monto = _pickStr(
        r,
        ['monto', 'valor', 'importe', 'total', 'pago'],
      );
      final fpago = _fmtDate(
        _pickStr(
          r,
          ['fecha', 'fecha_pago', 'fecha_vencimiento'],
        ),
      );
      final obs = _pickStr(
        r,
        ['observacion', 'observación', 'nota', 'comentario'],
      );

      sheet.appendRow([
        _cv(mes),
        _cv(anio),
        _cv(est),
        _cv(monto),
        _cv(fpago),
        _cv(obs),
      ]);
    }

    final encoded = book.encode()!;
    final bytes = Uint8List.fromList(encoded);
    await _saveBytes(
      bytes,
      defaultFileName: 'pagos_${nombreEst}.xlsx',
      extensions: const ['xlsx'],
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  Future<Uint8List> _buildPagosPdfBytes() async {
    if (_estudiante == null) {
      throw Exception('No hay estudiante seleccionado');
    }

    final rows = _mensualidades;

    final robotoData =
        await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final robotoFont = pw.Font.ttf(robotoData);
    final materialData = await rootBundle
        .load('assets/fonts/MaterialIcons-Regular.ttf');
    final materialFont = pw.Font.ttf(materialData);

    final doc = pw.Document();
    final nombre =
        _estudiante!['nombreCompleto'] ?? 'Estudiante';
    const titulo = 'Reporte de Pagos';

    const baseColor = PdfColors.blueGrey800;
    const lightColor = PdfColors.grey100;

    double totalFiltrado = 0.0;
    for (final r in rows) {
      final montoStr = _pickStr(
        r,
        ['monto', 'valor', 'importe', 'total', 'pago'],
      );
      final estado =
          _pickStr(r, ['estado', 'status']).toLowerCase();
      if (estado != 'anulado') {
        totalFiltrado += _asDouble(montoStr);
      }
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
        decoration:
            const pw.BoxDecoration(color: baseColor),
        children: [
          buildCell(
            'Mes',
            isHeader: true,
            alignment: pw.Alignment.center,
          ),
          buildCell(
            'Año',
            isHeader: true,
            alignment: pw.Alignment.center,
          ),
          buildCell(
            'Estado',
            isHeader: true,
            alignment: pw.Alignment.center,
          ),
          buildCell(
            'Monto',
            isHeader: true,
            alignment: pw.Alignment.centerRight,
          ),
          buildCell(
            'Fecha',
            isHeader: true,
            alignment: pw.Alignment.center,
          ),
          buildCell(
            'Observación',
            isHeader: true,
          ),
        ],
      ),
    );

    for (int i = 0; i < rows.length; i++) {
      final r = rows[i];
      final background =
          i % 2 == 0 ? lightColor : null;
      final estado =
          _pickStr(r, ['estado', 'status']).toLowerCase();
      final monto = _pickStr(
        r,
        ['monto', 'valor', 'importe', 'total', 'pago'],
      );

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
            buildCell(
              _mesNombre(
                int.tryParse(
                  _pickStr(r, ['mes', 'Mes']),
                ),
              ),
              alignment: pw.Alignment.center,
            ),
            buildCell(
              _pickStr(
                r,
                ['anio', 'año', 'anio_pago', 'ano', 'year'],
              ),
              alignment: pw.Alignment.center,
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              color: background,
              alignment: pw.Alignment.center,
              child: _buildChipPdf(
                estado,
                '',
                statusIcon,
                statusColor,
                materialFont,
              ),
            ),
            buildCell(
              _fmtMoney.format(_asDouble(monto)),
              alignment: pw.Alignment.centerRight,
            ),
            buildCell(
              _fmtDate(
                _pickStr(
                  r,
                  [
                    'fecha',
                    'fecha_pago',
                    'fecha_vencimiento',
                  ],
                ),
              ),
              alignment: pw.Alignment.center,
            ),
            buildCell(
              _pickStr(
                r,
                [
                  'observacion',
                  'observación',
                  'nota',
                  'comentario',
                ],
              ),
            ),
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
              mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  titulo.toUpperCase(),
                  style: pw.TextStyle(
                    color: baseColor,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  nombre,
                  style: const pw.TextStyle(
                    color: PdfColors.grey700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            pw.Divider(
              color: PdfColors.grey400,
              height: 8,
            ),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment:
              pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generado el: ${_fmtDate(DateTime.now())}',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
            pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
        build: (context) => [
          _buildSectionHeader(
            'Pagos filtrados',
            Icons.receipt_long,
            baseColor,
            materialFont,
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColors.grey300,
              width: 0.5,
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.8),
              1: pw.FlexColumnWidth(1.2),
              2: pw.FlexColumnWidth(1.8),
              3: pw.FlexColumnWidth(1.5),
              4: pw.FlexColumnWidth(1.8),
              5: pw.FlexColumnWidth(3.0),
            },
            children: tableRows,
          ),
          pw.Divider(
            color: PdfColors.grey300,
            height: 24,
            thickness: 1.5,
          ),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 250,
              child: pw.Column(
                crossAxisAlignment:
                    pw.CrossAxisAlignment.end,
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
                    _anioFiltro == null &&
                            _estado == 'Todos' &&
                            !_soloPendiente
                        ? 'Mostrando todos los registros.'
                        : 'Filtros aplicados.',
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
    if (_estudiante == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un estudiante primero'),
        ),
      );
      return;
    }
    final bytes = await _buildPagosPdfBytes();
    final nombreEst =
        _estudiante!['nombreCompleto'] ?? 'estudiante';
    await _saveBytes(
      bytes,
      defaultFileName: 'pagos_${nombreEst}.pdf',
      extensions: const ['pdf'],
      mimeType: 'application/pdf',
    );
  }
}

// ======================= DIÁLOGOS =======================

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
      _montoCtl.text =
          _fmtInput.format(_asDouble(p['monto']));
      _fecha = DateTime.tryParse('${p['fecha']}') ??
          DateTime.now();
      _metodo = (p['metodo'] ?? 'efectivo') as String;
      _referencia = p['referencia']?.toString();
      _notas = p['notas']?.toString();
    } else {
      _montoCtl.text = _fmtInput
          .format(widget.restante.clamp(0, double.infinity));
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
    } else if (widget.pagoExistente == null &&
        monto > widget.restante) {
      _montoError =
          'Sobrepago. Máximo: ${_fmtInput.format(widget.restante)}';
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
      final montoRedondeado =
          double.parse(monto.toStringAsFixed(2));
      if (widget.pagoExistente == null) {
        await widget.pagosRepo.crear(
          idMensualidad: widget.idMensualidad,
          monto: montoRedondeado,
          fecha: _fecha,
          metodoPago: _metodo,
          referencia: _referencia,
          notas: _notas,
        );
      } else {
        final idPago = widget.pagoExistente!['id'] as int;
        await widget.pagosRepo.actualizar(
          idPago: idPago,
          monto: montoRedondeado,
          fecha: _fecha,
          metodoPago: _metodo,
          referencia: _referencia,
          notas: _notas,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit
                    ? 'Modifica el monto, fecha o detalles del pago seleccionado.'
                    : 'Registra un nuevo pago para esta mensualidad. No se permite sobrepago.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _montoCtl,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Monto *',
                  helperText: isEdit
                      ? 'Edición de pago existente'
                      : 'Saldo pendiente: ${_fmtInput.format(widget.restante)} (máximo permitido).',
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
                onDateSubmitted: (d) =>
                    setState(() => _fecha = d),
                onDateSaved: (d) =>
                    setState(() => _fecha = d),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _metodo,
                decoration: const InputDecoration(
                  labelText: 'Método de pago *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'efectivo',
                    child: Text('Efectivo'),
                  ),
                  DropdownMenuItem(
                    value: 'transferencia',
                    child: Text('Transferencia'),
                  ),
                  DropdownMenuItem(
                    value: 'tarjeta',
                    child: Text('Tarjeta'),
                  ),
                ],
                onChanged: (v) =>
                    setState(() => _metodo = v ?? 'efectivo'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _referencia ?? '',
                decoration: const InputDecoration(
                  labelText: 'Referencia (opcional)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _referencia =
                    v.trim().isEmpty ? null : v.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _notas ?? '',
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                onChanged: (v) =>
                    _notas = v.trim().isEmpty ? null : v.trim(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _onSubmit,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
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
  final List<int> meses;

  _GenMensConfig({
    required this.anio,
    required this.valorMensual,
    required this.meses,
  });
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
  State<_GenerarMensualidadesDialog> createState() =>
      _GenerarMensualidadesDialogState();
}

class _GenerarMensualidadesDialogState
    extends State<_GenerarMensualidadesDialog> {
  late int _anio;
  final TextEditingController _valorCtl =
      TextEditingController(text: '40.00'); // valor por defecto
  String? _error;
  late Set<int> _mesesSeleccionados;

  @override
  void initState() {
    super.initState();
    _anio = widget.anioInicial;
    final desde = _mesActualSiCorresponde();
    _mesesSeleccionados = <int>{};
    for (int m = desde; m <= 12; m++) {
      if (!widget.mesesYa.contains(m)) {
        _mesesSeleccionados.add(m);
      }
    }
  }

  int _mesActualSiCorresponde() {
    final hoy = DateTime.now();
    return (_anio == hoy.year) ? hoy.month : 1;
  }

  double _toDouble(String s) {
    var t =
        s.trim().replaceAll(' ', '').replaceAll('\$', '');
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
    final valor = _toDouble(_valorCtl.text);
    final count = _mesesSeleccionados.length;
    final total = valor * count;

    return AlertDialog(
      title: const Text('Generar mensualidades'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Año:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Text('$_anio'),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valorCtl,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Valor mensual (USD) *',
                helperText:
                    'Este valor se aplicará a todos los meses seleccionados.',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                setState(() {
                  _error = null;
                });
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Selecciona los meses a generar:',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int mes = 1; mes <= 12; mes++)
                  _buildMesChip(
                    context,
                    mes: mes,
                    desde: desde,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                count == 0
                    ? 'Selecciona al menos un mes disponible.'
                    : 'Se crearán $count mensualidad(es).\n'
                        'Total estimado: ${widget.fmtMoney.format(total)}',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final v = _toDouble(_valorCtl.text);
            if (_mesesSeleccionados.isEmpty) {
              setState(
                () => _error = 'Selecciona al menos un mes.',
              );
              return;
            }
            if (v <= 0) {
              setState(
                () => _error = 'Ingresa un valor válido (> 0).',
              );
              return;
            }
            Navigator.pop(
              context,
              _GenMensConfig(
                anio: _anio,
                valorMensual: v,
                meses: _mesesSeleccionados.toList()..sort(),
              ),
            );
          },
          child: const Text('Generar'),
        ),
      ],
    );
  }

  Widget _buildMesChip(
    BuildContext context, {
    required int mes,
    required int desde,
  }) {
    final yaExiste = widget.mesesYa.contains(mes);
    final disponible = !yaExiste && mes >= desde;
    final seleccionado = _mesesSeleccionados.contains(mes);

    final nombreMes = _mesNombre(mes);
    final etiqueta =
        nombreMes.length <= 3 ? nombreMes : nombreMes.substring(0, 3);

    return FilterChip(
      label: Text(etiqueta),
      selected: seleccionado,
      onSelected: !disponible
          ? null
          : (v) {
              setState(() {
                if (v) {
                  _mesesSeleccionados.add(mes);
                } else {
                  _mesesSeleccionados.remove(mes);
                }
                _error = null;
              });
            },
      tooltip: yaExiste
          ? 'Ya existe una mensualidad para este mes.'
          : mes < desde
              ? 'Solo se pueden generar mensualidades desde el mes actual en adelante.'
              : null,
    );
  }
}
