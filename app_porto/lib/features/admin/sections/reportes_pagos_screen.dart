// lib/features/admin/sections/reportes_pagos_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:app_porto/app/app_scope.dart';

import 'package:excel/excel.dart' as xls;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:file_selector/file_selector.dart';
import 'package:cross_file/cross_file.dart';

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
                          'Explora por categoría. Toca un reporte para seleccionar el formato de descarga.',
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
                                        child:
                                            Divider(color: Colors.grey[300]),
                                      ),
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
            Icon(
              Icons.folder_off_outlined,
              size: 80,
              color: Colors.grey[300],
              semanticLabel: 'Sin resultados',
            ),
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
          'Busca reportes por nombre, descripción o categoría. Luego selecciona un reporte para descargarlo.',
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
                        'Genera, visualiza y exporta métricas clave del sistema.',
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
                  prefixIcon: const Icon(
                    Icons.search,
                    semanticLabel: 'Buscar',
                  ),
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
        'Toca para seleccionar el formato (CSV, Excel o PDF) y descargar.';

    return Semantics(
      button: true,
      label: semanticsLabel,
      hint: semanticsHint,
      child: Tooltip(
        message: 'Descargar reporte: ${config.nombre}',
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
                      message: 'Este reporte tiene ${config.filtros.length} filtros',
                      child: Semantics(
                        label:
                            'Cantidad de filtros: ${config.filtros.length}',
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
                              Icon(
                                Icons.tune,
                                size: 12,
                                color: Colors.grey[600],
                                semanticLabel: 'Filtros',
                              ),
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
          label: 'Seleccionar formato de descarga',
          hint:
              'Elige CSV, Excel o PDF para descargar el reporte seleccionado.',
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
                        child: Icon(
                          config.icono,
                          color: config.color,
                          semanticLabel: 'Reporte ${config.nombre}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            config.nombre,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Selecciona el formato de descarga',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Tooltip(
                      message: 'Cerrar',
                      child: Semantics(
                        button: true,
                        label: 'Cerrar selector de formato',
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
    final semLabel = 'Descargar en $label';
    final semHint = 'Genera el reporte en formato $label';

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
          onGenerar: (parametros) =>
              _generarReporte(config, formato, parametros),
          fetchEstudiantes: _fetchEstudiantes,
        ),
      );
    }
  }

  // ==============================
  // GENERAR REPORTE (FETCH BACK)
  // ==============================
  Future<void> _generarReporte(
    ReporteConfig config,
    FormatoDescarga formato,
    Map<String, dynamic> parametros,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>  Center(
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

      final cleanData = _sanitizeReporteData(data);

      Navigator.pop(context); // cerrar loading

      switch (formato) {
        case FormatoDescarga.csv:
          await _descargarCSV(config, cleanData);
          break;
        case FormatoDescarga.pdf:
          await _descargarPDF(config, cleanData);
          break;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reporte descargado exitosamente'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
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

    // NUEVO: Detectar si es un campo ID
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
          // Filtrar IDs de cada mapa en la lista
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

          // Solo agregar si hay datos después de limpiar
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

      // No incluir campos ID en valores escalares
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
  // EXPORT: CSV
  // ==============================
  String _csvEscape(String v) => v.replaceAll('"', '""');

  Future<void> _descargarCSV(
      ReporteConfig config, Map<String, dynamic> data) async {
    final csv = StringBuffer();
    csv.writeln('"${_csvEscape(config.nombre)}"');
    csv.writeln();
    _procesarDatosParaCSV(data, csv);

    final bytes = Uint8List.fromList(utf8.encode(csv.toString()));
    final fileName =
        '${config.id}_${DateTime.now().millisecondsSinceEpoch}.csv';
    await _saveBytes(bytes: bytes, fileName: fileName, mimeType: 'text/csv');
  }

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
  // EXPORT: EXCEL
  // ==============================
  Future<void> _descargarExcel(
      ReporteConfig config, Map<String, dynamic> data) async {
    final excel = xls.Excel.createExcel();
    final sheet = excel['Reporte'];

    // Título del reporte
    sheet.appendRow(<xls.CellValue>[xls.TextCellValue(config.nombre)]);
    sheet.appendRow(<xls.CellValue>[]);

    // KPIs (valores escalares)
    data.forEach((key, value) {
      if (value is List) return;
      if (value is Map) return;
      sheet.appendRow(<xls.CellValue>[
        xls.TextCellValue(_humanizeKey(key)),
        xls.TextCellValue(_formatValue(key, value)),
      ]);
    });

    sheet.appendRow(<xls.CellValue>[]);

    // Tablas
    data.forEach((key, value) {
      if (value is List && value.isNotEmpty && value.first is Map) {
        sheet.appendRow(<xls.CellValue>[xls.TextCellValue(_humanizeKey(key))]);
        final first = value.first as Map;
        final headers =
            _orderHeaders(first.keys.map((k) => k.toString()).toList());
        sheet.appendRow(
            headers.map((h) => xls.TextCellValue(_humanizeKey(h))).toList());

        for (final item in value) {
          final m = item as Map;
          sheet.appendRow(
            headers
                .map((h) => xls.TextCellValue(_formatValue(h, m[h])))
                .toList(),
          );
        }
        sheet.appendRow(<xls.CellValue>[]);
      }
    });

    final raw = excel.encode();
    if (raw == null) return;

    final fileName =
        '${config.id}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    await _saveBytes(
      bytes: Uint8List.fromList(raw),
      fileName: fileName,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  // ==============================
  // EXPORT: PDF (PRODUCCIÓN)
  // ==============================
  final _fmtMoney = NumberFormat.currency(locale: 'es_EC', symbol: r'$');
  final _fmtNum = NumberFormat('#,##0.##', 'es_EC');
  final _fmtDate = DateFormat('yyyy-MM-dd');

  // DICCIONARIO COMPLETO DE ETIQUETAS PROFESIONALES
  static const Map<String, String> _labels = {
    // IDs - filtrados pero por si acaso
    'id': 'Código',
    'id_estudiante': 'ID',
    'id_subcategoria': 'ID Sub',
    'id_categoria': 'ID Cat',
    'id_usuario': 'ID Usuario',
    'id_evaluacion': 'ID Eval',
    'id_pago': 'ID Pago',
    'id_mensualidad': 'ID Mens',

    // Identificación personal
    'cedula': 'Cédula',
    'dni': 'Cédula',
    'documento': 'Documento',
    'identificacion': 'Identificación',

    // Nombres
    'nombre': 'Nombre',
    'nombres': 'Nombres',
    'apellidos': 'Apellidos',
    'nombre_completo': 'Estudiante',
    'estudiante': 'Estudiante',
    'cliente': 'Cliente',
    'usuario': 'Usuario',
    'nombre_usuario': 'Usuario',

    // Categorización
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

    // Estados
    'estado': 'Estado',
    'estado_pago': 'Estado de Pago',
    'estado_estudiante': 'Estado',
    'activo': 'Activo',
    'inactivo': 'Inactivo',

    // Fechas
    'fecha': 'Fecha',
    'fecha_pago': 'Fecha de Pago',
    'fecha_registro': 'Fecha de Registro',
    'fecha_vencimiento': 'Fecha de Vencimiento',
    'fecha_corte': 'Fecha de Corte',
    'fecha_inicio': 'Fecha de Inicio',
    'fecha_fin': 'Fecha de Fin',
    'desde': 'Desde',
    'hasta': 'Hasta',
    'periodo': 'Período',
    'mes': 'Mes',
    'anio': 'Año',
    'año': 'Año',

    // Mora y vencimientos
    'dias_mora': 'Días de Mora',
    'dias_vencido': 'Días Vencido',
    'mora': 'Mora',
    'vencido': 'Vencido',
    'dia_vencimiento': 'Día de Vencimiento',

    // Montos y valores
    'monto': 'Monto',
    'monto_pagado': 'Monto Pagado',
    'monto_pendiente': 'Monto Pendiente',
    'valor': 'Valor',
    'total': 'Total',
    'subtotal': 'Subtotal',
    'total_recaudado': 'Total Recaudado',
    'total_facturado': 'Total Facturado',
    'total_pendiente': 'Total Pendiente',
    'total_vencido': 'Total Vencido',
    'saldo': 'Saldo',
    'saldo_pendiente': 'Saldo Pendiente',
    'deuda': 'Deuda',
    'debe': 'Debe',
    'haber': 'Haber',

    // Pagos
    'metodo_pago': 'Método de Pago',
    'metodo': 'Método',
    'forma_pago': 'Forma de Pago',
    'tipo_pago': 'Tipo de Pago',
    'efectivo': 'Efectivo',
    'transferencia': 'Transferencia',
    'tarjeta': 'Tarjeta',
    'cheque': 'Cheque',

    // Conteos y cantidades
    'cantidad': 'Cantidad',
    'cantidad_estudiantes': 'Cantidad de Estudiantes',
    'cantidad_pagos': 'Cantidad de Pagos',
    'total_estudiantes': 'Total Estudiantes',
    'total_pagos': 'Total de Pagos',
    'numero': 'Número',
    'numero_pagos': 'Número de Pagos',
    'count': 'Cantidad',
    'conteo': 'Conteo',

    // Porcentajes y ratios
    'porcentaje': 'Porcentaje',
    'porcentaje_mora': 'Porcentaje de Mora',
    'porcentaje_cobro': 'Porcentaje de Cobro',
    'tasa': 'Tasa',
    'ratio': 'Ratio',

    // Académico
    'promedio': 'Promedio',
    'nota': 'Nota',
    'calificacion': 'Calificación',
    'evaluacion': 'Evaluación',
    'ranking': 'Ranking',
    'posicion': 'Posición',
    'puesto': 'Puesto',

    // Asistencia
    'asistencias': 'Asistencias',
    'ausencias': 'Ausencias',
    'tardanzas': 'Tardanzas',
    'justificaciones': 'Justificaciones',
    'presente': 'Presente',
    'ausente': 'Ausente',
    'tardanza': 'Tardanza',

    // Contacto
    'telefono': 'Teléfono',
    'celular': 'Celular',
    'email': 'Email',
    'correo': 'Correo Electrónico',
    'direccion': 'Dirección',

    // Sistema
    'rol': 'Rol',
    'permisos': 'Permisos',
    'acciones': 'Acciones',
    'actividad': 'Actividad',
    'ultimo_acceso': 'Último Acceso',
    'fecha_creacion': 'Fecha de Creación',

    // Descripciones
    'descripcion': 'Descripción',
    'observaciones': 'Observaciones',
    'comentario': 'Comentario',
    'notas': 'Notas',
    'detalle': 'Detalle',
  };

  Future<void> _descargarPDF(
    ReporteConfig config,
    Map<String, dynamic> data,
  ) async {
    final cleanData = _sanitizeReporteData(data);

    final pdf = pw.Document();
    final generatedAt = DateTime.now();

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

    final bytes = await pdf.save();
    final fileName = '${config.id}_${generatedAt.millisecondsSinceEpoch}.pdf';
    await _saveBytes(
      bytes: bytes,
      fileName: fileName,
      mimeType: 'application/pdf',
    );
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

    if (k.contains('monto') ||
        k.contains('valor') ||
        k.contains('saldo') ||
        k.contains('deuda') ||
        k.contains('total')) return 10;

    if (k.contains('cantidad') ||
        k.contains('conteo') ||
        k.contains('count') ||
        k.contains('numero') ||
        k.contains('número')) return 20;

    if (k.contains('porcentaje') || k.contains('%') || k.contains('ratio')) {
      return 30;
    }

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
    if (h.contains('curso') || h.contains('nivel') || h.contains('grado')) {
      return 12;
    }

    if (h.contains('fecha') && !h.contains('venc')) return 20;
    if (h.contains('venc') || h.contains('vencimiento')) return 21;
    if (h.contains('periodo') || h.contains('mes') || h.contains('año')) {
      return 22;
    }

    if (h.contains('estado')) return 30;

    if (h.contains('dias') || h.contains('días') || h.contains('mora')) {
      return 40;
    }

    if (h.contains('monto') || h.contains('valor') || h.contains('saldo')) {
      return 50;
    }
    if (h.contains('total') || h.contains('deuda')) return 51;
    if (h.contains('pagado') || h.contains('recaudado')) return 52;
    if (h.contains('pendiente') || h.contains('debe')) return 53;

    if (h.contains('metodo') || h.contains('método') || h.contains('forma')) {
      return 60;
    }

    if (h.contains('cantidad') || h.contains('count') || h.contains('numero')) {
      return 70;
    }

    if (h.contains('nota') ||
        h.contains('calificacion') ||
        h.contains('promedio')) return 80;
    if (h.contains('ranking') || h.contains('posicion')) return 81;

    if (h.contains('asistencia') ||
        h.contains('ausencia') ||
        h.contains('tardanza')) return 85;

    if (h.contains('porcentaje') || h.contains('%') || h.contains('ratio')) {
      return 90;
    }

    if (h.startsWith('id_') || h == 'id') return 999;

    return 50;
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

        final originalHeaders = rows.first.keys.toList();
        final headers = _orderHeaders(originalHeaders);

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
                _humanizeKey(e.key).toUpperCase(),
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
    final hint = h.contains('monto') ||
        h.contains('total') ||
        h.contains('saldo') ||
        h.contains('deuda') ||
        h.contains('valor') ||
        h.contains('pagado') ||
        h.contains('recaudado') ||
        h.contains('facturado') ||
        h.contains('dias') ||
        h.contains('días') ||
        h.contains('mora') ||
        h.contains('porcentaje') ||
        h.contains('%');

    var numericCount = 0;
    var sample = 0;
    for (final r in rows.take(12)) {
      if (idx >= r.length) continue;
      final v = r[idx]
          .replaceAll('.', '')
          .replaceAll(',', '')
          .replaceAll(r'$', '')
          .trim();
      if (v.isEmpty) continue;
      sample++;
      if (double.tryParse(v) != null) numericCount++;
    }
    final looks = sample > 0 && (numericCount / sample) >= 0.6;
    return hint || looks;
  }

  String _formatValue(String key, dynamic value) {
    if (value == null) return '-';

    if (value is DateTime) return _fmtDate.format(value);

    if (value is String) {
      final s = value.trim();
      if (s.isEmpty) return '-';
      final dt = DateTime.tryParse(s);
      if (dt != null) return _fmtDate.format(dt);
      return s;
    }

    if (value is num) {
      final k = key.toLowerCase();
      final isMoney = k.contains('monto') ||
          k.contains('total') ||
          k.contains('saldo') ||
          k.contains('deuda') ||
          k.contains('valor') ||
          k.contains('recaudado') ||
          k.contains('facturado') ||
          k.contains('pagado');

      final isPercent = k.contains('porcentaje') || k.contains('%');

      if (isMoney) return _fmtMoney.format(value);
      if (isPercent) return '${_fmtNum.format(value)}%';
      return _fmtNum.format(value);
    }

    if (value is bool) return value ? 'Sí' : 'No';
    if (value is Map) return '-';

    return value.toString();
  }

  String _humanizeKey(String key) {
    final raw = key.trim();
    if (raw.isEmpty) return raw;

    final low = raw.toLowerCase();
    if (_labels.containsKey(low)) return _labels[low]!;

    var s = raw.replaceAll('_', ' ');
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

    final ced =
        (cedula == null || cedula!.trim().isEmpty) ? null : cedula!.trim();

    if (sub != null) parts.add(sub);
    if (ced != null) parts.add('Cédula: $ced');

    return parts.join(' • ');
  }

  static EstudianteOption fromMap(Map<String, dynamic> m) {
    final id = int.tryParse(
          '${m['id_estudiante'] ?? m['id'] ?? m['idEstudiante'] ?? ''}',
        ) ??
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

    final ced = (m['cedula'] ?? m['dni'] ?? m['documento'])
        ?.toString()
        .trim();

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
          'Completa los filtros requeridos y toca Descargar para generar el archivo.',
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Tooltip(
              message: 'Filtros del reporte',
              child: Icon(
                Icons.tune,
                color: widget.config.color,
                semanticLabel: 'Filtros',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.config.nombre,
                style: const TextStyle(fontSize: 18),
              ),
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
              hint: 'Cierra el diálogo sin descargar',
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ),
          Tooltip(
            message: 'Descargar',
            child: Semantics(
              button: true,
              label: 'Descargar reporte',
              hint: 'Valida los filtros y genera el archivo',
              child: FilledButton.icon(
                onPressed: _validarYGenerar,
                style:
                    FilledButton.styleFrom(backgroundColor: widget.config.color),
                icon: const Icon(Icons.download, semanticLabel: 'Descargar'),
                label: const Text('Descargar'),
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
    final hint = 'Toca para seleccionar un rango de fechas';

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        hint: hint,
        child: InkWell(
          onTap: _pickRango,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Rango de fechas${requerido ? " *" : " (opcional)"}',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(
                Icons.calendar_month,
                semanticLabel: 'Calendario',
              ),
              helperText:
                  requerido ? 'Obligatorio para generar este reporte' : null,
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
              helperText: 'Se usa como referencia para cálculos del reporte',
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
            helperText: 'Se usa para definir cuándo vence una mensualidad',
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
            helperText: 'Define cómo se agrupan los datos en el tiempo',
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
                  prefixIcon:
                      const Icon(Icons.person_search, semanticLabel: 'Estudiante'),
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
            helperText: 'Rango de días para análisis de alertas/recordatorios',
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
            prefixIcon: Icon(Icons.format_list_numbered,
                semanticLabel: 'Top'),
            helperText: 'Cantidad máxima de registros a incluir en el reporte',
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
            helperText: 'Filtra por una subcategoría específica si lo necesitas',
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
                    ?  Center(
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
