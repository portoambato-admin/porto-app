// lib/features/admin/sections/reportes_pagos_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:app_porto/app/app_scope.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:file_selector/file_selector.dart';
import 'package:cross_file/cross_file.dart';

// NUEVO (vista previa PDF)
import 'package:printing/printing.dart';

class ReportesPagosScreen extends StatefulWidget {
  const ReportesPagosScreen({super.key});

  @override
  State<ReportesPagosScreen> createState() => _ReportesPagosScreenState();
}

class _ReportesPagosScreenState extends State<ReportesPagosScreen> {
  AppScope get _scope => AppScope.of(context);

  String _busqueda = '';
  final ScrollController _scrollController = ScrollController();

  // ==============================
  // CONFIGURACIÓN DE REPORTES
  // ==============================
  final List<ReporteConfig> _reportes = [
    ReporteConfig(
      id: 'estado_cobros',
      categoria: 'Cobros',
      nombre: 'Estado General de Cobros',
      descripcion:
          'Resumen completo de cobros realizados, pendientes y vencidos con totales',
      icono: Icons.pie_chart,
      color: Colors.blue,
      filtros: [
        FiltroTipo.rangoOpcional,
        FiltroTipo.fechaCorte,
        FiltroTipo.diaVencimiento
      ],
    ),
    ReporteConfig(
      id: 'cuentas_cobrar',
      categoria: 'Cobros',
      nombre: 'Cuentas por Cobrar',
      descripcion:
          'Listado detallado de clientes con deudas pendientes y días de mora',
      icono: Icons.account_balance_wallet,
      color: Colors.orange,
      filtros: [FiltroTipo.fechaCorte, FiltroTipo.diaVencimiento],
    ),
    ReporteConfig(
      id: 'historial_cliente',
      categoria: 'Cobros',
      nombre: 'Historial de Cliente',
      descripcion:
          'Historial completo de pagos y mensualidades de un estudiante específico',
      icono: Icons.history,
      color: Colors.teal,
      filtros: [
        FiltroTipo.idEstudiante,
        FiltroTipo.rangoOpcional,
        FiltroTipo.fechaCorte,
        FiltroTipo.diaVencimiento
      ],
    ),
    ReporteConfig(
      id: 'cobros_periodo',
      categoria: 'Cobros',
      nombre: 'Cobros por Período',
      descripcion:
          'Análisis temporal de cobros agrupados por día, semana, mes o año',
      icono: Icons.timeline,
      color: Colors.purple,
      filtros: [FiltroTipo.rangoRequerido, FiltroTipo.granularidad],
    ),
    ReporteConfig(
      id: 'metodos_pago',
      categoria: 'Cobros',
      nombre: 'Métodos de Pago',
      descripcion: 'Distribución y estadísticas de pagos por método utilizado',
      icono: Icons.payment,
      color: Colors.green,
      filtros: [FiltroTipo.rangoOpcional],
    ),
    ReporteConfig(
      id: 'morosidad',
      categoria: 'Morosidad',
      nombre: 'Análisis de Morosidad',
      descripcion:
          'Indicadores y métricas de mora con porcentajes y montos totales',
      icono: Icons.warning_amber,
      color: Colors.red,
      filtros: [FiltroTipo.fechaCorte, FiltroTipo.diaVencimiento],
    ),
    ReporteConfig(
      id: 'alertas',
      categoria: 'Morosidad',
      nombre: 'Alertas y Recordatorios',
      descripcion: 'Efectividad de recordatorios de pago enviados a clientes',
      icono: Icons.notifications_active,
      color: Colors.deepOrange,
      filtros: [FiltroTipo.rangoOpcional, FiltroTipo.ventanaDias],
    ),
    ReporteConfig(
      id: 'consolidado',
      categoria: 'Gerencia',
      nombre: 'Consolidado Gerencial',
      descripcion: 'Dashboard ejecutivo con KPIs y métricas clave del negocio',
      icono: Icons.dashboard,
      color: Colors.indigo,
      filtros: [
        FiltroTipo.rangoOpcional,
        FiltroTipo.fechaCorte,
        FiltroTipo.diaVencimiento
      ],
    ),
    ReporteConfig(
      id: 'estudiantes_resumen',
      categoria: 'Estudiantes',
      nombre: 'Resumen de Estudiantes',
      descripcion: 'Distribución de estudiantes por categorías y subcategorías',
      icono: Icons.school,
      color: Colors.cyan,
      filtros: [],
    ),
    ReporteConfig(
      id: 'asistencia',
      categoria: 'Estudiantes',
      nombre: 'Asistencia',
      descripcion:
          'Estadísticas de asistencia, tardanzas, ausencias y justificaciones',
      icono: Icons.checklist,
      color: Colors.lightGreen,
      filtros: [FiltroTipo.rangoRequerido, FiltroTipo.idSubcategoria],
    ),
    ReporteConfig(
      id: 'evaluaciones',
      categoria: 'Estudiantes',
      nombre: 'Evaluaciones',
      descripcion:
          'Promedios y ranking de estudiantes por evaluaciones académicas',
      icono: Icons.grade,
      color: Colors.amber,
      filtros: [FiltroTipo.rangoRequerido, FiltroTipo.top],
    ),
    ReporteConfig(
      id: 'usuarios',
      categoria: 'Sistema',
      nombre: 'Usuarios del Sistema',
      descripcion: 'Resumen de usuarios, roles y métodos de autenticación',
      icono: Icons.people,
      color: Colors.blueGrey,
      filtros: [],
    ),
    ReporteConfig(
      id: 'auditoria',
      categoria: 'Sistema',
      nombre: 'Auditoría de Actividad',
      descripcion:
          'Top usuarios más activos y acciones más frecuentes en el sistema',
      icono: Icons.security,
      color: Colors.brown,
      filtros: [FiltroTipo.rangoRequerido, FiltroTipo.top],
    ),
  ];

  // ==============================
  // AGRUPACIÓN + FILTRO
  // ==============================
  Map<String, List<ReporteConfig>> get _reportesAgrupados {
    final busq = _busqueda.toLowerCase().trim();
    final filtrados = _reportes
        .where((r) =>
            r.nombre.toLowerCase().contains(busq) ||
            r.descripcion.toLowerCase().contains(busq) ||
            r.categoria.toLowerCase().contains(busq))
        .toList();

    final agrupados = <String, List<ReporteConfig>>{};
    for (var r in filtrados) {
      (agrupados[r.categoria] ??= []).add(r);
    }
    return agrupados;
  }

  // ==============================
  // HELPERS: SELECTOR ESTUDIANTES (usa tu repo REAL: paged)
  // ==============================
  Future<List<EstudianteOption>> _fetchEstudiantes(String search) async {
    final s = search.trim();

    try {
      final res = await _scope.estudiantes.paged(
        page: 1,
        pageSize: 60,
        q: s.isEmpty ? null : s,
      );

      final dynamic raw = (res is Map) ? (res['items'] ?? res) : res;
      final list = _coerceToListOfMaps(raw);

      return list.map(EstudianteOption.fromMap).toList();
    } catch (_) {
      return <EstudianteOption>[];
    }
  }

  List<Map<String, dynamic>> _coerceToListOfMaps(dynamic raw) {
    if (raw == null) return <Map<String, dynamic>>[];

    if (raw is String) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {}
    }

    if (raw is Map) {
      for (final key
          in ['items', 'data', 'rows', 'result', 'results', 'estudiantes']) {
        final v = raw[key];
        if (v is List) {
          return v
              .whereType<Map>()
              .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
              .toList();
        }
      }
    }

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    }

    return <Map<String, dynamic>>[];
  }

  // ==============================
  // UI PRINCIPAL
  // ==============================
  @override
  Widget build(BuildContext context) {
    final agrupados = _reportesAgrupados;
    final categorias = agrupados.keys.toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: agrupados.isEmpty
                ? _buildEmptyState()
                : Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: Semantics(
                      label: 'Lista de reportes disponibles',
                      hint:
                          'Explora por categoría. Toca un reporte para seleccionar el formato.',
                      child: CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          for (var categoria in categorias) ...[
                            SliverToBoxAdapter(
                              child: Semantics(
                                header: true,
                                label: 'Categoría $categoria',
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: 24, bottom: 12),
                                  child: Row(
                                    children: [
                                      Tooltip(
                                        message: 'Categoría: $categoria',
                                        child: Container(
                                          width: 4,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(context).primaryColor,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        categoria,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[800],
                                            ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Divider(
                                              color: Colors.grey[300])),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 400,
                                mainAxisExtent: 180,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final config = agrupados[categoria]![index];
                                  return _buildReporteCard(config);
                                },
                                childCount: agrupados[categoria]!.length,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Semantics(
      label: 'No se encontraron reportes',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_outlined,
                size: 80,
                color: Colors.grey[300],
                semanticLabel: 'Sin resultados'),
            const SizedBox(height: 16),
            Text(
              'No se encontraron reportes',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Semantics(
      header: true,
      label: 'Centro de Reportes',
      hint:
          'Busca reportes por nombre, descripción o categoría. Luego selecciona un reporte para previsualizar y descargar.',
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Tooltip(
                  message: 'Centro de Reportes',
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      color: Theme.of(context).primaryColor,
                      size: 32,
                      semanticLabel: 'Reportes',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Centro de Reportes',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Genera, previsualiza y exporta métricas clave del sistema.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Semantics(
              textField: true,
              label: 'Buscar reporte',
              hint: 'Escribe para filtrar por nombre, descripción o categoría',
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Buscar reporte',
                  helperText: 'Filtra por nombre, descripción o categoría',
                  hintText: 'Ej. "Cobros", "Asistencia"...',
                  prefixIcon: const Icon(Icons.search, semanticLabel: 'Buscar'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                onChanged: (v) => setState(() => _busqueda = v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReporteCard(ReporteConfig config) {
    final semanticsLabel = 'Reporte: ${config.nombre}. ${config.descripcion}.';
    final semanticsHint =
        'Toca para seleccionar el formato (CSV o PDF), previsualizar y descargar.';

    return Semantics(
      button: true,
      label: semanticsLabel,
      hint: semanticsHint,
      child: Tooltip(
        message: 'Exportar: ${config.nombre}',
        child: Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _mostrarDialogoFormato(config),
            hoverColor: config.color.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tooltip(
                        message: config.nombre,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: config.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            config.icono,
                            color: config.color,
                            size: 24,
                            semanticLabel: 'Ícono de ${config.nombre}',
                          ),
                        ),
                      ),
                      const Spacer(),
                      Tooltip(
                        message: 'Información del reporte',
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.grey[400],
                          size: 20,
                          semanticLabel: 'Información',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    config.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      config.descripcion,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (config.filtros.isNotEmpty)
                    Tooltip(
                      message:
                          'Este reporte tiene ${config.filtros.length} filtros',
                      child: Semantics(
                        label: 'Cantidad de filtros: ${config.filtros.length}',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune,
                                  size: 12,
                                  color: Colors.grey[600],
                                  semanticLabel: 'Filtros'),
                              const SizedBox(width: 4),
                              Text(
                                '${config.filtros.length} filtros',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==============================
  // DIÁLOGOS EXPORTACIÓN
  // ==============================
  void _mostrarDialogoFormato(ReporteConfig config) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Semantics(
          label: 'Seleccionar formato',
          hint: 'Elige CSV o PDF para previsualizar antes de descargar.',
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: 'Indicador de arrastre',
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Tooltip(
                      message: 'Reporte: ${config.nombre}',
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: config.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(config.icono,
                            color: config.color,
                            semanticLabel: 'Reporte ${config.nombre}'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(config.nombre,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const Text(
                            'Selecciona el formato (con vista previa)',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Tooltip(
                      message: 'Cerrar',
                      child: Semantics(
                        button: true,
                        label: 'Cerrar',
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, semanticLabel: 'Cerrar'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: _buildFormatOption(
                        Icons.table_chart,
                        'CSV',
                        Colors.green,
                        () => _startExport(config, FormatoDescarga.csv),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFormatOption(
                        Icons.picture_as_pdf,
                        'PDF',
                        Colors.red,
                        () => _startExport(config, FormatoDescarga.pdf),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startExport(ReporteConfig config, FormatoDescarga formato) {
    Navigator.pop(context);
    _procesarReporte(config, formato);
  }

  Widget _buildFormatOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    final semLabel = 'Exportar en $label';
    final semHint = 'Genera el reporte, muestra vista previa y permite descargar';

    return Semantics(
      button: true,
      label: semLabel,
      hint: semHint,
      child: Tooltip(
        message: semLabel,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 32, semanticLabel: label),
                const SizedBox(height: 8),
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _procesarReporte(ReporteConfig config, FormatoDescarga formato) {
    if (config.filtros.isEmpty) {
      _generarReporte(config, formato, {});
    } else {
      showDialog(
        context: context,
        builder: (context) => _DialogoParametros(
          config: config,
          formato: formato,
          onGenerar: (parametros) => _generarReporte(config, formato, parametros),
          fetchEstudiantes: _fetchEstudiantes,
        ),
      );
    }
  }

  // ==============================
  // GENERAR REPORTE (FETCH BACK) + VISTA PREVIA
  // ==============================
  Future<void> _generarReporte(
    ReporteConfig config,
    FormatoDescarga formato,
    Map<String, dynamic> parametros,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Semantics(
          label: 'Cargando reporte',
          child: CircularProgressIndicator(),
        ),
      ),
    );

    try {
      final repo = _scope.reportes;
      Map<String, dynamic> data;

      switch (config.id) {
        case 'estado_cobros':
          data = await repo.estadoCobros(
            desde: parametros['desde'],
            hasta: parametros['hasta'],
            corte: parametros['corte'],
            diaVencimiento: parametros['diaVencimiento'],
          );
          break;
        case 'cuentas_cobrar':
          data = await repo.cuentasPorCobrar(
            corte: parametros['corte'],
            diaVencimiento: parametros['diaVencimiento'],
          );
          break;
        case 'historial_cliente':
          data = await repo.historialPagosCliente(
            idEstudiante: parametros['idEstudiante'],
            desde: parametros['desde'],
            hasta: parametros['hasta'],
            corte: parametros['corte'],
            diaVencimiento: parametros['diaVencimiento'],
          );
          break;
        case 'cobros_periodo':
          data = await repo.cobrosPorPeriodo(
            desde: parametros['desde'],
            hasta: parametros['hasta'],
            granularidad: parametros['granularidad'],
          );
          break;
        case 'morosidad':
          data = await repo.morosidad(
            corte: parametros['corte'],
            diaVencimiento: parametros['diaVencimiento'],
          );
          break;
        case 'metodos_pago':
          data = await repo.metodosPago(
            desde: parametros['desde'],
            hasta: parametros['hasta'],
          );
          break;
        case 'alertas':
          data = await repo.alertasRecordatorios(
            desde: parametros['desde'],
            hasta: parametros['hasta'],
            ventanaDias: parametros['ventanaDias'],
          );
          break;
        case 'consolidado':
          data = await repo.consolidadoGerencia(
            desde: parametros['desde'],
            hasta: parametros['hasta'],
            corte: parametros['corte'],
            diaVencimiento: parametros['diaVencimiento'],
          );
          break;
        case 'usuarios':
          data = await repo.usuariosResumen();
          break;
        case 'auditoria':
          data = await repo.auditoriaActividad(
            desde: parametros['desde'],
            hasta: parametros['hasta'],
            top: parametros['top'],
          );
          break;
        case 'estudiantes_resumen':
          data = await repo.estudiantesResumen();
          break;
        case 'asistencia':
          data = await repo.asistenciaResumen(
            desde: parametros['desde'],
            hasta: parametros['hasta'],
            idSubcategoria: parametros['idSubcategoria'],
          );
          break;
        case 'evaluaciones':
          data = await repo.evaluacionesResumen(
            desde: parametros['desde'],
            hasta: parametros['hasta'],
            top: parametros['top'],
          );
          break;
        default:
          throw Exception('Reporte no implementado');
      }

      // ENRIQUECE (solo donde aplica) para mejorar lógica/UX (Saldo/Período/Creado en)
      final enriched = _enrichReporteData(config.id, data);

      final cleanData = _sanitizeReporteData(enriched);

      // Genera bytes (una sola vez) para usar en vista previa + descarga.
      final generatedAt = DateTime.now();
      final export = await _buildExportBytes(
        config: config,
        formato: formato,
        data: cleanData,
        generatedAt: generatedAt,
      );

      if (!mounted) return;
      Navigator.pop(context); // cerrar loading

      final ok = await _mostrarVistaPrevia(
        config: config,
        formato: formato,
        data: cleanData,
        bytes: export.bytes,
        generatedAt: generatedAt,
      );

      if (ok != true) return;

      await _saveBytes(
        bytes: export.bytes,
        fileName: export.fileName,
        mimeType: export.mimeType,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Descarga completada'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // cerrar loading si estaba abierto
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==============================
  // VISTA PREVIA (ANTES DE DESCARGAR)
  // ==============================
  Future<bool?> _mostrarVistaPrevia({
    required ReporteConfig config,
    required FormatoDescarga formato,
    required Map<String, dynamic> data,
    required Uint8List bytes,
    required DateTime generatedAt,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final w = MediaQuery.of(ctx).size.width;
        final h = MediaQuery.of(ctx).size.height;

        final dialogWidth = w >= 1100 ? 980.0 : (w >= 800 ? 760.0 : w * 0.95);
        final dialogHeight = h >= 850 ? 720.0 : (h >= 650 ? 600.0 : h * 0.88);

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Row(
            children: [
              Icon(Icons.visibility,
                  color: config.color, semanticLabel: 'Vista previa'),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Vista previa • ${config.nombre}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Tooltip(
                message: 'Cerrar',
                child: IconButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  icon: const Icon(Icons.close, semanticLabel: 'Cerrar'),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: Column(
              children: [
                Row(
                  children: [
                    Chip(
                      label: Text(formato == FormatoDescarga.pdf ? 'PDF' : 'CSV'),
                      avatar: Icon(
                        formato == FormatoDescarga.pdf
                            ? Icons.picture_as_pdf
                            : Icons.table_chart,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(generatedAt)}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: formato == FormatoDescarga.pdf
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            color: Colors.grey[100],
                            child: PdfPreview(
                              build: (_) async => bytes,
                              canChangePageFormat: false,
                              canChangeOrientation: false,
                              allowPrinting: false,
                              allowSharing: false,
                              useActions: false,
                              pdfFileName:
                                  '${config.id}_${generatedAt.millisecondsSinceEpoch}.pdf',
                            ),
                          ),
                        )
                      : _buildPreviewCSVStructured(data),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: config.color),
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.download, semanticLabel: 'Descargar'),
              label: const Text('Descargar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreviewCSVStructured(Map<String, dynamic> data) {
    final kpis = <MapEntry<String, String>>[];
    final tables = <_PreviewTable>[];

    data.forEach((key, value) {
      if (value is List || value is Map) return;
      kpis.add(MapEntry(_humanizeKey(key), _formatValue(key, value)));
    });

    data.forEach((key, value) {
      if (value is List && value.isNotEmpty && value.first is Map) {
        final rows = value
            .whereType<Map>()
            .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
            .toList();
        if (rows.isEmpty) return;

        final headers = _orderHeaders(rows.first.keys.toList());
        final previewRows = rows.take(40).map((r) {
          return headers.map((h) => _formatValue(h, r[h])).toList();
        }).toList();

        tables.add(_PreviewTable(
          title: _humanizeKey(key),
          headers: headers.map(_humanizeKey).toList(),
          rows: previewRows,
          totalRows: rows.length,
        ));
      }
    });

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: Colors.grey[100],
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (kpis.isNotEmpty) ...[
              Text('Resumen',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: Colors.grey[800])),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: kpis.take(12).map((e) {
                      return SizedBox(
                        width: 240,
                        child: _KpiTile(label: e.key, value: e.value),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (tables.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No hay tablas para mostrar en la vista previa.',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              )
            else
              ...tables.map((t) => _PreviewTableCard(table: t)).toList(),
          ],
        ),
      ),
    );
  }

  // ==============================
  // ENRIQUECER DATA (UX/LÓGICA)
  // ==============================
  Map<String, dynamic> _enrichReporteData(String reportId, Map<String, dynamic> data) {
    switch (reportId) {
      case 'historial_cliente':
        return _enrichHistorialClienteData(data);
      default:
        return data;
    }
  }

  Map<String, dynamic> _enrichHistorialClienteData(Map<String, dynamic> data) {
    // Copia superficial del root
    final out = <String, dynamic>{...data};

    // intenta ubicar listas "pagos" y "mensualidades" incluso si vienen con otro casing
    final pagosKey = _findListKey(out, ['pagos']);
    final mensualidadesKey = _findListKey(out, ['mensualidades', 'mensualidad']);

    final pagosRaw = pagosKey == null ? null : out[pagosKey];
    final mensRaw = mensualidadesKey == null ? null : out[mensualidadesKey];

    final pagos = _listOfMap(pagosRaw);
    final mensualidades = _listOfMap(mensRaw);

    // 1) Mensualidades: agrega PERÍODO y normaliza "creado_en" si existe
    if (mensualidades.isNotEmpty) {
      final updated = mensualidades.map((row) {
        final r = <String, dynamic>{...row};

        final anio = _toIntAny(_pickCI(r, ['anio', 'año', 'year']));
        final mes = _toIntAny(_pickCI(r, ['mes', 'month']));
        final periodo = _periodoFrom(anio, mes);
        if (periodo != null) r['periodo'] = periodo;

        // mueve "valor" -> "valor_mensualidad" para que sea más claro
        final valor = _pickCI(r, ['valor']);
        if (valor != null) {
          r['valor_mensualidad'] = valor;
          _removeCI(r, ['valor']);
        }

        // si el backend manda creado_en / created_at / fecha_creacion, lo normalizamos a "creado_en"
        final creado = _pickCI(r, [
          'creado_en',
          'created_at',
          'fecha_creacion',
          'fecha_creación',
          'creadoen',
          'createdat',
        ]);
        if (creado != null) {
          r['creado_en'] = creado;
        }

        // ocultamos año/mes sueltos (ya queda por período)
        _removeCI(r, ['anio', 'año', 'year', 'mes', 'month']);

        return r;
      }).toList();

      out[mensualidadesKey ?? 'mensualidades'] = updated;
    }

    // 2) Pagos: reemplaza VALOR -> SALDO (acumulado) y agrega PERÍODO
    if (pagos.isNotEmpty) {
      // agrupar por mensualidad usando el mejor identificador disponible
      final groups = <String, List<Map<String, dynamic>>>{};

      for (final row in pagos) {
        final r = <String, dynamic>{...row};

        final idMens = _pickCI(r, ['id_mensualidad', 'idmensualidad', 'mensualidad_id', 'idMensualidad']);
        final anio = _toIntAny(_pickCI(r, ['anio', 'año', 'year']));
        final mes = _toIntAny(_pickCI(r, ['mes', 'month']));
        final valor = _toDoubleAny(_pickCI(r, ['valor', 'valor_mensualidad', 'monto', 'total'])) ?? 0.0;

        final key = idMens != null
            ? 'id:$idMens'
            : 'ym:${anio ?? '-'}-${mes ?? '-'}-v:${valor.toStringAsFixed(2)}';

        (groups[key] ??= []).add(r);
      }

      // calcular saldo acumulado por grupo (ordenado por fecha)
      final updatedAll = <Map<String, dynamic>>[];

      for (final entry in groups.entries) {
        final rows = entry.value;

        rows.sort((a, b) {
          final da = _parseDate(_pickCI(a, ['fecha_pago', 'fecha', 'fechaPago'])) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final db = _parseDate(_pickCI(b, ['fecha_pago', 'fecha', 'fechaPago'])) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return da.compareTo(db);
        });

        double acumulado = 0.0;
        for (final r in rows) {
          final valor = _toDoubleAny(_pickCI(r, ['valor', 'valor_mensualidad', 'monto', 'total'])) ?? 0.0;
          final pagado = _toDoubleAny(_pickCI(r, ['monto_pagado', 'montoPagado', 'pagado', 'abono'])) ?? 0.0;

          acumulado += pagado;
          final saldo = (valor - acumulado);
          r['saldo'] = saldo < 0 ? 0.0 : saldo;

          // agrega período y oculta año/mes
          final anio = _toIntAny(_pickCI(r, ['anio', 'año', 'year']));
          final mes = _toIntAny(_pickCI(r, ['mes', 'month']));
          final periodo = _periodoFrom(anio, mes);
          if (periodo != null) r['periodo'] = periodo;

          _removeCI(r, ['anio', 'año', 'year', 'mes', 'month']);

          // elimina "valor" para que no se vea (el usuario quiere Saldo)
          _removeCI(r, ['valor', 'valor_mensualidad']);

          updatedAll.add(r);
        }
      }

      out[pagosKey ?? 'pagos'] = updatedAll;
    }

    return out;
  }

  String? _findListKey(Map<String, dynamic> root, List<String> candidates) {
    // exact
    for (final c in candidates) {
      if (root.containsKey(c) && root[c] is List) return c;
    }
    // case-insensitive
    final lowerToReal = <String, String>{};
    for (final k in root.keys) {
      lowerToReal[k.toLowerCase()] = k;
    }
    for (final c in candidates) {
      final real = lowerToReal[c.toLowerCase()];
      if (real != null && root[real] is List) return real;
    }
    // fallback: busca lista que contenga maps y coincida por nombre parcial
    for (final k in root.keys) {
      final lk = k.toLowerCase();
      if (root[k] is List && candidates.any((c) => lk.contains(c.toLowerCase()))) {
        return k;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _listOfMap(dynamic v) {
    if (v is List) {
      return v
          .whereType<Map>()
          .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  dynamic _pickCI(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k)) return m[k];
    }
    final lowerToReal = <String, String>{};
    for (final k in m.keys) {
      lowerToReal[k.toString().toLowerCase()] = k.toString();
    }
    for (final k in keys) {
      final real = lowerToReal[k.toLowerCase()];
      if (real != null && m.containsKey(real)) return m[real];
    }
    return null;
  }

  void _removeCI(Map<String, dynamic> m, List<String> keys) {
    final target = keys.map((e) => e.toLowerCase()).toSet();
    final toRemove = <String>[];
    for (final k in m.keys) {
      if (target.contains(k.toString().toLowerCase())) {
        toRemove.add(k.toString());
      }
    }
    for (final k in toRemove) {
      m.remove(k);
    }
  }

  int? _toIntAny(dynamic v) {
    final d = _toDoubleAny(v);
    if (d == null) return null;
    return d.round();
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  String? _periodoFrom(int? anio, int? mes) {
    if (anio == null || mes == null) return null;
    if (mes < 1 || mes > 12) return '$anio';
    return '${_mesNombre(mes)} $anio';
  }

  String _mesNombre(int m) {
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
    if (m < 1 || m > 12) return m.toString();
    return meses[m];
  }

  // ==============================
  // SANITIZAR DATA (quita PARAMETROS e IDs)
  // ==============================
  Map<String, dynamic> _sanitizeReporteData(Map<String, dynamic> data) {
    final out = <String, dynamic>{};

    bool _isParamsKey(String k) {
      final low = k.trim().toLowerCase();
      return low == 'parametros' ||
          low == 'parametro' ||
          low == 'params' ||
          low == 'parameters' ||
          low == 'filtros' ||
          low == 'filters';
    }

    bool _isIdField(String k) {
      final low = k.trim().toLowerCase();
      return low == 'id' ||
          low.startsWith('id_') ||
          low.endsWith('_id') ||
          low == 'idusuario' ||
          low == 'idestudiante' ||
          low == 'idsubcategoria' ||
          low == 'idcategoria' ||
          low == 'idevaluacion' ||
          low == 'idpago' ||
          low == 'idmensualidad';
    }

    void walk(String prefix, dynamic v) {
      if (v == null) return;

      if (v is List) {
        if (v.isNotEmpty && v.first is Map) {
          final cleaned = v.whereType<Map>().map((m) {
            final cleanMap = <String, dynamic>{};
            m.forEach((k, vv) {
              final key = k.toString();
              if (!_isIdField(key)) {
                cleanMap[key] = vv;
              }
            });
            return cleanMap;
          }).toList();

          if (cleaned.isNotEmpty && cleaned.first.isNotEmpty) {
            out[prefix] = cleaned;
          }
        } else {
          out[prefix] = v.map((e) => e?.toString() ?? '').toList();
        }
        return;
      }

      if (v is Map) {
        for (final e in v.entries) {
          final k = e.key.toString();
          if (_isParamsKey(k) || _isIdField(k)) continue;
          final nextPrefix = prefix.isEmpty ? k : '$prefix.$k';
          walk(nextPrefix, e.value);
        }
        return;
      }

      if (!_isIdField(prefix)) {
        out[prefix] = v;
      }
    }

    for (final e in data.entries) {
      final k = e.key.toString();
      if (_isParamsKey(k) || _isIdField(k)) continue;
      walk(k, e.value);
    }

    return out;
  }

  // ==============================
  // SAVE BYTES (WEB + DESKTOP)
  // ==============================
  Future<void> _saveBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final file = XFile.fromData(bytes, name: fileName, mimeType: mimeType);

    if (kIsWeb) {
      await file.saveTo(fileName);
      return;
    }

    final loc = await getSaveLocation(suggestedName: fileName);
    if (loc == null) return;
    await file.saveTo(loc.path);
  }

  // ==============================
  // BUILD EXPORT BYTES
  // ==============================
  Future<_ExportBytes> _buildExportBytes({
    required ReporteConfig config,
    required FormatoDescarga formato,
    required Map<String, dynamic> data,
    required DateTime generatedAt,
  }) async {
    switch (formato) {
      case FormatoDescarga.csv:
        final csv = StringBuffer();
        csv.writeln('"${_csvEscape(config.nombre)}"');
        csv.writeln();
        _procesarDatosParaCSV(data, csv);
        final bytes = Uint8List.fromList(utf8.encode(csv.toString()));
        return _ExportBytes(
          bytes: bytes,
          fileName: '${config.id}_${generatedAt.millisecondsSinceEpoch}.csv',
          mimeType: 'text/csv',
        );

      case FormatoDescarga.pdf:
        final bytes = await _buildPdfBytes(config, data, generatedAt);
        return _ExportBytes(
          bytes: bytes,
          fileName: '${config.id}_${generatedAt.millisecondsSinceEpoch}.pdf',
          mimeType: 'application/pdf',
        );
    }
  }

  // ==============================
  // EXPORT: CSV
  // ==============================
  String _csvEscape(String v) => v.replaceAll('"', '""');

  void _procesarDatosParaCSV(Map<String, dynamic> data, StringBuffer csv) {
    data.forEach((key, value) {
      if (value is List) return;
      if (value is Map) return;
      csv.writeln(
          '"${_csvEscape(_humanizeKey(key))}","${_csvEscape(_formatValue(key, value))}"');
    });

    csv.writeln();

    data.forEach((key, value) {
      if (value is List && value.isNotEmpty && value.first is Map) {
        csv.writeln('"${_csvEscape(_humanizeKey(key))}"');
        final first = value.first as Map;
        final headers =
            _orderHeaders(first.keys.map((k) => k.toString()).toList());
        csv.writeln(headers
            .map((h) => '"${_csvEscape(_humanizeKey(h))}"')
            .join(','));

        for (final item in value) {
          final m = item as Map;
          final row = headers
              .map((h) => '"${_csvEscape(_formatValue(h, m[h]))}"')
              .join(',');
          csv.writeln(row);
        }
        csv.writeln();
      }
    });
  }

  // ==============================
  // EXPORT: PDF (PRODUCCIÓN)
  // ==============================
  final _fmtMoney = NumberFormat.currency(
    locale: 'es_EC',
    symbol: r'$',
    decimalDigits: 2,
  );
  final _fmtInt = NumberFormat('#,##0', 'es_EC');
  final _fmtNum2 = NumberFormat('#,##0.00', 'es_EC');
  final _fmtNum = NumberFormat('#,##0.##', 'es_EC');
  final _fmtDate = DateFormat('yyyy-MM-dd');

  static const Map<String, String> _labels = {
    'cedula': 'Cédula',
    'dni': 'Cédula',
    'documento': 'Documento',
    'identificacion': 'Identificación',

    'nombre': 'Nombre',
    'nombres': 'Nombres',
    'apellidos': 'Apellidos',
    'nombre_completo': 'Estudiante',
    'estudiante': 'Estudiante',
    'cliente': 'Cliente',
    'usuario': 'Usuario',
    'nombre_usuario': 'Usuario',

    'subcategoria': 'Subcategoría',
    'subcategorianombre': 'Subcategoría',
    'nombre_subcategoria': 'Subcategoría',
    'subcategoria_nombre': 'Subcategoría',

    'categoria': 'Categoría',
    'nombre_categoria': 'Categoría',

    'tipo': 'Tipo',
    'nivel': 'Nivel',
    'grado': 'Grado',
    'curso': 'Curso',

    'estado': 'Estado',
    'estado_pago': 'Estado de Pago',
    'estado_estudiante': 'Estado',
    'estado_mensualidad': 'Estado Mensualidad',

    'activo': 'Activo',

    'fecha': 'Fecha',
    'fecha_pago': 'Fecha de Pago',
    'fecha_registro': 'Fecha de Registro',
    'fecha_venc': 'Fecha de Vencimiento',
    'fecha_vencimiento': 'Fecha de Vencimiento',
    'fecha_ultimo_pago': 'Fecha Último Pago',
    'fecha_corte': 'Fecha de Corte',
    'fecha_inicio': 'Fecha de Inicio',
    'fecha_fin': 'Fecha de Fin',
    'desde': 'Desde',
    'hasta': 'Hasta',

    'periodo': 'Período',
    'mes': 'Mes',
    'anio': 'Año',
    'año': 'Año',

    'dias_mora': 'Días de Mora',
    'dias_vencido': 'Días Vencido',
    'dias_retraso': 'Días Retraso',
    'mora': 'Mora',
    'vencido': 'Vencido',
    'dia_vencimiento': 'Día de Vencimiento',

    'monto': 'Monto',
    'monto_pagado': 'Monto Pagado',
    'monto_pendiente': 'Monto Pendiente',
    'valor': 'Valor',
    'valor_mensualidad': 'Valor Mensualidad',
    'total': 'Total',
    'subtotal': 'Subtotal',
    'total_recaudado': 'Total Recaudado',
    'total_facturado': 'Total Facturado',
    'total_pendiente': 'Total Pendiente',
    'total_vencido': 'Total Vencido',

    'saldo': 'Saldo',
    'saldo_pendiente': 'Saldo Pendiente',
    'deuda': 'Deuda',

    'metodo_pago': 'Método de Pago',
    'metodo': 'Método',
    'forma_pago': 'Forma de Pago',
    'tipo_pago': 'Tipo de Pago',

    'cantidad': 'Cantidad',
    'cantidad_estudiantes': 'Cantidad de Estudiantes',
    'cantidad_pagos': 'Cantidad de Pagos',
    'total_estudiantes': 'Total Estudiantes',
    'total_pagos': 'Total de Pagos',

    'numero': 'Número',
    'count': 'Cantidad',
    'conteo': 'Conteo',
    'usuarios': 'Usuarios',

    'porcentaje': 'Porcentaje',
    'porcentaje_mora': 'Porcentaje de Mora',
    'porcentaje_cobro': 'Porcentaje de Cobro',
    'promedio': 'Promedio',

    'nota': 'Nota',
    'calificacion': 'Calificación',
    'ranking': 'Ranking',
    'posicion': 'Posición',

    'asistencias': 'Asistencias',
    'ausencias': 'Ausencias',
    'tardanzas': 'Tardanzas',
    'justificaciones': 'Justificaciones',

    'telefono': 'Teléfono',
    'celular': 'Celular',
    'email': 'Email',
    'correo': 'Correo Electrónico',
    'direccion': 'Dirección',

    'rol': 'Rol',
    'permisos': 'Permisos',
    'acciones': 'Acciones',
    'actividad': 'Actividad',
    'ultimo_acceso': 'Último Acceso',

    'creado_en': 'Creado en',
    'created_at': 'Creado en',
    'fecha_creacion': 'Fecha de Creación',

    'descripcion': 'Descripción',
    'observaciones': 'Observaciones',
    'comentario': 'Comentario',
    'notas': 'Notas',
    'detalle': 'Detalle',

    // tiempo/duración
    'tiempo': 'Tiempo',
    'duracion': 'Duración',
    'duración': 'Duración',
    'minutos': 'Minutos',
    'horas': 'Horas',
    'segundos': 'Segundos',
  };

  Future<Uint8List> _buildPdfBytes(
    ReporteConfig config,
    Map<String, dynamic> data,
    DateTime generatedAt,
  ) async {
    // data ya viene sanitizado/enriquecido desde _buildExportBytes
    final cleanData = data;

    final pdf = pw.Document();

    final primary = PdfColor.fromInt(0xFF0D47A1);
    final text = PdfColor.fromInt(0xFF1F2937);
    final muted = PdfColor.fromInt(0xFF6B7280);
    final line = PdfColor.fromInt(0xFFE5E7EB);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 32),
        header: (ctx) => _pdfHeader(config, generatedAt, primary, text, line),
        footer: (ctx) => _pdfFooter(ctx, muted, line),
        build: (ctx) {
          final widgets = <pw.Widget>[];

          final kpis = _extractKpis(cleanData);
          if (kpis.isNotEmpty) {
            widgets.add(_sectionTitle('Resumen ejecutivo', primary));
            widgets.add(pw.SizedBox(height: 10));
            widgets.add(_kpiCards(kpis, primary, text, line));
            widgets.add(pw.SizedBox(height: 18));
          }

          final tables = _extractTables(cleanData);
          if (tables.isNotEmpty) {
            for (final t in tables) {
              widgets.add(_sectionTitle(_humanizeKey(t.title), primary));
              widgets.add(pw.SizedBox(height: 8));
              widgets.add(_dataTable(t.headers, t.rows, primary, text, line));
              widgets.add(pw.SizedBox(height: 16));
            }
          }

          if (widgets.isEmpty) {
            widgets.add(pw.SizedBox(height: 30));
            widgets.add(
              pw.Center(
                child: pw.Text(
                  'No hay datos para mostrar.',
                  style: pw.TextStyle(fontSize: 12, color: muted),
                ),
              ),
            );
          }

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfHeader(
    ReporteConfig config,
    DateTime generatedAt,
    PdfColor primary,
    PdfColor text,
    PdfColor line,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              children: [
                pw.Container(
                  width: 34,
                  height: 34,
                  decoration: pw.BoxDecoration(
                    color: primary,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'PA',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Academia Porto Ambato',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: text,
                      ),
                    ),
                    pw.Text(
                      'Sistema de Cobros y Gestión',
                      style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Generado:',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(generatedAt),
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: text,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: pw.BoxDecoration(
            color: primary,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Text(
            config.nombre,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Container(height: 1, color: line),
        pw.SizedBox(height: 12),
      ],
    );
  }

  pw.Widget _pdfFooter(pw.Context ctx, PdfColor muted, PdfColor line) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: line)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Documento generado automáticamente',
            style: pw.TextStyle(fontSize: 8, color: muted),
          ),
          pw.Text(
            'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: muted),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String title, PdfColor primary) {
    return pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 16,
          decoration: pw.BoxDecoration(
            color: primary,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: primary,
          ),
        ),
      ],
    );
  }

  // ==============================
  // KPIs / TABLAS PDF
  // ==============================
  int _kpiRank(String key) {
    final k = key.toLowerCase();

    if (k.contains('total_recaudado') ||
        (k.contains('recaudado') && k.contains('total'))) return 0;
    if (k.contains('total_facturado') ||
        (k.contains('facturado') && k.contains('total'))) return 1;

    if (k.contains('total_pendiente') ||
        (k.contains('pendiente') && k.contains('total'))) return 2;
    if (k.contains('total_vencido') ||
        (k.contains('vencido') && k.contains('total'))) return 3;

    if (_isMoneyKey(k)) return 10;
    if (_isCountKey(k)) return 20;
    if (_isPercentKey(k)) return 30;
    if (_isDurationKey(k)) return 35;

    if (k.contains('fecha') ||
        k.contains('desde') ||
        k.contains('hasta') ||
        k.contains('corte')) return 40;

    if (k.startsWith('id_') || k == 'id') return 90;

    return 60;
  }

  Map<String, String> _extractKpis(Map<String, dynamic> data) {
    final entries = <MapEntry<String, String>>[];

    data.forEach((key, value) {
      if (value is List) return;
      if (value is Map) return;
      entries.add(MapEntry(key, _formatValue(key, value)));
    });

    entries.sort((a, b) {
      final ra = _kpiRank(a.key);
      final rb = _kpiRank(b.key);
      if (ra != rb) return ra.compareTo(rb);
      return _humanizeKey(a.key).compareTo(_humanizeKey(b.key));
    });

    final out = <String, String>{};
    for (final e in entries) {
      out[e.key] = e.value;
    }
    return out;
  }

  int _colRank(String header) {
    final h = header.toLowerCase();

    if (h.contains('periodo')) return 12;
    if (h.contains('creado')) return 18;

    if (h.contains('nombre') &&
        !h.contains('subcategoria') &&
        !h.contains('categoria')) return 0;
    if (h.contains('estudiante') || h.contains('cliente')) return 1;
    if (h.contains('apellido')) return 2;

    if (h.contains('cedula') || h.contains('dni') || h.contains('documento')) {
      return 5;
    }

    if (h.contains('categoria') && !h.contains('sub')) return 10;
    if (h.contains('subcategoria') || h.contains('subcategoría')) return 11;

    if (h.contains('fecha') && !h.contains('venc')) return 20;
    if (h.contains('venc') || h.contains('vencimiento')) return 21;

    if (h.contains('estado')) return 30;
    if (h.contains('dias') || h.contains('días') || h.contains('mora')) return 40;

    if (h.contains('monto_pagado') || h.contains('montopagado')) return 48;
    if (h.contains('saldo')) return 49;

    if (_isMoneyKey(h)) return 50;
    if (_isCountKey(h)) return 70;
    if (_isDurationKey(h)) return 75;
    if (_isPercentKey(h)) return 90;

    if (h.startsWith('id_') || h == 'id') return 999;

    return 80;
  }

  List<String> _orderHeaders(List<String> headers) {
    final list = List<String>.from(headers);
    list.sort((a, b) {
      final ra = _colRank(a);
      final rb = _colRank(b);
      if (ra != rb) return ra.compareTo(rb);
      return _humanizeKey(a).compareTo(_humanizeKey(b));
    });
    return list;
  }

  List<_PdfTableData> _extractTables(Map<String, dynamic> data) {
    final out = <_PdfTableData>[];

    data.forEach((key, value) {
      if (value is List && value.isNotEmpty && value.first is Map) {
        final rows = value
            .whereType<Map>()
            .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
            .toList();
        if (rows.isEmpty) return;

        final headers = _orderHeaders(rows.first.keys.toList());

        final tableRows = rows.map((r) {
          return headers.map((h) => _formatValue(h, r[h])).toList();
        }).toList();

        out.add(_PdfTableData(title: key, headers: headers, rows: tableRows));
      }
    });

    return out;
  }

  pw.Widget _kpiCards(
    Map<String, String> kpis,
    PdfColor primary,
    PdfColor text,
    PdfColor line,
  ) {
    final entries = kpis.entries.toList();

    return pw.Wrap(
      spacing: 10,
      runSpacing: 10,
      children: entries.map((e) {
        return pw.Container(
          width: 170,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: line),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _humanizeKey(e.key),
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                e.value,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: text,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _dataTable(
    List<String> headers,
    List<List<String>> rows,
    PdfColor primary,
    PdfColor text,
    PdfColor line,
  ) {
    final alignments = <int, pw.Alignment>{};
    for (var i = 0; i < headers.length; i++) {
      final h = headers[i];
      if (_looksNumericColumn(h, rows, i)) {
        alignments[i] = pw.Alignment.centerRight;
      } else {
        alignments[i] = pw.Alignment.centerLeft;
      }
    }

    final manyColumns = headers.length >= 9;
    final cellFont = manyColumns ? 6.5 : 8.0;
    final headerFont = manyColumns ? 7.0 : 9.0;
    final padding = manyColumns
        ? const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3)
        : const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4);

    return pw.Table.fromTextArray(
      headers: headers.map(_humanizeKey).toList(),
      data: rows,
      border: pw.TableBorder.all(color: line, width: 0.6),
      headerDecoration: pw.BoxDecoration(color: primary),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: headerFont,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(
        fontSize: cellFont,
        color: text,
      ),
      headerAlignments: alignments,
      cellAlignments: alignments,
      cellPadding: padding,
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    );
  }

  bool _looksNumericColumn(String header, List<List<String>> rows, int idx) {
    final h = header.toLowerCase();
    final hint = _isMoneyKey(h) ||
        _isCountKey(h) ||
        _isPercentKey(h) ||
        _isDurationKey(h) ||
        h.contains('dias') ||
        h.contains('días') ||
        h.contains('mora');

    var numericCount = 0;
    var sample = 0;
    for (final r in rows.take(12)) {
      if (idx >= r.length) continue;
      final v = r[idx]
          .replaceAll('.', '')
          .replaceAll(',', '')
          .replaceAll(r'$', '')
          .replaceAll('%', '')
          .trim();
      if (v.isEmpty) continue;
      sample++;
      if (double.tryParse(v) != null) numericCount++;
    }
    final looks = sample > 0 && (numericCount / sample) >= 0.6;
    return hint || looks;
  }

  // ==============================
  // FORMATEO ROBUSTO (DINERO / ENTERO / % / TIEMPO)
  // ==============================
  double? _toDoubleAny(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();

    if (v is String) {
      var s = v.trim();
      if (s.isEmpty) return null;

      // Normaliza: quita $, %, etc.
      s = s.replaceAll(r'$', '').replaceAll('%', '').trim();

      final hasComma = s.contains(',');
      final hasDot = s.contains('.');

      if (hasComma && hasDot) {
        // "1,234.56" => "1234.56"
        s = s.replaceAll(',', '');
      } else if (hasComma && !hasDot) {
        // "1234,56" => "1234.56"
        s = s.replaceAll(',', '.');
      }

      return double.tryParse(s);
    }

    return null;
  }

  bool _isPercentKey(String key) {
    final k = key.toLowerCase();
    return k.contains('porcentaje') ||
        k.contains('%') ||
        k.contains('ratio') ||
        k.contains('tasa');
  }

  bool _isCountKey(String key) {
  final k = key.toLowerCase();

  // ✅ Cualquier métrica que sea "clientes" normalmente es CONTEO (no dinero),
  // salvo que explícitamente diga monto/valor/saldo/deuda.
  final hasClientes = k.contains('cliente') || k.contains('clientes');
  final hasMoneyHints = k.contains('monto') ||
      k.contains('valor') ||
      k.contains('saldo') ||
      k.contains('deuda') ||
      k.contains('recaudado') ||
      k.contains('facturado') ||
      k.contains('pagado') ||
      k.contains('subtotal');

  if (hasClientes && !hasMoneyHints && !_isPercentKey(k) && !_isDurationKey(k)) {
    return true; // ejemplo: total_clientes_activos, clientes_morosos
  }
  // ✅ Eventos / auditoría: siempre es CONTEO (no dinero)
  final hasEventos = k.contains('evento') || k.contains('eventos');
  final hasAcciones = k.contains('accion') || k.contains('acciones');

  if ((hasEventos || hasAcciones) &&
      !hasMoneyHints &&
      !_isPercentKey(k) &&
      !_isDurationKey(k)) {
    return true; // ejemplo: total_eventos, total_acciones, eventos_totales
  }

  // caso especial: "total_mensualidades" NO es dinero
  if (k.contains('mensualidad') &&
      !(k.contains('monto') ||
          k.contains('valor') ||
          k.contains('saldo') ||
          k.contains('deuda')) &&
      (k.contains('total') ||
          k.contains('cantidad') ||
          k.contains('conteo') ||
          k.contains('count'))) {
    return true;
  }

  // usuarios
  if (k == 'usuarios' || k.contains('usuario') || k.contains('usuarios')) {
    // total_usuarios, usuarios_activos, etc.
    if (!hasMoneyHints && !_isPercentKey(k) && !_isDurationKey(k)) return true;
  }

  return k.contains('cantidad') ||
      k.contains('conteo') ||
      k.contains('count') ||
      k.contains('numero') ||
      k.contains('número') ||
      k.contains('total_estudiantes') ||
      k.contains('total_pagos') ||
      k.contains('cantidad_estudiantes') ||
      k.contains('cantidad_pagos');
}


  bool _isMoneyKey(String key) {
    final k = key.toLowerCase();

    // evita chocar con conteos/porcentajes/tiempos
    if (_isCountKey(k) || _isPercentKey(k) || _isDurationKey(k)) return false;

    return k.contains('monto') ||
        k.contains('valor') ||
        k.contains('saldo') ||
        k.contains('deuda') ||
        k.contains('recaudado') ||
        k.contains('facturado') ||
        k.contains('pagado') ||
        // totales financieros típicos:
        (k.contains('total') &&
            !k.contains('total_estudiantes') &&
            !k.contains('total_pagos')) ||
        k.contains('subtotal');
  }

  bool _isDurationKey(String key) {
    final k = key.toLowerCase().trim();
    if (k.contains('min') || k.contains('minuto')) return true;
    if (k.contains('hora') || k.contains('hr') || k.contains('hrs')) return true;
    if (k.contains('seg') || k.contains('segundo')) return true;

    if (k.contains('duracion') || k.contains('duración')) return true;
    if (k.contains('tiempo')) return true;

    return false;
  }

  bool _isYearKey(String key) {
    final k = key.toLowerCase().trim();
    return k == 'anio' ||
        k == 'año' ||
        k.endsWith('_anio') ||
        k.endsWith('_año') ||
        k.contains('anio') ||
        k.contains('año') ||
        k.contains('year');
  }

  bool _isMonthKey(String key) {
    final k = key.toLowerCase().trim();
    return k == 'mes' ||
        k.endsWith('_mes') ||
        k.contains('mes') ||
        k.contains('month');
  }

  String _formatDuration(String key, double value) {
    final k = key.toLowerCase().trim();

    // unidad por nombre del campo
    String unit;
    if (k.contains('hora') || k.contains('hr') || k.contains('hrs')) {
      unit = 'h';
    } else if (k.contains('seg') || k.contains('segundo')) {
      unit = 's';
    } else {
      unit = 'min';
    }

    int asInt = value.round();

    if (unit == 's') {
      if (asInt >= 3600) {
        final h = asInt ~/ 3600;
        final rem = asInt % 3600;
        final m = rem ~/ 60;
        return m > 0 ? '$h h $m min' : '$h h';
      }
      if (asInt >= 60) {
        final m = asInt ~/ 60;
        final s = asInt % 60;
        return s > 0 ? '$m min $s s' : '$m min';
      }
      return '$asInt s';
    }

    if (unit == 'min') {
      if (asInt >= 60) {
        final h = asInt ~/ 60;
        final m = asInt % 60;
        return m > 0 ? '$h h $m min' : '$h h';
      }
      return '$asInt min';
    }

    // unit == 'h'
    if ((value - value.round()).abs() < 0.0001) {
      return '${value.round()} h';
    }
    // horas decimales
    return '${_fmtNum2.format(value)} h';
  }

  String _formatPercent(String key, double value) {
    // Si viene como fracción (0.31) => 31.00%
    final v = (value >= 0 && value <= 1) ? value * 100 : value;
    return '${_fmtNum2.format(v)}%';
  }

  String _formatMonth(dynamic v) {
    final n = _toIntAny(v);
    if (n == null) return v?.toString() ?? '-';
    if (n >= 1 && n <= 12) return _mesNombre(n);
    return n.toString();
  }

  String _formatYear(dynamic v) {
    final n = _toIntAny(v);
    if (n == null) return v?.toString() ?? '-';
    return n.toString(); // sin separador de miles
  }

  String _formatValue(String key, dynamic value) {
    if (value == null) return '-';

    if (value is DateTime) return _fmtDate.format(value);

    final k = key.toLowerCase();

    // Si viene como String, intentamos parsear para formateo correcto (dinero/%/tiempo/entero)
    if (value is String) {
      final s = value.trim();
      if (s.isEmpty) return '-';

      // fechas ISO
      final dt = DateTime.tryParse(s);
      if (dt != null) return _fmtDate.format(dt);

      // año/mes aunque vengan como string
      final num = _toDoubleAny(s);
      if (num != null) {
        if (_isYearKey(k)) return _formatYear(num);
        if (_isMonthKey(k)) return _formatMonth(num);

        if (_isPercentKey(k)) return _formatPercent(k, num);
        if (_isDurationKey(k)) return _formatDuration(k, num);
        if (_isCountKey(k)) return _fmtInt.format(num.round());
        if (_isMoneyKey(k)) return _fmtMoney.format(num);

        if ((num - num.round()).abs() < 0.0001) return _fmtInt.format(num.round());
        return _fmtNum.format(num);
      }

      // si ya viene como "20$" y NO se pudo parsear arriba (raro), lo limpiamos
      return s.replaceAll(r'$', '').trim();
    }

    if (value is num) {
      if (_isYearKey(k)) return _formatYear(value);
      if (_isMonthKey(k)) return _formatMonth(value);

      if (_isPercentKey(k)) return _formatPercent(k, value.toDouble());
      if (_isDurationKey(k)) return _formatDuration(k, value.toDouble());
      if (_isCountKey(k)) return _fmtInt.format(value.round());
      if (_isMoneyKey(k)) return _fmtMoney.format(value);

      if ((value.toDouble() - value.roundToDouble()).abs() < 0.0001) {
        return _fmtInt.format(value.round());
      }
      return _fmtNum.format(value);
    }

    if (value is bool) return value ? 'Sí' : 'No';
    if (value is Map) return '-';

    return value.toString();
  }

  String _humanizeKey(String key) {
    var raw = key.trim();
    if (raw.isEmpty) return raw;

    // si viene como "resumen.total_mensualidades" => toma el último segmento
    if (raw.contains('.')) {
      raw = raw.split('.').last.trim();
    }

    final low = raw.toLowerCase();
    if (_labels.containsKey(low)) return _labels[low]!;

    var s = raw.replaceAll('_', ' ').replaceAll('.', ' ');
    s = s.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m[1]} ${m[2]}',
    );

    final parts = s.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    return parts
        .map((p) => p.length == 1
            ? p.toUpperCase()
            : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
        .join(' ');
  }
}

// ======================================================================
// MODELOS
// ======================================================================
enum FormatoDescarga { csv, pdf }

enum FiltroTipo {
  rangoRequerido,
  rangoOpcional,
  fechaCorte,
  diaVencimiento,
  granularidad,
  idEstudiante,
  ventanaDias,
  top,
  idSubcategoria,
}

class ReporteConfig {
  final String id;
  final String categoria;
  final String nombre;
  final String descripcion;
  final IconData icono;
  final Color color;
  final List<FiltroTipo> filtros;

  const ReporteConfig({
    required this.id,
    required this.categoria,
    required this.nombre,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.filtros,
  });
}

class EstudianteOption {
  final int id;
  final String nombreCompleto;
  final String? subcategoria;
  final String? cedula;

  const EstudianteOption({
    required this.id,
    required this.nombreCompleto,
    this.subcategoria,
    this.cedula,
  });

  String get label {
    final parts = <String>[nombreCompleto];

    final sub = (subcategoria == null || subcategoria!.trim().isEmpty)
        ? null
        : subcategoria!.trim();

    final ced = (cedula == null || cedula!.trim().isEmpty) ? null : cedula!.trim();

    if (sub != null) parts.add(sub);
    if (ced != null) parts.add('Cédula: $ced');

    return parts.join(' • ');
  }

  static EstudianteOption fromMap(Map<String, dynamic> m) {
    final id = int.tryParse(
            '${m['id_estudiante'] ?? m['id'] ?? m['idEstudiante'] ?? ''}') ??
        0;

    final nombres = (m['nombres'] ?? m['nombre'] ?? '').toString().trim();
    final apellidos = (m['apellidos'] ?? '').toString().trim();
    final full = ('$nombres $apellidos').trim();
    final nombreCompleto = full.isEmpty ? 'Estudiante #$id' : full;

    final sub = (m['subcategoriaNombre'] ??
            m['subcategoria'] ??
            m['nombre_subcategoria'] ??
            m['subcategoria_nombre'])
        ?.toString()
        .trim();

    final ced = (m['cedula'] ?? m['dni'] ?? m['documento'])?.toString().trim();

    return EstudianteOption(
      id: id,
      nombreCompleto: nombreCompleto,
      subcategoria: (sub == null || sub.isEmpty) ? null : sub,
      cedula: (ced == null || ced.isEmpty) ? null : ced,
    );
  }
}

class _PdfTableData {
  final String title;
  final List<String> headers;
  final List<List<String>> rows;

  const _PdfTableData({
    required this.title,
    required this.headers,
    required this.rows,
  });
}

class _ExportBytes {
  final Uint8List bytes;
  final String fileName;
  final String mimeType;

  const _ExportBytes({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });
}

// ======================================================================
// VISTA PREVIA CSV (UI)
// ======================================================================
class _KpiTile extends StatelessWidget {
  final String label;
  final String value;

  const _KpiTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[900])),
        ],
      ),
    );
  }
}

class _PreviewTable {
  final String title;
  final List<String> headers;
  final List<List<String>> rows;
  final int totalRows;

  const _PreviewTable({
    required this.title,
    required this.headers,
    required this.rows,
    required this.totalRows,
  });
}

class _PreviewTableCard extends StatelessWidget {
  final _PreviewTable table;

  const _PreviewTableCard({required this.table});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(
                  table.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${table.rows.length} / ${table.totalRows}',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ]),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: table.headers
                    .map((h) => DataColumn(label: Text(h)))
                    .toList(),
                rows: table.rows.map((r) {
                  return DataRow(
                    cells: r.map((c) => DataCell(Text(c))).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// DIÁLOGO PARÁMETROS
// ======================================================================
class _DialogoParametros extends StatefulWidget {
  final ReporteConfig config;
  final FormatoDescarga formato;
  final Function(Map<String, dynamic>) onGenerar;
  final Future<List<EstudianteOption>> Function(String search)? fetchEstudiantes;

  const _DialogoParametros({
    required this.config,
    required this.formato,
    required this.onGenerar,
    required this.fetchEstudiantes,
  });

  @override
  State<_DialogoParametros> createState() => _DialogoParametrosState();
}

class _DialogoParametrosState extends State<_DialogoParametros> {
  final _formKey = GlobalKey<FormState>();
  final _fmtDate = DateFormat('yyyy-MM-dd');

  DateTimeRange? _rango;
  DateTime _corte = DateTime.now();
  int _diaVenc = 5;
  String _granularidad = 'mes';

  int? _idEstudiante;
  EstudianteOption? _estudianteSeleccionado;

  int _ventanaDias = 14;
  int _top = 10;
  int? _idSubcategoria;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Parámetros del reporte',
      hint:
          'Completa los filtros requeridos y toca Previsualizar para generar la vista previa.',
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Tooltip(
              message: 'Filtros del reporte',
              child: Icon(Icons.tune,
                  color: widget.config.color, semanticLabel: 'Filtros'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(widget.config.nombre,
                  style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.config.filtros.map((f) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildCampoFiltro(f),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        actions: [
          Tooltip(
            message: 'Cancelar',
            child: Semantics(
              button: true,
              label: 'Cancelar',
              hint: 'Cierra el diálogo sin generar',
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ),
          Tooltip(
            message: 'Previsualizar',
            child: Semantics(
              button: true,
              label: 'Previsualizar reporte',
              hint: 'Valida los filtros y genera la vista previa',
              child: FilledButton.icon(
                onPressed: _validarYGenerar,
                style:
                    FilledButton.styleFrom(backgroundColor: widget.config.color),
                icon: const Icon(Icons.visibility,
                    semanticLabel: 'Vista previa'),
                label: const Text('Previsualizar'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoFiltro(FiltroTipo tipo) {
    switch (tipo) {
      case FiltroTipo.rangoRequerido:
        return _buildRango(true);
      case FiltroTipo.rangoOpcional:
        return _buildRango(false);
      case FiltroTipo.fechaCorte:
        return _buildFechaCorte();
      case FiltroTipo.diaVencimiento:
        return _buildDiaVencimiento();
      case FiltroTipo.granularidad:
        return _buildGranularidad();
      case FiltroTipo.idEstudiante:
        return _buildSelectorEstudiante();
      case FiltroTipo.ventanaDias:
        return _buildVentanaDias();
      case FiltroTipo.top:
        return _buildTop();
      case FiltroTipo.idSubcategoria:
        return _buildIdSubcategoria();
    }
  }

  Widget _buildRango(bool requerido) {
    final rangoTxt = _rango == null
        ? 'Toca para seleccionar'
        : '${_fmtDate.format(_rango!.start)} → ${_fmtDate.format(_rango!.end)}';

    final label = 'Rango de fechas${requerido ? " requerido" : " opcional"}';

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        hint: 'Toca para seleccionar un rango de fechas',
        child: InkWell(
          onTap: _pickRango,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Rango de fechas${requerido ? " *" : " (opcional)"}',
              border: const OutlineInputBorder(),
              prefixIcon:
                  const Icon(Icons.calendar_month, semanticLabel: 'Calendario'),
              helperText: requerido ? 'Obligatorio para este reporte' : null,
            ),
            child: Text(
              rangoTxt,
              style: TextStyle(color: _rango == null ? Colors.grey : null),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFechaCorte() {
    return Tooltip(
      message: 'Fecha de corte',
      child: Semantics(
        button: true,
        label: 'Fecha de corte requerida',
        hint: 'Toca para seleccionar la fecha de corte',
        child: InkWell(
          onTap: _pickCorte,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Fecha de corte *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.event, semanticLabel: 'Fecha'),
              helperText: 'Referencia para cálculos del reporte',
            ),
            child: Text(_fmtDate.format(_corte)),
          ),
        ),
      ),
    );
  }

  Widget _buildDiaVencimiento() {
    return Tooltip(
      message: 'Día de vencimiento',
      child: Semantics(
        textField: true,
        label: 'Día de vencimiento requerido',
        hint: 'Ingresa un número entre 1 y 28',
        child: TextFormField(
          initialValue: '$_diaVenc',
          decoration: const InputDecoration(
            labelText: 'Día de vencimiento *',
            hintText: '1-28',
            border: OutlineInputBorder(),
            prefixIcon:
                Icon(Icons.event_available, semanticLabel: 'Vencimiento'),
            helperText: 'Define cuándo vence una mensualidad',
          ),
          keyboardType: TextInputType.number,
          validator: (v) {
            final n = int.tryParse(v ?? '');
            if (n == null || n < 1 || n > 28) return 'Entre 1 y 28';
            return null;
          },
          onChanged: (v) {
            final n = int.tryParse(v);
            if (n != null) _diaVenc = n.clamp(1, 28);
          },
        ),
      ),
    );
  }

  Widget _buildGranularidad() {
    return Tooltip(
      message: 'Granularidad',
      child: Semantics(
        label: 'Granularidad requerida',
        hint: 'Selecciona el nivel de agrupación del reporte',
        child: DropdownButtonFormField<String>(
          value: _granularidad,
          decoration: const InputDecoration(
            labelText: 'Granularidad *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.view_week, semanticLabel: 'Agrupar'),
            helperText: 'Define agrupación temporal',
          ),
          items: const [
            DropdownMenuItem(value: 'dia', child: Text('Diario')),
            DropdownMenuItem(value: 'semana', child: Text('Semanal')),
            DropdownMenuItem(value: 'mes', child: Text('Mensual')),
            DropdownMenuItem(value: 'anio', child: Text('Anual')),
          ],
          onChanged: (v) => setState(() => _granularidad = v ?? 'mes'),
        ),
      ),
    );
  }

  Widget _buildSelectorEstudiante() {
    return Tooltip(
      message: 'Seleccionar estudiante',
      child: Semantics(
        button: true,
        label: 'Seleccionar estudiante requerido',
        hint: 'Toca para buscar y seleccionar un estudiante',
        child: FormField<int>(
          validator: (_) {
            if (_idEstudiante == null || _idEstudiante! <= 0) {
              return 'Selecciona un estudiante';
            }
            return null;
          },
          builder: (state) {
            return InkWell(
              onTap: () async {
                final selected = await showDialog<EstudianteOption>(
                  context: context,
                  builder: (ctx) => _EstudiantePickerDialog(
                    fetch: widget.fetchEstudiantes,
                    selectedId: _idEstudiante,
                  ),
                );

                if (selected != null) {
                  setState(() {
                    _idEstudiante = selected.id;
                    _estudianteSeleccionado = selected;
                  });
                  state.didChange(_idEstudiante);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Estudiante *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person_search,
                      semanticLabel: 'Estudiante'),
                  errorText: state.errorText,
                  helperText: 'Toca para buscar y seleccionar',
                ),
                child: Text(
                  _estudianteSeleccionado?.label ?? 'Seleccionar estudiante',
                  style: TextStyle(
                    color: _estudianteSeleccionado == null ? Colors.grey : null,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVentanaDias() {
    return Tooltip(
      message: 'Ventana de días',
      child: Semantics(
        textField: true,
        label: 'Ventana de días requerida',
        hint: 'Ingresa un número entre 1 y 365',
        child: TextFormField(
          initialValue: '$_ventanaDias',
          decoration: const InputDecoration(
            labelText: 'Ventana de días *',
            hintText: '1-365',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.timelapse, semanticLabel: 'Días'),
            helperText: 'Rango para análisis de alertas/recordatorios',
          ),
          keyboardType: TextInputType.number,
          validator: (v) {
            final n = int.tryParse(v ?? '');
            if (n == null || n < 1 || n > 365) return 'Entre 1 y 365';
            return null;
          },
          onChanged: (v) {
            final n = int.tryParse(v);
            if (n != null) _ventanaDias = n.clamp(1, 365);
          },
        ),
      ),
    );
  }

  Widget _buildTop() {
    return Tooltip(
      message: 'Top registros',
      child: Semantics(
        textField: true,
        label: 'Top registros requerido',
        hint: 'Ingresa un número entre 1 y 100',
        child: TextFormField(
          initialValue: '$_top',
          decoration: const InputDecoration(
            labelText: 'Top registros *',
            hintText: '1-100',
            border: OutlineInputBorder(),
            prefixIcon:
                Icon(Icons.format_list_numbered, semanticLabel: 'Top'),
            helperText: 'Máximo de registros a incluir',
          ),
          keyboardType: TextInputType.number,
          validator: (v) {
            final n = int.tryParse(v ?? '');
            if (n == null || n < 1 || n > 100) return 'Entre 1 y 100';
            return null;
          },
          onChanged: (v) {
            final n = int.tryParse(v);
            if (n != null) _top = n.clamp(1, 100);
          },
        ),
      ),
    );
  }

  Widget _buildIdSubcategoria() {
    return Tooltip(
      message: 'ID Subcategoría',
      child: Semantics(
        textField: true,
        label: 'ID de subcategoría opcional',
        hint: 'Deja vacío para incluir todas las subcategorías',
        child: TextFormField(
          initialValue: _idSubcategoria?.toString() ?? '',
          decoration: const InputDecoration(
            labelText: 'ID Subcategoría (opcional)',
            hintText: 'Todas si está vacío',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category, semanticLabel: 'Subcategoría'),
            helperText: 'Filtra por una subcategoría específica',
          ),
          keyboardType: TextInputType.number,
          onChanged: (v) => _idSubcategoria = int.tryParse(v),
        ),
      ),
    );
  }

  Future<void> _pickRango() async {
    final now = DateTime.now();
    final initial = _rango ??
        DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );

    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initial,
      helpText: 'Seleccionar rango de fechas',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
    );

    if (r != null) setState(() => _rango = r);
  }

  Future<void> _pickCorte() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _corte,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      helpText: 'Seleccionar fecha de corte',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
    );
    if (d != null) setState(() => _corte = d);
  }

  void _validarYGenerar() {
    if (widget.config.filtros.contains(FiltroTipo.rangoRequerido) &&
        _rango == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar un rango de fechas'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final parametros = <String, dynamic>{
        if (_rango != null) 'desde': _rango!.start,
        if (_rango != null) 'hasta': _rango!.end,
        'corte': _corte,
        'diaVencimiento': _diaVenc,
        'granularidad': _granularidad,
        if (_idEstudiante != null) 'idEstudiante': _idEstudiante,
        'ventanaDias': _ventanaDias,
        'top': _top,
        if (_idSubcategoria != null) 'idSubcategoria': _idSubcategoria,
      };

      Navigator.pop(context);
      widget.onGenerar(parametros);
    }
  }
}

// ======================================================================
// DIÁLOGO SELECTOR ESTUDIANTE
// ======================================================================
class _EstudiantePickerDialog extends StatefulWidget {
  final Future<List<EstudianteOption>> Function(String search)? fetch;
  final int? selectedId;

  const _EstudiantePickerDialog({
    required this.fetch,
    required this.selectedId,
  });

  @override
  State<_EstudiantePickerDialog> createState() => _EstudiantePickerDialogState();
}

class _EstudiantePickerDialogState extends State<_EstudiantePickerDialog> {
  final _controller = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  String _error = '';
  List<EstudianteOption> _items = [];

  @override
  void initState() {
    super.initState();
    _load('');
    _controller.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), () {
        _load(_controller.text);
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load(String q) async {
    final qq = q.trim();
    if (qq.isNotEmpty && qq.length < 2) {
      setState(() {
        _items = [];
        _loading = false;
        _error = 'Escribe al menos 2 letras para buscar.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final fetch = widget.fetch;
      if (fetch == null) {
        if (!mounted) return;
        setState(() {
          _items = [];
          _loading = false;
          _error = 'No hay fuente de estudiantes configurada.';
        });
        return;
      }

      final res = await fetch(q);
      if (!mounted) return;
      setState(() {
        _items = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _loading = false;
        _error = 'Error al cargar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Selector de estudiante',
      hint: 'Busca por nombre y selecciona un estudiante de la lista.',
      child: AlertDialog(
        title: Row(
          children: [
            const Expanded(child: Text('Seleccionar estudiante')),
            Tooltip(
              message: 'Cerrar',
              child: Semantics(
                button: true,
                label: 'Cerrar selector',
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, semanticLabel: 'Cerrar'),
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                textField: true,
                label: 'Buscar estudiante',
                hint: 'Escribe al menos 2 letras para buscar',
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, semanticLabel: 'Buscar'),
                    hintText: 'Buscar por nombre...',
                    labelText: 'Buscar estudiante',
                    border: OutlineInputBorder(),
                    helperText: 'Ej. Juan, Pedro, María',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 360,
                child: _loading
                    ? Center(
                        child: Semantics(
                          label: 'Cargando estudiantes',
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _error.isNotEmpty
                        ? Center(
                            child: Text(
                              _error,
                              style: TextStyle(color: Colors.red[700]),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : _items.isEmpty
                            ? const Center(
                                child: Text('No se encontraron estudiantes.'),
                              )
                            : Semantics(
                                label: 'Lista de estudiantes',
                                child: ListView.separated(
                                  itemCount: _items.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final it = _items[index];
                                    final selected =
                                        (widget.selectedId == it.id);

                                    final ced = (it.cedula == null ||
                                            it.cedula!.trim().isEmpty)
                                        ? 'Cédula: -'
                                        : 'Cédula: ${it.cedula}';

                                    final sub = (it.subcategoria == null ||
                                            it.subcategoria!.trim().isEmpty)
                                        ? null
                                        : it.subcategoria!.trim();

                                    final semLabel = [
                                      it.nombreCompleto,
                                      if (sub != null) 'Subcategoría $sub',
                                      ced,
                                      if (selected) 'Seleccionado'
                                    ].join('. ');

                                    return Semantics(
                                      button: true,
                                      selected: selected,
                                      label: semLabel,
                                      hint: 'Toca para seleccionar',
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          child: Text(
                                            it.nombreCompleto.isNotEmpty
                                                ? it.nombreCompleto
                                                    .characters.first
                                                    .toUpperCase()
                                                : '#',
                                          ),
                                        ),
                                        title: Text(it.nombreCompleto),
                                        subtitle: Text(
                                          sub == null ? ced : '$sub • $ced',
                                        ),
                                        trailing: selected
                                            ? const Icon(Icons.check_circle,
                                                color: Colors.green,
                                                semanticLabel: 'Seleccionado')
                                            : null,
                                        onTap: () => Navigator.pop(context, it),
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
        actions: [
          Tooltip(
            message: 'Cerrar',
            child: Semantics(
              button: true,
              label: 'Cerrar',
              hint: 'Cierra el selector sin seleccionar',
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
