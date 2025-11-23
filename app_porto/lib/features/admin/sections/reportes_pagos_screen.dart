
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

// ============================================================================
// CLASES STUB (Para que el código compile sin tus archivos core)
// ============================================================================

// Stub de HttpClient
class HttpClient {
  final TokenProvider? tokenProvider;
  HttpClient({this.tokenProvider});

  Future<dynamic> get(String url, {Map<String, String>? headers, Map<String, dynamic>? query}) async {
    debugPrint('[STUB] GET: $url, Query: $query');
    await Future.delayed(const Duration(milliseconds: 300));
    // Simula una respuesta vacía o de ejemplo
    if (url.contains('resumen')) return {'valor': 100, 'pagado': 50, 'pendiente': 50, 'estado': 'parcial'};
    return [];
  }

  Future<dynamic> post(String url, {Map<String, String>? headers, dynamic body}) async {
    debugPrint('[STUB] POST: $url, Body: $body');
    await Future.delayed(const Duration(milliseconds: 300));
    // Simula una creación exitosa
    return {'ok': true, 'data': {...body, 'id': 123, 'creado_por_nombre': 'Admin'}};
  }

  Future<dynamic> put(String url, {Map<String, String>? headers, dynamic body}) async {
    debugPrint('[STUB] PUT: $url, Body: $body');
    await Future.delayed(const Duration(milliseconds: 300));
    return {'ok': true, 'data': {'id': 123, ...body}};
  }

  Future<dynamic> delete(String url, {Map<String, String>? headers}) async {
    debugPrint('[STUB] DELETE: $url');
    await Future.delayed(const Duration(milliseconds: 300));
    return {'ok': true};
  }
}

// Stub de Endpoints
class Endpoints {
  static const String adminEstadoMensualidad = '/estado-mensualidad';
  static const String pagos = '/pagos';
}

// Stub de ApiError
class ApiError implements Exception {
  final int status;
  final String message;
  final Map? body;
  ApiError(this.status, this.message, {this.body});
}

// Stub de TokenProvider
abstract class TokenProvider {
  Future<String?> getToken();
}

// Stub de implementación de TokenProvider
class FakeTokenProvider implements TokenProvider {
  @override
  Future<String?> getToken() async {
    return 'fake-jwt-token';
  }
}

// ============================================================================
// PANTALLA PRINCIPAL DE REPORTES CON TABS (Tu código original)
// ============================================================================
class ReportesPagosScreen extends StatefulWidget {
  const ReportesPagosScreen({super.key});

  @override
  State<ReportesPagosScreen> createState() => _ReportesPagosScreenState();
}

class _ReportesPagosScreenState extends State<ReportesPagosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        const maxWidth = 1400.0;
        final width =
            constraints.maxWidth > maxWidth ? maxWidth : constraints.maxWidth;

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics_outlined,
                              size: 28, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 12),
                          const Text('Sistema de Reportes',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                          'Genera reportes detallados del sistema y expórtalos en PDF',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                ),

                // Tabs
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: Theme.of(context).primaryColor,
                    tabs: const [
                      Tab(text: 'Pagos'),
                      Tab(text: 'Estudiantes'),
                      Tab(text: 'Asistencias'),
                      Tab(text: 'Usuarios'),
                      Tab(text: 'Financiero'),
                      Tab(text: 'Estadísticas'),
                      Tab(text: 'Personalizado'),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      ReportePagosTab(), // <--- ESTE ES EL TAB MODIFICADO
                      ReporteEstudiantesTab(),
                      ReporteAsistenciasTab(),
                      ReporteUsuariosTab(),
                      ReporteFinancieroTab(),
                      ReporteEstadisticasTab(),
                      ReportePersonalizadoTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// TAB 1: REPORTES DE PAGOS (MODIFICADO para conectar con Repos)
// ============================================================================
class ReportePagosTab extends StatefulWidget {
  const ReportePagosTab({super.key});

  @override
  State<ReportePagosTab> createState() => _ReportePagosTabState();
}

class _ReportePagosTabState extends State<ReportePagosTab> {
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _metodoPago = 'todos';
  String _estadoPago = 'todos';

  // Controlador para el ID del estudiante
  final TextEditingController _estudianteCedulaController =
      TextEditingController();

  @override
  void dispose() {
    _estudianteCedulaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReportCard(
            icon: Icons.receipt_long,
            title: 'Reporte de Pagos Realizados',
            description:
                'Lista detallada de todos los pagos con filtros personalizados',
            color: Colors.blue,
            onGenerate: () => _generarReportePagos(context),
            filters: [
              _buildDateRangePicker(),
              _buildMetodoPagoDropdown(),
              _buildEstadoPagoDropdown(),
            ],
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            icon: Icons.pending_actions,
            title: 'Mensualidades Pendientes',
            description: 'Reporte de mensualidades vencidas y por vencer',
            color: Colors.orange,
            onGenerate: () => _generarReportePendientes(context),
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            icon: Icons.account_balance_wallet,
            title: 'Resumen de Ingresos',
            description:
                'Consolidado de ingresos por período y método de pago',
            color: Colors.green,
            onGenerate: () => _generarReporteIngresos(context),
            filters: [_buildDateRangePicker()],
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            icon: Icons.person_outline,
            title: 'Estado de Cuenta por Estudiante',
            description: 'Historial de pagos y saldo pendiente individual',
            color: Colors.purple,
            onGenerate: () => _generarEstadoCuenta(context),
            // Filtro para ingresar la cédula o ID del estudiante
            filters: [
              TextFormField(
                controller: _estudianteCedulaController,
                decoration: const InputDecoration(
                  labelText: 'Cédula del Estudiante',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.person),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _selectDate(context, true),
            child: InputDecorator(
              decoration: const InputDecoration(
                  labelText: 'Desde',
                  border: OutlineInputBorder(),
                  isDense: true),
              child: Text(_fechaInicio == null
                  ? 'Seleccionar'
                  : DateFormat('dd/MM/yyyy').format(_fechaInicio!)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () => _selectDate(context, false),
            child: InputDecorator(
              decoration: const InputDecoration(
                  labelText: 'Hasta',
                  border: OutlineInputBorder(),
                  isDense: true),
              child: Text(_fechaFin == null
                  ? 'Seleccionar'
                  : DateFormat('dd/MM/yyyy').format(_fechaFin!)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetodoPagoDropdown() {
    return DropdownButtonFormField<String>(
      value: _metodoPago,
      decoration: const InputDecoration(
          labelText: 'Método de pago',
          border: OutlineInputBorder(),
          isDense: true),
      items: const [
        DropdownMenuItem(value: 'todos', child: Text('Todos')),
        DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
        DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
        DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
      ],
      onChanged: (v) => setState(() => _metodoPago = v!),
    );
  }

  Widget _buildEstadoPagoDropdown() {
    return DropdownButtonFormField<String>(
      value: _estadoPago,
      decoration: const InputDecoration(
          labelText: 'Estado', border: OutlineInputBorder(), isDense: true),
      items: const [
        DropdownMenuItem(value: 'todos', child: Text('Todos')),
        DropdownMenuItem(value: 'activo', child: Text('Activos')),
        DropdownMenuItem(value: 'anulado', child: Text('Anulados')),
      ],
      onChanged: (v) => setState(() => _estadoPago = v!),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _fechaInicio = date;
        } else {
          _fechaFin = date;
        }
      });
    }
  }

  // ========================================================================
  // MÉTODOS DE GENERACIÓN (MODIFICADOS)
  // ========================================================================

  Future<void> _generarReportePagos(BuildContext context) async {
    // Obten el repositorio (ej. via Provider)
    final pagosRepo = context.read<PagosRepository>();

    await _showLoadingAndGenerate(
      context,
      'Generando reporte de pagos...',
      () async {
        // --- 1. LLAMADA AL REPOSITORIO ---
        // !! DEBES CREAR ESTE MÉTODO EN PagosRepository !!
        /*
        final List<Map<String, dynamic>> datosPagos = await pagosRepo.getPagosGlobales(
          fechaInicio: _fechaInicio,
          fechaFin: _fechaFin,
          metodoPago: _metodoPago,
          estadoPago: _estadoPago,
        );
        */
        
        // ** (Línea temporal usando datos de ejemplo) **
        // Reemplaza esto con la llamada real al repositorio cuando la tengas
        debugPrint('Usando datos de EJEMPLO para Reporte Pagos');
        final List<Map<String, dynamic>> datosPagos = PDFGenerator.getDatosPagosEjemplo();


        // --- 2. PASAR DATOS AL GENERADOR ---
        return PDFGenerator.generarReportePagos(
          datosPagos: datosPagos, // <--- Aquí pasas los datos reales
          fechaInicio: _fechaInicio,
          fechaFin: _fechaFin,
          metodoPago: _metodoPago,
          estadoPago: _estadoPago,
        );
      },
    );
  }

  Future<void> _generarReportePendientes(BuildContext context) async {
    // Asumo que tendrás un Repositorio de Mensualidades/EstadoMensualidad
    // final mensualidadRepo = context.read<EstadoMensualidadRepository>();

    await _showLoadingAndGenerate(
      context,
      'Generando deudas pendientes...',
      () async {
        // --- 1. LLAMADA AL REPOSITORIO ---
        // !! DEBES CREAR ESTE MÉTODO EN TU REPOSITORIO !!
        /*
        final List<Map<String, dynamic>> datosPendientes = 
          await mensualidadRepo.getMensualidadesPendientesGlobales(); // <--- DEBES CREAR ESTO
        */
        
        // ** (Línea temporal usando datos de ejemplo) **
        debugPrint('Usando datos de EJEMPLO para Reporte Pendientes');
        final datosPendientes = PDFGenerator.getDatosPendientesEjemplo();

        // --- 2. PASAR DATOS AL GENERADOR ---
        return PDFGenerator.generarReportePendientes(
          datosPendientes: datosPendientes,
        );
      },
    );
  }

  Future<void> _generarReporteIngresos(BuildContext context) async {
    final pagosRepo = context.read<PagosRepository>();

    await _showLoadingAndGenerate(
      context,
      'Generando resumen de ingresos...',
      () async {
        // --- 1. LLAMADA AL REPOSITORIO ---
        // !! DEBES CREAR ESTE MÉTODO EN PagosRepository !!
        /*
        final List<Map<String, dynamic>> datosIngresos = 
          await pagosRepo.getResumenIngresosGlobal( // <--- DEBES CREAR ESTO
            fechaInicio: _fechaInicio,
            fechaFin: _fechaFin
          );
        */
        
        // ** (Línea temporal usando datos de ejemplo) **
        debugPrint('Usando datos de EJEMPLO para Reporte Ingresos');
        final datosIngresos = PDFGenerator.getDatosIngresosEjemplo();


        // --- 2. PASAR DATOS AL GENERADOR ---
        return PDFGenerator.generarReporteIngresos(
          datosIngresos: datosIngresos,
          fechaInicio: _fechaInicio,
          fechaFin: _fechaFin,
        );
      },
    );
  }

  Future<void> _generarEstadoCuenta(BuildContext context) async {
    final cedula = _estudianteCedulaController.text.trim();
    if (cedula.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingrese la cédula del estudiante.')),
      );
      return;
    }

    // Asumo que tendrás un Repositorio de Estudiantes
    // final estudianteRepo = context.read<EstudianteRepository>();

    await _showLoadingAndGenerate(
      context,
      'Generando estado de cuenta...',
      () async {
        // --- 1. LLAMADA AL REPOSITORIO ---
        // !! DEBES CREAR ESTE MÉTODO EN TU REPOSITORIO !!
        /*
        final Map<String, dynamic> datosCuenta = 
          await estudianteRepo.getEstadoDeCuentaPorCedula(cedula: cedula); // <--- DEBES CREAR ESTO
        */
        
        // ** (Línea temporal usando datos de ejemplo) **
        // Nota: El ejemplo es una lista, pero para un solo estudiante
        // lo lógico es que tu repo devuelva un solo Map.
        // Aquí simulo que obtengo el primero de una lista.
        debugPrint('Usando datos de EJEMPLO para Estado de Cuenta');
        final datosCuenta = PDFGenerator.getDatosEstadoCuentaEjemplo().first;


        // --- 2. PASAR DATOS AL GENERADOR ---
        return PDFGenerator.generarEstadoCuenta(
          datosCuenta: datosCuenta,
        );
      },
    );
  }


  Widget _buildReportCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onGenerate,
    List<Widget>? filters,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(description, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            if (filters != null && filters.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              ...filters.map((f) => Padding(padding: const EdgeInsets.only(bottom: 12), child: f)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onGenerate,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Generar PDF'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14), 
                  backgroundColor: color,
                  foregroundColor: Colors.white, // Texto blanco
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper de Carga modificado para aceptar un texto
  Future<void> _showLoadingAndGenerate(
    BuildContext context,
    String loadingText,
    Future<pw.Document> Function() generator,
  ) async {
    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(loadingText), // Texto dinámico
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final pdf = await generator();
      if (!context.mounted) return;
      Navigator.pop(context); // Cierra el loading
      
      // Muestra la vista previa del PDF
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
      
    } catch (e, st) {
      debugPrint('Error al generar PDF: $e\n$st'); // Imprime el stack trace
      if (!context.mounted) return;
      Navigator.pop(context); // Cierra el loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar el reporte: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


// ============================================================================
// TAB 2: REPORTES DE ESTUDIANTES (Tu código original)
// ============================================================================
class ReporteEstudiantesTab extends StatelessWidget {
  const ReporteEstudiantesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSimpleReportCard(context,
              icon: Icons.people,
              title: 'Lista de Estudiantes Activos',
              description: 'Todos los estudiantes actualmente matriculados',
              color: Colors.indigo,
              onGenerate: () => PDFGenerator.generarListaEstudiantes(
                    datosEstudiantes: PDFGenerator.getDatosEstudiantesEjemplo(true), // Usando datos de ejemplo
                    activos: true,
                  )),
          const SizedBox(height: 16),
          _buildSimpleReportCard(context,
              icon: Icons.people_outline,
              title: 'Lista de Estudiantes Inactivos',
              description: 'Estudiantes dados de baja',
              color: Colors.grey,
              onGenerate: () => PDFGenerator.generarListaEstudiantes(
                datosEstudiantes: PDFGenerator.getDatosEstudiantesEjemplo(false), // Usando datos de ejemplo
                activos: false,
              )),
          const SizedBox(height: 16),
          _buildSimpleReportCard(context,
              icon: Icons.category,
              title: 'Estudiantes por Categoría',
              description: 'Distribución de estudiantes en categorías',
              color: Colors.teal,
              onGenerate: () => PDFGenerator.generarEstudiantesPorCategoria(
                datosCategorias: PDFGenerator.getDatosCategoriaEjemplo() // Usando datos de ejemplo
              )),
          const SizedBox(height: 16),
          _buildSimpleReportCard(context,
              icon: Icons.school,
              title: 'Estudiantes por Subcategoría',
              description: 'Listado detallado por subcategorías',
              color: Colors.cyan,
              onGenerate: () => PDFGenerator.generarEstudiantesPorSubcategoria(
                datosSubcategorias: PDFGenerator.getDatosSubcategoriaEjemplo() // Usando datos de ejemplo
              )),
          const SizedBox(height: 16),
          _buildSimpleReportCard(context,
              icon: Icons.cake,
              title: 'Cumpleaños del Mes',
              description: 'Estudiantes que cumplen años este mes',
              color: Colors.pink,
              onGenerate: () => PDFGenerator.generarCumpleanosMes(
                datosCumpleanos: PDFGenerator.getDatosCumpleanosEjemplo() // Usando datos de ejemplo
              )),
        ],
      ),
    );
  }

  // Nota: Este helper está duplicado en varias clases,
  // idealmente debería ser un widget reutilizable
  Widget _buildSimpleReportCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String description,
      required Color color,
      required Future<pw.Document> Function() onGenerate}) {
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
            padding: const EdgeInsets.only(top: 4), child: Text(description)),
        trailing: ElevatedButton.icon(
          onPressed: () async {
            // Reutiliza el helper de carga global si es posible
            // O usa este simple:
            showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) =>
                    const Center(child: CircularProgressIndicator()));
            try {
              final pdf = await onGenerate();
              if (!context.mounted) return;
              Navigator.pop(context);
              await Printing.layoutPdf(onLayout: (format) async => pdf.save());
            } catch (e, st) {
              debugPrint('Error al generar PDF: $e\n$st');
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          },
          icon: const Icon(Icons.picture_as_pdf, size: 18),
          label: const Text('PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 3: REPORTES DE ASISTENCIAS (Tu código original)
// ============================================================================
class ReporteAsistenciasTab extends StatelessWidget {
  const ReporteAsistenciasTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSimpleReportCard(context,
              icon: Icons.calendar_today,
              title: 'Asistencias del Mes',
              description: 'Registro de asistencias del mes actual',
              color: Colors.green,
              onGenerate: () => PDFGenerator.generarAsistenciasMes(
                datosAsistencias: PDFGenerator.getDatosAsistenciasEjemplo() // Usando datos de ejemplo
              )),
          const SizedBox(height: 16),
          _buildSimpleReportCard(context,
              icon: Icons.person_search,
              title: 'Asistencias por Estudiante',
              description: 'Historial individual de asistencias',
              color: Colors.blue,
              onGenerate: () => PDFGenerator.generarAsistenciasEstudiante(
                datosEstudiantes: PDFGenerator.getDatosAsistenciasEstudianteEjemplo() // Usando datos de ejemplo
              )),
          const SizedBox(height: 16),
          _buildSimpleReportCard(context,
              icon: Icons.warning,
              title: 'Reporte de Inasistencias',
              description: 'Estudiantes con alta tasa de ausencias',
              color: Colors.red,
              onGenerate: () => PDFGenerator.generarReporteInasistencias(
                datosInasistencias: PDFGenerator.getDatosInasistenciasEjemplo() // Usando datos de ejemplo
              )),
          const SizedBox(height: 16),
          _buildSimpleReportCard(context,
              icon: Icons.trending_up,
              title: 'Estadísticas de Asistencia',
              description: 'Análisis de porcentajes y tendencias',
              color: Colors.orange,
              onGenerate: () => PDFGenerator.generarEstadisticasAsistencia(
                stats: PDFGenerator.getEstadisticasAsistenciaEjemplo() // Usando datos de ejemplo
              )),
        ],
      ),
    );
  }

  Widget _buildSimpleReportCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String description,
      required Color color,
      required Future<pw.Document> Function() onGenerate}) {
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
            padding: const EdgeInsets.only(top: 4), child: Text(description)),
        trailing: ElevatedButton.icon(
          onPressed: () async {
            showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) =>
                    const Center(child: CircularProgressIndicator()));
            try {
              final pdf = await onGenerate();
              if (!context.mounted) return;
              Navigator.pop(context);
              await Printing.layoutPdf(onLayout: (format) async => pdf.save());
            } catch (e, st) {
              debugPrint('Error al generar PDF: $e\n$st');
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          },
          icon: const Icon(Icons.picture_as_pdf, size: 18),
          label: const Text('PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 4: REPORTES DE USUARIOS (Tu código original)
// ============================================================================
class ReporteUsuariosTab extends StatelessWidget {
  const ReporteUsuariosTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSimpleReportCard(context,
              icon: Icons.admin_panel_settings,
              title: 'Lista de Usuarios del Sistema',
              description: 'Todos los usuarios con acceso al sistema',
              color: Colors.deepPurple,
              onGenerate: () => PDFGenerator.generarListaUsuarios(
                datosUsuarios: PDFGenerator.getDatosUsuariosEjemplo() // Usando datos de ejemplo
              )),
          const SizedBox(height: 16),
          _buildSimpleReportCard(context,
              icon: Icons.person,
              title: 'Profesores Activos',
              description: 'Listado de profesores registrados',
              color: Colors.blue,
              onGenerate: () => PDFGenerator.generarListaProfesores(
                datosProfesores: PDFGenerator.getDatosProfesoresEjemplo() // Usando datos de ejemplo
              )),
          const SizedBox(height: 16),
          _buildSimpleReportCard(context,
              icon: Icons.security,
              title: 'Usuarios por Rol',
              description: 'Distribución de usuarios según permisos',
              color: Colors.amber,
              onGenerate: () => PDFGenerator.generarUsuariosPorRol(
                datosRoles: PDFGenerator.getDatosRolesEjemplo() // Usando datos de ejemplo
              )),
        ],
      ),
    );
  }

  Widget _buildSimpleReportCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String description,
      required Color color,
      required Future<pw.Document> Function() onGenerate}) {
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
            padding: const EdgeInsets.only(top: 4), child: Text(description)),
        trailing: ElevatedButton.icon(
          onPressed: () async {
            showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) =>
                    const Center(child: CircularProgressIndicator()));
            try {
              final pdf = await onGenerate();
              if (!context.mounted) return;
              Navigator.pop(context);
              await Printing.layoutPdf(onLayout: (format) async => pdf.save());
            } catch (e, st) {
              debugPrint('Error al generar PDF: $e\n$st');
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          },
          icon: const Icon(Icons.picture_as_pdf, size: 18),
          label: const Text('PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 5: REPORTES FINANCIEROS (Tu código original)
// ============================================================================
class ReporteFinancieroTab extends StatelessWidget {
  const ReporteFinancieroTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSimpleReportCard(context,
              icon: Icons.bar_chart,
              title: 'Balance General',
              description: 'Resumen financiero completo del período',
              color: Colors.green,
              onGenerate: () => PDFGenerator.generarBalanceGeneral(
                balance: PDFGenerator.getDatosBalanceEjemplo() // Usando datos de ejemplo
              )),
          const SizedBox(height: 16),
          _buildSimpleReportCard(context,
              icon: Icons.monetization_on,
              title: 'Ingresos por Método de Pago',
              description: 'Desglose de ingresos según forma de pago',
              color: Colors.teal,
              onGenerate: () => PDFGenerator.generarIngresosPorMetodo(
                metodos: PDFGenerator.getDatosMetodosEjemplo() // Usando datos de ejemplo
              )),
          const SizedBox(height: 16),
          _buildSimpleReportCard(context,
              icon: Icons.trending_down,
              title: 'Cuentas por Cobrar',
              description: 'Montos pendientes de pago',
              color: Colors.orange,
              onGenerate: () => PDFGenerator.generarCuentasPorCobrar(
                cuentas: PDFGenerator.getDatosCuentasPorCobrarEjemplo() // Usando datos de ejemplo
              )),
          const SizedBox(height: 16),
          _buildSimpleReportCard(context,
              icon: Icons.calendar_month,
              title: 'Proyección Mensual',
              description: 'Estimado de ingresos para próximos meses',
              color: Colors.purple,
              onGenerate: () => PDFGenerator.generarProyeccionMensual(
                proyeccion: PDFGenerator.getDatosProyeccionEjemplo() // Usando datos de ejemplo
              )),
        ],
      ),
    );
  }

  Widget _buildSimpleReportCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String description,
      required Color color,
      required Future<pw.Document> Function() onGenerate}) {
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
            padding: const EdgeInsets.only(top: 4), child: Text(description)),
        trailing: ElevatedButton.icon(
          onPressed: () async {
            showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) =>
                    const Center(child: CircularProgressIndicator()));
            try {
              final pdf = await onGenerate();
              if (!context.mounted) return;
              Navigator.pop(context);
              await Printing.layoutPdf(onLayout: (format) async => pdf.save());
            } catch (e, st) {
              debugPrint('Error al generar PDF: $e\n$st');
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          },
          icon: const Icon(Icons.picture_as_pdf, size: 18),
          label: const Text('PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 6: ESTADÍSTICAS GENERALES (Tu código original)
// ============================================================================
class ReporteEstadisticasTab extends StatelessWidget {
  const ReporteEstadisticasTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSimpleReportCard(context,
              icon: Icons.dashboard,
              title: 'Dashboard Ejecutivo',
              description: 'KPIs y métricas principales del sistema',
              color: Colors.indigo,
              onGenerate: () => PDFGenerator.generarDashboardEjecutivo(
                kpis: PDFGenerator.getDatosKPIsEjemplo() // Usando datos de ejemplo
              )),
          const SizedBox(height: 16),
          _buildSimpleReportCard(context,
              icon: Icons.show_chart,
              title: 'Tendencias de Crecimiento',
              description: 'Análisis de crecimiento en matriculaciones',
              color: Colors.green,
              onGenerate: () => PDFGenerator.generarTendenciasCrecimiento(
                tendencias: PDFGenerator.getDatosTendenciasEjemplo() // Usando datos de ejemplo
              )),
          const SizedBox(height: 16),
          _buildSimpleReportCard(context,
              icon: Icons.pie_chart,
              title: 'Distribución por Categorías',
              description: 'Gráficos de distribución de estudiantes',
              color: Colors.blue,
              onGenerate: () => PDFGenerator.generarDistribucionCategorias(
                distribucion: PDFGenerator.getDatosDistribucionEjemplo() // Usando datos de ejemplo
              )),
          const SizedBox(height: 16),
          _buildSimpleReportCard(context,
              icon: Icons.assessment,
              title: 'Índice de Retención',
              description: 'Análisis de permanencia de estudiantes',
              color: Colors.purple,
              onGenerate: () => PDFGenerator.generarIndiceRetencion(
                retencion: PDFGenerator.getDatosRetencionEjemplo() // Usando datos de ejemplo
              )),
        ],
      ),
    );
  }

  Widget _buildSimpleReportCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String description,
      required Color color,
      required Future<pw.Document> Function() onGenerate}) {
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
            padding: const EdgeInsets.only(top: 4), child: Text(description)),
        trailing: ElevatedButton.icon(
          onPressed: () async {
            showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) =>
                    const Center(child: CircularProgressIndicator()));
            try {
              final pdf = await onGenerate();
              if (!context.mounted) return;
              Navigator.pop(context);
              await Printing.layoutPdf(onLayout: (format) async => pdf.save());
            } catch (e, st) {
              debugPrint('Error al generar PDF: $e\n$st');
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          },
          icon: const Icon(Icons.picture_as_pdf, size: 18),
          label: const Text('PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 7: REPORTES PERSONALIZADOS (Tu código original)
// ============================================================================
class ReportePersonalizadoTab extends StatefulWidget {
  const ReportePersonalizadoTab({super.key});

  @override
  State<ReportePersonalizadoTab> createState() =>
      _ReportePersonalizadoTabState();
}

class _ReportePersonalizadoTabState extends State<ReportePersonalizadoTab> {
  final _formKey = GlobalKey<FormState>();
  String _titulo = '';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  final Set<String> _secciones = {};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit_note,
                        size: 28, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    const Text('Crear Reporte Personalizado',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Título del Reporte',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title)),
                  validator: (v) =>
                      v?.trim().isEmpty ?? true ? 'Requerido' : null,
                  onSaved: (v) => _titulo = v ?? '',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                              labelText: 'Fecha Inicio',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today)),
                          child: Text(_fechaInicio == null
                              ? 'Seleccionar'
                              : DateFormat('dd/MM/yyyy')
                                  .format(_fechaInicio!)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                              labelText: 'Fecha Fin',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today)),
                          child: Text(_fechaFin == null
                              ? 'Seleccionar'
                              : DateFormat('dd/MM/yyyy').format(_fechaFin!)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Secciones a incluir:',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildCheckOption('Pagos', 'pagos'),
                    _buildCheckOption('Estudiantes', 'estudiantes'),
                    _buildCheckOption('Asistencias', 'asistencias'),
                    _buildCheckOption('Mensualidades', 'mensualidades'),
                    _buildCheckOption('Categorías', 'categorias'),
                    _buildCheckOption('Subcategorías', 'subcategorias'),
                    _buildCheckOption('Usuarios', 'usuarios'),
                    _buildCheckOption('Estadísticas', 'estadisticas'),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _secciones.isEmpty
                        ? null
                        : () => _generarReportePersonalizado(context),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Generar Reporte Personalizado'),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckOption(String label, String value) {
    final isSelected = _secciones.contains(value);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _secciones.add(value);
          } else {
            _secciones.remove(value);
          }
        });
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _fechaInicio = date;
        } else {
          _fechaFin = date;
        }
      });
    }
  }

  Future<void> _generarReportePersonalizado(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generando reporte personalizado...'),
            ]),
          ),
        ),
      ),
    );

    try {
      // AQUÍ TAMBIÉN DEBERÍAS OBTENER DATOS REALES BASADOS EN LAS SECCIONES
      // Y pasarlos a la función 'generarReportePersonalizado'
      final pdf = await PDFGenerator.generarReportePersonalizado(
        titulo: _titulo,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        secciones: _secciones.toList(),
        // datosReales: ... (necesitarías pasar los datos aquí)
      );
      if (!context.mounted) return;
      Navigator.pop(context);
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e, st) {
      debugPrint('Error al generar PDF: $e\n$st');
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}


// ============================================================================
// GENERADOR DE PDFs - CLASE PRINCIPAL (MODIFICADA para recibir datos)
// ============================================================================
class PDFGenerator {
  // ========== PAGOS ==========
  static Future<pw.Document> generarReportePagos({
    required List<Map<String, dynamic>> datosPagos, // <--- DATO RECIBIDO
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String metodoPago = 'todos',
    String estadoPago = 'todos',
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final pagos = datosPagos; // <--- SE USA EL PARÁMETRO

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Reporte de Pagos Realizados'),
          pw.SizedBox(height: 20),
          _buildInfoRow('Fecha de generación:',
              DateFormat('dd/MM/yyyy HH:mm').format(now)),
          if (fechaInicio != null)
            _buildInfoRow('Desde:', DateFormat('dd/MM/yyyy').format(fechaInicio)),
          if (fechaFin != null)
            _buildInfoRow('Hasta:', DateFormat('dd/MM/yyyy').format(fechaFin)),
          _buildInfoRow('Método de pago:', metodoPago),
          _buildInfoRow('Estado:', estadoPago),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),
          _buildTablePagos(pagos), // Los datos se pasan a la tabla
          pw.SizedBox(height: 20),
          _buildResumenPagos(pagos),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    return pdf;
  }

  static Future<pw.Document> generarReportePendientes({
    required List<Map<String, dynamic>> datosPendientes, // <--- DATO RECIBIDO
  }) async {
    final pdf = pw.Document();
    final pendientes = datosPendientes; // <--- SE USA EL PARÁMETRO

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Mensualidades Pendientes'),
          pw.SizedBox(height: 20),
          _buildInfoRow(
              'Fecha:', DateFormat('dd/MM/yyyy').format(DateTime.now())),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),
          _buildTablePendientes(pendientes),
          pw.SizedBox(height: 20),
          _buildResumenPendientes(pendientes),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    return pdf;
  }

  static Future<pw.Document> generarReporteIngresos({
    required List<Map<String, dynamic>> datosIngresos, // <--- DATO RECIBIDO
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final pdf = pw.Document();
    final ingresos = datosIngresos; // <--- SE USA EL PARÁMETRO

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Resumen de Ingresos'),
          pw.SizedBox(height: 20),
          if (fechaInicio != null)
            _buildInfoRow('Desde:', DateFormat('dd/MM/yyyy').format(fechaInicio)),
          if (fechaFin != null)
            _buildInfoRow('Hasta:', DateFormat('dd/MM/yyyy').format(fechaFin)),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),
          _buildTableIngresos(ingresos),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    return pdf;
  }

  static Future<pw.Document> generarEstadoCuenta({
    required Map<String, dynamic> datosCuenta, // <--- DATO RECIBIDO (Uno solo)
  }) async {
    final pdf = pw.Document();
    final est = datosCuenta; // <--- SE USA EL PARÁMETRO

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Estado de Cuenta por Estudiante'),
          pw.SizedBox(height: 20),
          // Ya no se mapea una lista, se muestra el estudiante directamente
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                color: PdfColors.blue50,
                width: double.infinity,
                child: pw.Text('${est['nombres']} ${est['apellidos']}',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 14)),
              ),
              pw.SizedBox(height: 10),
              // Asumo que tu repo devolverá los pagos anidados
              _buildTableEstadoCuenta(
                  (est['pagos'] as List).cast<Map<String, dynamic>>()),
              pw.SizedBox(height: 10),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
                pw.Text('Total: \$${est['total']}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(width: 20),
                pw.Text('Pendiente: \$${est['pendiente']}',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
              ]),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
            ],
          ),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    return pdf;
  }

  // ========== ESTUDIANTES ==========
  static Future<pw.Document> generarListaEstudiantes({
    required List<Map<String, dynamic>> datosEstudiantes,
    required bool activos
  }) async {
    final pdf = pw.Document();
    final estudiantes = datosEstudiantes;
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Lista de Estudiantes ${activos ? 'Activos' : 'Inactivos'}'),
          pw.SizedBox(height: 20),
          _buildInfoRow('Total:', '${estudiantes.length} estudiantes'),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),
          _buildTableEstudiantes(estudiantes),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    return pdf;
  }

  static Future<pw.Document> generarEstudiantesPorCategoria({
    required List<Map<String, dynamic>> datosCategorias,
  }) async {
    final pdf = pw.Document();
    final categorias = datosCategorias;
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Estudiantes por Categoría'),
          pw.SizedBox(height: 20),
          ...categorias.map((cat) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    color: PdfColors.teal50,
                    width: double.infinity,
                    child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(cat['nombre'],
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 14)),
                          pw.Text('${cat['estudiantes'].length} estudiantes'),
                        ]),
                  ),
                  pw.SizedBox(height: 10),
                  _buildTableEstudiantes( (cat['estudiantes'] as List).cast<Map<String, dynamic>>()),
                  pw.SizedBox(height: 20),
                ],
              )),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    return pdf;
  }

  static Future<pw.Document> generarEstudiantesPorSubcategoria({
    required List<Map<String, dynamic>> datosSubcategorias,
  }) async {
    final pdf = pw.Document();
    final subcategorias = datosSubcategorias;
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Estudiantes por Subcategoría'),
          pw.SizedBox(height: 20),
          ...subcategorias.map((sub) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    color: PdfColors.cyan50,
                    width: double.infinity,
                    child:
                        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text(sub['nombre'],
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.Text('Categoría: ${sub['categoria']}',
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('${sub['estudiantes'].length} estudiantes',
                          style: const pw.TextStyle(fontSize: 10)),
                    ]),
                  ),
                  pw.SizedBox(height: 10),
                  _buildTableEstudiantes((sub['estudiantes'] as List).cast<Map<String, dynamic>>()),
                  pw.SizedBox(height: 20),
                ],
              )),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    return pdf;
  }

  static Future<pw.Document> generarCumpleanosMes({
    required List<Map<String, dynamic>> datosCumpleanos,
  }) async {
    final pdf = pw.Document();
    final cumpleanos = datosCumpleanos;
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Cumpleaños del Mes'),
          pw.SizedBox(height: 20),
          _buildInfoRow(
              'Mes:', DateFormat('MMMM yyyy', 'es').format(DateTime.now())),
          _buildInfoRow('Total:', '${cumpleanos.length} cumpleaños'),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),
          _buildTableCumpleanos(cumpleanos),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    return pdf;
  }

  // ========== ASISTENCIAS ==========
  static Future<pw.Document> generarAsistenciasMes({
    required List<Map<String, dynamic>> datosAsistencias,
  }) async {
    final pdf = pw.Document();
    final asistencias = datosAsistencias;
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Asistencias del Mes'),
          pw.SizedBox(height: 20),
          _buildInfoRow(
              'Mes:', DateFormat('MMMM yyyy', 'es').format(DateTime.now())),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),
          _buildTableAsistencias(asistencias),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    return pdf;
  }

  static Future<pw.Document> generarAsistenciasEstudiante({
    required List<Map<String, dynamic>> datosEstudiantes,
  }) async {
    final pdf = pw.Document();
    final estudiantes = datosEstudiantes;
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Asistencias por Estudiante'),
          pw.SizedBox(height: 20),
          ...estudiantes.map((est) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    color: PdfColors.blue50,
                    width: double.infinity,
                    child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('${est['nombres']} ${est['apellidos']}',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text('Asistencia: ${est['porcentaje']}%'),
                        ]),
                  ),
                  pw.SizedBox(height: 10),
                  _buildTableAsistenciasDetalle((est['asistencias'] as List).cast<Map<String, dynamic>>()),
                  pw.SizedBox(height: 20),
                ],
              )),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    return pdf;
  }

  static Future<pw.Document> generarReporteInasistencias({
    required List<Map<String, dynamic>> datosInasistencias,
  }) async {
    final pdf = pw.Document();
    final inasistencias = datosInasistencias;
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Reporte de Inasistencias'),
          pw.SizedBox(height: 20),
          pw.Text('Estudiantes con alta tasa de ausencias (>30%)',
              style: const pw.TextStyle(color: PdfColors.red)),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),
          _buildTableInasistencias(inasistencias),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    return pdf;
  }

  static Future<pw.Document> generarEstadisticasAsistencia({
    required Map<String, dynamic> stats,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Estadísticas de Asistencia'),
          pw.SizedBox(height: 20),
          _buildKPIsAsistencia(stats),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    return pdf;
  }

  // ========== USUARIOS ==========
  static Future<pw.Document> generarListaUsuarios({
    required List<Map<String, dynamic>> datosUsuarios,
  }) async {
    final pdf = pw.Document();
    final usuarios = datosUsuarios;
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Lista de Usuarios del Sistema'),
          pw.SizedBox(height: 20),
          _buildInfoRow('Total:', '${usuarios.length} usuarios'),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),
          _buildTableUsuarios(usuarios),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    return pdf;
  }

  static Future<pw.Document> generarListaProfesores({
    required List<Map<String, dynamic>> datosProfesores,
  }) async {
    final pdf = pw.Document();
    final profesores = datosProfesores;
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Lista de Profesores'),
          pw.SizedBox(height: 20),
          _buildInfoRow('Total:', '${profesores.length} profesores'),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),
          _buildTableProfesores(profesores),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    return pdf;
  }

  static Future<pw.Document> generarUsuariosPorRol({
    required List<Map<String, dynamic>> datosRoles,
  }) async {
    final pdf = pw.Document();
    final roles = datosRoles;
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Usuarios por Rol'),
          pw.SizedBox(height: 20),
          ...roles.map((rol) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    color: PdfColors.amber50,
                    width: double.infinity,
                    child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(rol['nombre'],
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 14)),
                          pw.Text('${rol['usuarios'].length} usuarios'),
                        ]),
                  ),
                  pw.SizedBox(height: 10),
                  _buildTableUsuarios((rol['usuarios'] as List).cast<Map<String, dynamic>>()),
                  pw.SizedBox(height: 20),
                ],
              )),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    return pdf;
  }

  // ========== FINANCIERO ==========
  static Future<pw.Document> generarBalanceGeneral({
    required Map<String, dynamic> balance,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Balance General'),
          pw.SizedBox(height: 20),
          _buildInfoRow(
              'Período:', DateFormat('MMMM yyyy', 'es').format(DateTime.now())),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),
          _buildKPIsFinancieros(balance),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    return pdf;
  }

  static Future<pw.Document> generarIngresosPorMetodo({
    required List<Map<String, dynamic>> metodos,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Ingresos por Método de Pago'),
          pw.SizedBox(height: 20),
          _buildTableMetodos(metodos),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    return pdf;
  }

  static Future<pw.Document> generarCuentasPorCobrar({
    required List<Map<String, dynamic>> cuentas,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Cuentas por Cobrar'),
          pw.SizedBox(height: 20),
          _buildTableCuentasPorCobrar(cuentas),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    return pdf;
  }

  static Future<pw.Document> generarProyeccionMensual({
    required List<Map<String, dynamic>> proyeccion,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Proyección Mensual'),
          pw.SizedBox(height: 20),
          _buildTableProyeccion(proyeccion),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    return pdf;
  }

  // ========== ESTADÍSTICAS ==========
  static Future<pw.Document> generarDashboardEjecutivo({
    required Map<String, dynamic> kpis,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Dashboard Ejecutivo'),
          pw.SizedBox(height: 20),
          _buildKPICards(kpis),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    return pdf;
  }

  static Future<pw.Document> generarTendenciasCrecimiento({
    required List<Map<String, dynamic>> tendencias,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Tendencias de Crecimiento'),
          pw.SizedBox(height: 20),
          _buildTableTendencias(tendencias),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    return pdf;
  }

  static Future<pw.Document> generarDistribucionCategorias({
    required List<Map<String, dynamic>> distribucion,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Distribución por Categorías'),
          pw.SizedBox(height: 20),
          _buildTableDistribucion(distribucion),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    return pdf;
  }

  static Future<pw.Document> generarIndiceRetencion({
    required List<Map<String, dynamic>> retencion,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Índice de Retención'),
          pw.SizedBox(height: 20),
          _buildTableRetencion(retencion),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    return pdf;
  }

  // ========== PERSONALIZADO ==========
  static Future<pw.Document> generarReportePersonalizado({
    required String titulo,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    required List<String> secciones,
    // Map<String, List<Map<String, dynamic>>>? datosReales, // <-- Deberías pasar los datos aquí
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(titulo),
          pw.SizedBox(height: 20),
          _buildInfoRow(
              'Fecha:', DateFormat('dd/MM/yyyy').format(DateTime.now())),
          if (fechaInicio != null)
            _buildInfoRow('Desde:', DateFormat('dd/MM/yyyy').format(fechaInicio)),
          if (fechaFin != null)
            _buildInfoRow('Hasta:', DateFormat('dd/MM/yyyy').format(fechaFin)),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),
          pw.Text('Secciones incluidas: ${secciones.join(", ")}'),
          pw.SizedBox(height: 20),
          
          // --- AQUÍ DEBERÍAS CONSTRUIR EL REPORTE ---
          // Tendrías que hacer un 'switch' o 'if' por cada
          // sección en la lista 'secciones' y dibujar la tabla
          // correspondiente usando los 'datosReales'.
          
          // Ejemplo:
          // if (secciones.contains('pagos') && datosReales.containsKey('pagos')) {
          //   yield _buildTablePagos(datosReales['pagos']!);
          // }
          // if (secciones.contains('estudiantes') && datosReales.containsKey('estudiantes')) {
          //   yield _buildTableEstudiantes(datosReales['estudiantes']!);
          // }

          pw.Text('Implementación de reporte personalizado pendiente...',
              style: const pw.TextStyle(color: PdfColors.grey)),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    return pdf;
  }

  // ============================================================================
  // HELPERS PDF (Sin cambios)
  // ============================================================================
  static pw.Widget _buildHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800)),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 2, color: PdfColors.blue800),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(children: [
        pw.Text('$label ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(value),
      ]),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text('Página ${context.pageNumber} de ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
    );
  }

  // ============================================================================
  // TABLAS (Sin cambios)
  // ============================================================================
  static pw.Widget _buildTablePagos(List<Map<String, dynamic>> pagos) {
    return pw.Table.fromTextArray(
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      headers: ['Fecha', 'Estudiante', 'Monto', 'Método', 'Estado'],
      data: pagos
          .map((p) => [
                p['fecha'],
                p['estudiante'],
                '\$${p['monto']}',
                p['metodo'],
                p['estado'],
              ])
          .toList(),
    );
  }

  static pw.Widget _buildResumenPagos(List<Map<String, dynamic>> pagos) {
    final total = pagos.fold<double>(
        0, (sum, p) => sum + (p['monto'] as num).toDouble());
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
          color: PdfColors.green50, border: pw.Border.all(color: PdfColors.green)),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('Total de pagos: ${pagos.length}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.Text('Monto total: \$${total.toStringAsFixed(2)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
      ]),
    );
  }

  static pw.Widget _buildTablePendientes(List<Map<String, dynamic>> pendientes) {
    return pw.Table.fromTextArray(
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.orange),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      headers: ['Estudiante', 'Mes', 'Año', 'Monto', 'Días vencido'],
      data: pendientes
          .map((p) => [
                p['estudiante'],
                p['mes'],
                p['anio'].toString(),
                '\$${p['monto']}',
                p['dias_vencido'].toString(),
              ])
          .toList(),
    );
  }

  static pw.Widget _buildResumenPendientes(
      List<Map<String, dynamic>> pendientes) {
    final total = pendientes.fold<double>(
        0, (sum, p) => sum + (p['monto'] as num).toDouble());
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
          color: PdfColors.red50, border: pw.Border.all(color: PdfColors.red)),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('Total pendientes: ${pendientes.length}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.Text('Monto total: \$${total.toStringAsFixed(2)}',
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 14,
                color: PdfColors.red)),
      ]),
    );
  }

  static pw.Widget _buildTableIngresos(List<Map<String, dynamic>> ingresos) {
    return pw.Table.fromTextArray(
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      headers: ['Fecha', 'Concepto', 'Método', 'Monto'],
      data: ingresos
          .map((i) => [
                i['fecha'],
                i['concepto'],
                i['metodo'],
                '\$${i['monto']}',
              ])
          .toList(),
    );
  }

  static pw.Widget _buildTableEstadoCuenta(List<Map<String, dynamic>> pagos) {
    return pw.Table.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(6),
      headers: ['Fecha', 'Concepto', 'Monto'],
      data: pagos
          .map((p) => [p['fecha'], p['concepto'], '\$${p['monto']}'])
          .toList(),
    );
  }

  static pw.Widget _buildTableEstudiantes(
      List<Map<String, dynamic>> estudiantes) {
    return pw.Table.fromTextArray(
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      headers: ['Cédula', 'Nombres', 'Apellidos', 'Teléfono'],
      data: estudiantes
          .map((e) => [
                e['cedula'] ?? 'N/A',
                e['nombres'],
                e['apellidos'],
                e['telefono'] ?? 'N/A',
              ])
          .toList(),
    );
  }

  static pw.Widget _buildTableCumpleanos(
      List<Map<String, dynamic>> cumpleanos) {
    return pw.Table.fromTextArray(
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.pink),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      headers: ['Fecha', 'Nombres', 'Apellidos', 'Edad'],
      data: cumpleanos
          .map((c) => [
                c['fecha'],
                c['nombres'],
                c['apellidos'],
                c['edad'].toString(),
              ])
          .toList(),
    );
  }

  static pw.Widget _buildTableAsistencias(
      List<Map<String, dynamic>> asistencias) {
    return pw.Table.fromTextArray(
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      headers: ['Fecha', 'Estudiante', 'Estado', 'Observaciones'],
      data: asistencias
          .map((a) => [
                a['fecha'],
                a['estudiante'],
                a['estado'],
                a['observaciones'] ?? '-',
              ])
          .toList(),
    );
  }

  static pw.Widget _buildTableAsistenciasDetalle(
      List<Map<String, dynamic>> asistencias) {
    return pw.Table.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(6),
      headers: ['Fecha', 'Estado', 'Observaciones'],
      data: asistencias
          .map((a) => [
                a['fecha'],
                a['estado'],
                a['observaciones'] ?? '-',
              ])
          .toList(),
    );
  }

  static pw.Widget _buildTableInasistencias(
      List<Map<String, dynamic>> inasistencias) {
    return pw.Table.fromTextArray(
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.red),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      headers: ['Estudiante', 'Faltas', 'Total Clases', '% Ausencia'],
      data: inasistencias
          .map((i) => [
                i['estudiante'],
                i['faltas'].toString(),
                i['total'].toString(),
                '${i['porcentaje']}%',
              ])
          .toList(),
    );
  }

  static pw.Widget _buildKPIsAsistencia(Map<String, dynamic> stats) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          border: pw.Border.all(color: PdfColors.grey400)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('Promedio de asistencia: ${stats['promedio']}%',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 8),
        pw.Text('Total de sesiones: ${stats['totalSesiones']}'),
        pw.Text('Estudiantes con >90%: ${stats['excelentes']}'),
        pw.Text('Estudiantes con <70%: ${stats['bajos']}'),
      ]),
    );
  }

  static pw.Widget _buildTableUsuarios(List<Map<String, dynamic>> usuarios) {
    return pw.Table.fromTextArray(
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      headers: ['Nombre', 'Correo', 'Rol', 'Estado'],
      data: usuarios
          .map((u) => [
                u['nombre'],
                u['correo'],
                u['rol'],
                (u['activo'] ?? false) ? 'Activo' : 'Inactivo',
              ])
          .toList(),
    );
  }

  static pw.Widget _buildTableProfesores(
      List<Map<String, dynamic>> profesores) {
    return pw.Table.fromTextArray(
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      headers: ['Nombre', 'Correo', 'Especialidad', 'Estado'],
      data: profesores
          .map((p) => [
                p['nombre'],
                p['correo'],
                p['especialidad'] ?? 'N/A',
                (p['activo'] ?? false) ? 'Activo' : 'Inactivo',
              ])
          .toList(),
    );
  }

  static pw.Widget _buildKPIsFinancieros(Map<String, dynamic> balance) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
          color: PdfColors.green50, border: pw.Border.all(color: PdfColors.green)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('Ingresos totales: \$${balance['ingresos']}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
        pw.SizedBox(height: 8),
        pw.Text('Cuentas por cobrar: \$${balance['porCobrar']}',
            style: const pw.TextStyle(color: PdfColors.orange)),
        pw.Text('Tasa de cobranza: ${balance['tasaCobranza']}%',
            style: const pw.TextStyle(color: PdfColors.green)),
      ]),
    );
  }

  static pw.Widget _buildTableMetodos(List<Map<String, dynamic>> metodos) {
    return pw.Table.fromTextArray(
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      headers: ['Método', 'Cantidad', 'Monto Total', '% del Total'],
      data: metodos
          .map((m) => [
                m['metodo'],
                m['cantidad'].toString(),
                '\$${m['monto']}',
                '${m['porcentaje']}%',
              ])
          .toList(),
    );
  }

  static pw.Widget _buildTableCuentasPorCobrar(
      List<Map<String, dynamic>> cuentas) {
    return pw.Table.fromTextArray(
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.orange),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      headers: ['Estudiante', 'Monto', 'Vencimiento', 'Días'],
      data: cuentas
          .map((c) => [
                c['estudiante'],
                '\$${c['monto']}',
                c['vencimiento'],
                c['dias'].toString(),
              ])
          .toList(),
    );
  }

  static pw.Widget _buildTableProyeccion(
      List<Map<String, dynamic>> proyeccion) {
    return pw.Table.fromTextArray(
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.purple),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      headers: ['Mes', 'Estimado', 'Real', 'Diferencia'],
      data: proyeccion
          .map((p) => [
                p['mes'],
                '\$${p['estimado']}',
                '\$${p['real'] ?? '-'}',
                '\$${p['diferencia'] ?? '-'}',
              ])
          .toList(),
    );
  }

  static pw.Widget _buildKPICards(Map<String, dynamic> kpis) {
    return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildKPICard(
              'Estudiantes Activos', kpis['estudiantes'].toString(), PdfColors.blue),
          _buildKPICard(
              'Ingresos del Mes', '\$${kpis['ingresos']}', PdfColors.green),
          _buildKPICard(
              'Asistencia Promedio', '${kpis['asistencia']}%', PdfColors.orange),
        ]);
  }

  static pw.Widget _buildKPICard(String label, String value, PdfColor color) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
          color: color.shade(0.1), border: pw.Border.all(color: color)),
      child: pw.Column(children: [
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 24, fontWeight: pw.FontWeight.bold, color: color)),
        pw.SizedBox(height: 8),
        pw.Text(label,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 10)),
      ]),
    );
  }

  static pw.Widget _buildTableTendencias(
      List<Map<String, dynamic>> tendencias) {
    return pw.Table.fromTextArray(
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      headers: ['Período', 'Matrículas', 'Crecimiento'],
      data: tendencias
          .map((t) => [
                t['periodo'],
                t['matriculas'].toString(),
                '${t['crecimiento']}%',
              ])
          .toList(),
    );
  }

  static pw.Widget _buildTableDistribucion(
      List<Map<String, dynamic>> distribucion) {
    return pw.Table.fromTextArray(
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      headers: ['Categoría', 'Estudiantes', '% Total'],
      data: distribucion
          .map((d) => [
                d['categoria'],
                d['estudiantes'].toString(),
                '${d['porcentaje']}%',
              ])
          .toList(),
    );
  }

  static pw.Widget _buildTableRetencion(List<Map<String, dynamic>> retencion) {
    return pw.Table.fromTextArray(
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.purple),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      headers: ['Período', 'Ingresaron', 'Permanecen', '% Retención'],
      data: retencion
          .map((r) => [
                r['periodo'],
                r['ingresaron'].toString(),
                r['permanecen'].toString(),
                '${r['retencion']}%',
              ])
          .toList(),
    );
  }

  // ============================================================================
  // GENERADORES DE DATOS DE EJEMPLO (Ahora son públicos)
  // ============================================================================
  static List<Map<String, dynamic>> getDatosPagosEjemplo() {
    return [
      {
        'fecha': '15/11/2025',
        'estudiante': 'Juan Pérez',
        'monto': 50.00,
        'metodo': 'Efectivo',
        'estado': 'Activo'
      },
      {
        'fecha': '14/11/2025',
        'estudiante': 'María García',
        'monto': 45.00,
        'metodo': 'Transferencia',
        'estado': 'Activo'
      },
      {
        'fecha': '13/11/2025',
        'estudiante': 'Carlos López',
        'monto': 50.00,
        'metodo': 'Tarjeta',
        'estado': 'Activo'
      },
      {
        'fecha': '12/11/2025',
        'estudiante': 'Ana Martínez',
        'monto': 40.00,
        'metodo': 'Efectivo',
        'estado': 'Activo'
      },
      {
        'fecha': '11/11/2025',
        'estudiante': 'Pedro Sánchez',
        'monto': 55.00,
        'metodo': 'Transferencia',
        'estado': 'Activo'
      },
    ];
  }

  static List<Map<String, dynamic>> getDatosPendientesEjemplo() {
    return [
      {
        'estudiante': 'Luis Torres',
        'mes': 'Octubre',
        'anio': 2025,
        'monto': 50.00,
        'dias_vencido': 15
      },
      {
        'estudiante': 'Carmen Ruiz',
        'mes': 'Noviembre',
        'anio': 2025,
        'monto': 45.00,
        'dias_vencido': 5
      },
      {
        'estudiante': 'Jorge Díaz',
        'mes': 'Septiembre',
        'anio': 2025,
        'monto': 50.00,
        'dias_vencido': 45
      },
    ];
  }

  static List<Map<String, dynamic>> getDatosIngresosEjemplo() {
    return [
      {
        'fecha': '15/11/2025',
        'concepto': 'Mensualidad',
        'metodo': 'Efectivo',
        'monto': 50.00
      },
      {
        'fecha': '14/11/2025',
        'concepto': 'Mensualidad',
        'metodo': 'Transferencia',
        'monto': 45.00
      },
      {
        'fecha': '13/11/2025',
        'concepto': 'Matrícula',
        'metodo': 'Tarjeta',
        'monto': 100.00
      },
    ];
  }

  static List<Map<String, dynamic>> getDatosEstadoCuentaEjemplo() {
    return [
      {
        'nombres': 'Juan',
        'apellidos': 'Pérez',
        'total': 200.00,
        'pendiente': 50.00,
        'pagos': [
          {
            'fecha': '15/10/2025',
            'concepto': 'Mensualidad Oct',
            'monto': 50.00
          },
          {
            'fecha': '15/09/2025',
            'concepto': 'Mensualidad Sep',
            'monto': 50.00
          },
          {
            'fecha': '15/08/2025',
            'concepto': 'Mensualidad Ago',
            'monto': 50.00
          },
        ],
      },
      {
        'nombres': 'María',
        'apellidos': 'García',
        'total': 150.00,
        'pendiente': 0.00,
        'pagos': [
          {
            'fecha': '14/10/2025',
            'concepto': 'Mensualidad Oct',
            'monto': 50.00
          },
          {
            'fecha': '14/09/2025',
            'concepto': 'Mensualidad Sep',
            'monto': 50.00
          },
          {
            'fecha': '14/08/2025',
            'concepto': 'Mensualidad Ago',
            'monto': 50.00
          },
        ],
      },
    ];
  }

  static List<Map<String, dynamic>> getDatosEstudiantesEjemplo(bool activos) {
    if (!activos) {
        return [
           {'cedula': '9999999999', 'nombres': 'Ex-Estudiante', 'apellidos': 'Retirado', 'telefono': '0966666666'},
        ];
    }
    return [
      {
        'cedula': '1234567890',
        'nombres': 'Juan',
        'apellidos': 'Pérez',
        'telefono': '0999999999'
      },
      {
        'cedula': '0987654321',
        'nombres': 'María',
        'apellidos': 'García',
        'telefono': '0988888888'
      },
      {
        'cedula': '1122334455',
        'nombres': 'Carlos',
        'apellidos': 'López',
        'telefono': '0977777777'
      },
    ];
  }

  static List<Map<String, dynamic>> getDatosCategoriaEjemplo() {
    return [
      {
        'nombre': 'Infantil (6-9 años)',
        'estudiantes': [
          {
            'cedula': '1234567890',
            'nombres': 'Juan',
            'apellidos': 'Pérez',
            'telefono': '0999999999'
          },
          {
            'cedula': '0987654321',
            'nombres': 'María',
            'apellidos': 'García',
            'telefono': '0988888888'
          },
        ],
      },
      {
        'nombre': 'Juvenil (10-14 años)',
        'estudiantes': [
          {
            'cedula': '1122334455',
            'nombres': 'Carlos',
            'apellidos': 'López',
            'telefono': '0977777777'
          },
        ],
      },
    ];
  }

  static List<Map<String, dynamic>> getDatosSubcategoriaEjemplo() {
    return [
      {
        'nombre': 'Grupo A (L-M-V 16:00)',
        'categoria': 'Infantil',
        'estudiantes': [
          {
            'cedula': '1234567890',
            'nombres': 'Juan',
            'apellidos': 'Pérez',
            'telefono': '0999999999'
          },
        ],
      },
      {
        'nombre': 'Grupo B (M-J 15:00)',
        'categoria': 'Infantil',
        'estudiantes': [
          {
            'cedula': '0987654321',
            'nombres': 'María',
            'apellidos': 'García',
            'telefono': '0988888888'
          },
        ],
      },
    ];
  }

  static List<Map<String, dynamic>> getDatosCumpleanosEjemplo() {
    return [
      {'fecha': '20/11/2025', 'nombres': 'Juan', 'apellidos': 'Pérez', 'edad': 12},
      {
        'fecha': '25/11/2025',
        'nombres': 'María',
        'apellidos': 'García',
        'edad': 10
      },
    ];
  }

  static List<Map<String, dynamic>> getDatosAsistenciasEjemplo() {
    return [
      {
        'fecha': '15/11/2025',
        'estudiante': 'Juan Pérez',
        'estado': 'Presente',
        'observaciones': null
      },
      {
        'fecha': '15/11/2025',
        'estudiante': 'María García',
        'estado': 'Ausente',
        'observaciones': 'Justificado'
      },
      {
        'fecha': '14/11/2025',
        'estudiante': 'Juan Pérez',
        'estado': 'Presente',
        'observaciones': null
      },
      {
        'fecha': '14/11/2025',
        'estudiante': 'María García',
        'estado': 'Presente',
        'observaciones': null
      },
    ];
  }

  static List<Map<String, dynamic>> getDatosAsistenciasEstudianteEjemplo() {
    return [
      {
        'nombres': 'Juan',
        'apellidos': 'Pérez',
        'porcentaje': 95,
        'asistencias': [
          {'fecha': '15/11/2025', 'estado': 'Presente', 'observaciones': null},
          {'fecha': '14/11/2025', 'estado': 'Presente', 'observaciones': null},
        ],
      },
      {
        'nombres': 'María',
        'apellidos': 'García',
        'porcentaje': 50,
        'asistencias': [
          {
            'fecha': '15/11/2025',
            'estado': 'Ausente',
            'observaciones': 'Justificado'
          },
          {'fecha': '14/11/2025', 'estado': 'Presente', 'observaciones': null},
        ],
      },
    ];
  }

  static List<Map<String, dynamic>> getDatosInasistenciasEjemplo() {
    return [
      {'estudiante': 'Luis Torres', 'faltas': 8, 'total': 20, 'porcentaje': 40},
      {'estudiante': 'Carmen Ruiz', 'faltas': 7, 'total': 20, 'porcentaje': 35},
    ];
  }

  static Map<String, dynamic> getEstadisticasAsistenciaEjemplo() {
    return {
      'promedio': 87,
      'totalSesiones': 50,
      'excelentes': 15,
      'bajos': 3,
    };
  }

  static List<Map<String, dynamic>> getDatosUsuariosEjemplo() {
    return [
      {
        'nombre': 'Admin Usuario',
        'correo': 'admin@academia.com',
        'rol': 'Administrador',
        'activo': true
      },
      {
        'nombre': 'Prof. García',
        'correo': 'garcia@academia.com',
        'rol': 'Profesor',
        'activo': true
      },
       {
        'nombre': 'Usuario Inactivo',
        'correo': 'ex@academia.com',
        'rol': 'Profesor',
        'activo': false
      },
    ];
  }

  static List<Map<String, dynamic>> getDatosProfesoresEjemplo() {
    return [
      {
        'nombre': 'Prof. García',
        'correo': 'garcia@academia.com',
        'especialidad': 'Danza Contemporánea',
        'activo': true
      },
      {
        'nombre': 'Prof. López',
        'correo': 'lopez@academia.com',
        'especialidad': 'Ballet Clásico',
        'activo': true
      },
    ];
  }

  static List<Map<String, dynamic>> getDatosRolesEjemplo() {
    return [
      {
        'nombre': 'Administrador',
        'usuarios': [
          {
            'nombre': 'Admin Usuario',
            'correo': 'admin@academia.com',
            'rol': 'Administrador',
            'activo': true
          },
        ],
      },
      {
        'nombre': 'Profesor',
        'usuarios': [
          {
            'nombre': 'Prof. García',
            'correo': 'garcia@academia.com',
            'rol': 'Profesor',
            'activo': true
          },
          {
            'nombre': 'Usuario Inactivo',
            'correo': 'ex@academia.com',
            'rol': 'Profesor',
            'activo': false
          },
        ],
      },
    ];
  }

  static Map<String, dynamic> getDatosBalanceEjemplo() {
    return {
      'ingresos': 5000.00,
      'porCobrar': 800.00,
      'tasaCobranza': 86,
    };
  }

  static List<Map<String, dynamic>> getDatosMetodosEjemplo() {
    return [
      {'metodo': 'Efectivo', 'cantidad': 15, 'monto': 750.00, 'porcentaje': 45},
      {
        'metodo': 'Transferencia',
        'cantidad': 12,
        'monto': 600.00,
        'porcentaje': 36
      },
      {'metodo': 'Tarjeta', 'cantidad': 8, 'monto': 400.00, 'porcentaje': 19},
    ];
  }

  static List<Map<String, dynamic>> getDatosCuentasPorCobrarEjemplo() {
    return [
      {
        'estudiante': 'Luis Torres',
        'monto': 150.00,
        'vencimiento': '15/10/2025',
        'dias': 30
      },
      {
        'estudiante': 'Carmen Ruiz',
        'monto': 100.00,
        'vencimiento': '01/11/2025',
        'dias': 14
      },
    ];
  }

  static List<Map<String, dynamic>> getDatosProyeccionEjemplo() {
    return [
      {
        'mes': 'Diciembre 2025',
        'estimado': 5500.00,
        'real': null,
        'diferencia': null
      },
      {
        'mes': 'Noviembre 2025',
        'estimado': 5000.00,
        'real': 4800.00,
        'diferencia': -200.00
      },
    ];
  }

  static Map<String, dynamic> getDatosKPIsEjemplo() {
    return {
      'estudiantes': 125,
      'ingresos': 5000.00,
      'asistencia': 87,
    };
  }

  static List<Map<String, dynamic>> getDatosTendenciasEjemplo() {
    return [
      {'periodo': 'Nov 2025', 'matriculas': 125, 'crecimiento': 8},
      {'periodo': 'Oct 2025', 'matriculas': 116, 'crecimiento': 5},
    ];
  }

  static List<Map<String, dynamic>> getDatosDistribucionEjemplo() {
    return [
      {'categoria': 'Infantil', 'estudiantes': 45, 'porcentaje': 36},
      {'categoria': 'Juvenil', 'estudiantes': 50, 'porcentaje': 40},
      {'categoria': 'Adultos', 'estudiantes': 30, 'porcentaje': 24},
    ];
  }

  static List<Map<String, dynamic>> getDatosRetencionEjemplo() {
    return [
      {'periodo': '2025-2', 'ingresaron': 30, 'permanecen': 27, 'retencion': 90},
      {'periodo': '2025-1', 'ingresaron': 25, 'permanecen': 21, 'retencion': 84},
      {'periodo': '2024-2', 'ingresaron': 28, 'permanecen': 22, 'retencion': 79},
    ];
  }
}


// ============================================================================
// REPOSITORIO: EstadoMensualidadRepository (Tu código original)
// ============================================================================
class EstadoMensualidadRepository {
  final HttpClient _api;

  EstadoMensualidadRepository(this._api);

  Future<List<Map<String, dynamic>>> listByMensualidad(int mensualidadId) async {
    final res = await _api.get(
      Endpoints.adminEstadoMensualidad, // e.g. '/estado-mensualidad'
      query: {'mensualidadId': '$mensualidadId'}, headers: {},
    );
    if (res is List) {
      return res.cast<Map<String, dynamic>>();
    }
    return <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> create({
    required int idMensualidad,
    required String estado, // 'pendiente' | 'pagado' | 'anulado'
  }) async {
    final res = await _api.post(
      Endpoints.adminEstadoMensualidad,
      body: {
        'id_mensualidad': idMensualidad,
        'estado': estado,
      }, headers: {},
    );
    // El backend retorna { ok: true, data: {...} }
    if (res is Map && res['data'] is Map) {
      return (res['data'] as Map).cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  // --- !! MÉTODO NECESARIO QUE DEBES IMPLEMENTAR !! ---
  /*
  Future<List<Map<String, dynamic>>> getMensualidadesPendientesGlobales() async {
    // Aquí harías la llamada a tu backend para traer todas las mensualidades
    // que estén con estado 'pendiente' o 'parcial' y que estén vencidas.
    
    // Ejemplo de llamada (tendrás que crear este endpoint):
    // final res = await _api.get(Endpoints.mensualidadesPendientes);
    
    // Y luego retornar la lista de mapas
    // if (res is List) {
    //   return res.cast<Map<String, dynamic>>();
    // }
    
    // Por ahora, retornas una lista vacía o arrojas error
    throw UnimplementedError('Debes implementar getMensualidadesPendientesGlobales en el backend y aquí');
  }
  */
}


// ============================================================================
// REPOSITORIO: PagosRepository (Tu código original)
// ============================================================================
class PagosRepository {
  final HttpClient _http;

  PagosRepository(this._http);

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // ---------- HELPERS ----------

  /// Verifica que exista token antes de llamar al backend.
  /// Evita hacer requests que siempre devolverían 401.
  Future<void> _requireAuth() async {
    final t = await _http.tokenProvider?.getToken();
    if (t == null || t.isEmpty) {
      throw Exception('Debes iniciar sesión para gestionar pagos.');
    }
  }

  /// Traduce ApiError(401/403) en mensajes claros para el usuario.
  Never _rethrowPretty(Object e) {
    if (e is ApiError) {
      if (e.status == 401) {
        throw Exception('Usuario no autenticado. Inicia sesión nuevamente.');
      }
      if (e.status == 403) {
        throw Exception('Permisos insuficientes para operar pagos.');
      }
      // Otros códigos devuelven el mensaje del backend si viene
      final msg = e.body?['message'] ?? e.message;
      throw Exception('$msg');
    }
    // Excepción desconocida
    throw Exception(e.toString());
  }

  /// Genera clave idempotente única
  String _generateIdempotencyKey() {
    final rnd = Random();
    final hex =
        List.generate(12, (_) => rnd.nextInt(16).toRadixString(16)).join();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return 'idem-$timestamp-$hex';
  }

  /// Asegura formato YYYY-MM-DD
  String _formatDate(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Parsea monto a double con 2 decimales
  double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      String s = value.trim().replaceAll(' ', '').replaceAll('\$', '');
      if (s.contains(',') && s.contains('.')) {
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else if (s.contains(',')) {
        s = s.replaceAll(',', '.');
      }
      return double.tryParse(s) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> _mapPago(Map<String, dynamic> json) {
    return {
      'id': json['id_pago'] ?? json['id'],
      'idMensualidad': json['id_mensualidad'] ?? json['mensualidad_id'],
      'monto': _parseAmount(json['monto_pagado'] ?? json['monto']),
      'fecha': json['fecha_pago'] ?? json['fecha'],
      'metodo': json['metodo_pago'] ?? json['metodo'],
      'referencia': json['referencia'],
      'notas': json['notas'] ?? json['observaciones'],
      'activo': (json['activo'] ?? true) == true,
      'motivoAnulacion': json['motivo_anulacion'] ?? json['motivoAnulacion'],
      'creadoPor': json['creado_por'],
      'creadoPorNombre': json['creado_por_nombre'],
      'anuladoPor': json['anulado_por'],
      'anuladoPorNombre': json['anulado_por_nombre'],
      'anuladoEn': json['anulado_en'],
      'idempotencyKey': json['idempotency_key'],
    };
  }

  // ---------- LECTURAS (Tus métodos originales por ID) ----------

  /// Lista pagos de una mensualidad
  Future<List<Map<String, dynamic>>> porMensualidad(int idMensualidad) async {
    try {
      await _requireAuth();

      final res = await _http.get(
        '${Endpoints.pagos}/mensualidad/$idMensualidad',
        headers: _headers,
      );

      if (res is List) {
        return List<Map<String, dynamic>>.from(res).map(_mapPago).toList();
      }
      return const <Map<String, dynamic>>[];
    } catch (e, st) {
      debugPrint('PagosRepository.porMensualidad error: $e\n$st');
      _rethrowPretty(e);
    }
  }

  /// Resumen de pagos de una mensualidad
  /// {valor, pagado, pendiente, numPagosActivos, numPagosAnulados, estado}
  Future<Map<String, dynamic>?> resumen(int idMensualidad) async {
    try {
      await _requireAuth();

      final res = await _http.get(
        '${Endpoints.pagos}/mensualidad/$idMensualidad/resumen',
        headers: _headers,
      );

      if (res is Map) {
        final map = Map<String, dynamic>.from(res);
        return {
          'idMensualidad': map['id_mensualidad'] ?? idMensualidad,
          'valor': _parseAmount(map['valor']),
          'pagado': _parseAmount(map['pagado']),
          'pendiente': _parseAmount(map['pendiente']),
          'estado': map['estado'],
          'numPagosActivos': map['num_pagos_activos'] ?? 0,
          'numPagosAnulados': map['num_pagos_anulados'] ?? 0,
        };
      }
      return null;
    } catch (e, st) {
      debugPrint('PagosRepository.resumen error: $e\n$st');
      _rethrowPretty(e);
    }
  }


  // --- !! MÉTODOS GLOBALES QUE DEBES IMPLEMENTAR !! ---

  /*
  Future<List<Map<String, dynamic>>> getPagosGlobales({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? metodoPago,
    String? estadoPago,
  }) async {
    try {
      await _requireAuth();
      
      // 1. Construir los query parameters
      final query = <String, String>{};
      if (fechaInicio != null) query['fecha_inicio'] = _formatDate(fechaInicio);
      if (fechaFin != null) query['fecha_fin'] = _formatDate(fechaFin);
      if (metodoPago != null && metodoPago != 'todos') query['metodo'] = metodoPago;
      if (estadoPago != null && estadoPago != 'todos') query['estado'] = estadoPago;

      // 2. Llamar al endpoint global (¡DEBES CREARLO EN TU BACKEND!)
      //    ej. GET /pagos/reporte o GET /pagos
      final res = await _http.get(
        Endpoints.pagos, // O un nuevo endpoint como Endpoints.pagosReporte
        query: query,
        headers: _headers,
      );

      // 3. Mapear la respuesta
      if (res is List) {
        // Asumo que el endpoint de reporte global devolverá más datos
        // (como el nombre del estudiante), así que ajústalo según sea necesario.
        // No podrás usar _mapPago si la estructura es diferente.
        return res.cast<Map<String, dynamic>>(); 
      }
      return const <Map<String, dynamic>>[];

    } catch (e, st) {
      debugPrint('PagosRepository.getPagosGlobales error: $e\n$st');
      _rethrowPretty(e);
    }
  }

  Future<List<Map<String, dynamic>>> getResumenIngresosGlobal({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
     try {
      await _requireAuth();
      final query = <String, String>{};
      if (fechaInicio != null) query['fecha_inicio'] = _formatDate(fechaInicio);
      if (fechaFin != null) query['fecha_fin'] = _formatDate(fechaFin);

      // 2. Llamar al endpoint global (¡DEBES CREARLO EN TU BACKEND!)
      //    ej. GET /reportes/ingresos
      final res = await _http.get(
        Endpoints.reporteIngresos, // <-- Endpoint ficticio
        query: query,
        headers: _headers,
      );

      if (res is List) {
        return res.cast<Map<String, dynamic>>(); 
      }
      return const <Map<String, dynamic>>[];

    } catch (e, st) {
      debugPrint('PagosRepository.getResumenIngresosGlobal error: $e\n$st');
      _rethrowPretty(e);
    }
  }
  */

  // ---------- MUTACIONES (Tu código original) ----------

  /// Crea un pago con validación + idempotencia
  Future<Map<String, dynamic>> crear({
    required int idMensualidad,
    required double monto,
    required DateTime fecha,
    required String metodoPago, // efectivo | transferencia | tarjeta
    String? referencia,
    String? notas,
  }) async {
    try {
      await _requireAuth();

      if (monto <= 0) {
        throw Exception('El monto debe ser mayor a 0.');
      }
      if (!['efectivo', 'transferencia', 'tarjeta'].contains(metodoPago)) {
        throw Exception(
            'Método inválido: use efectivo, transferencia o tarjeta.');
      }

      final body = {
        'id_mensualidad': idMensualidad,
        'monto_pagado': double.parse(monto.toStringAsFixed(2)),
        'fecha_pago': _formatDate(fecha),
        'metodo_pago': metodoPago,
        if (referencia != null && referencia.isNotEmpty)
          'referencia': referencia,
        if (notas != null && notas.isNotEmpty) 'notas': notas,
      };

      final idempotencyKey = _generateIdempotencyKey();

      final res = await _http.post(
        Endpoints.pagos,
        headers: {
          ..._headers,
          'Idempotency-Key': idempotencyKey,
        },
        body: body,
      );

      if (res is Map && res['ok'] == true && res['data'] != null) {
        return _mapPago(Map<String, dynamic>.from(res['data']));
      }

      if (res is Map && res['ok'] == false) {
        final error =
            (res['error'] ?? res['message'] ?? 'Error desconocido').toString();
        final restante = res['restante'];
        if (restante != null) {
          final r = _parseAmount(restante).toStringAsFixed(2);
          throw Exception('$error. Restante: \$$r');
        }
        throw Exception(error);
      }

      throw Exception('Respuesta inesperada del servidor.');
    } catch (e, st) {
      debugPrint('PagosRepository.crear error: $e\n$st');
      _rethrowPretty(e);
    }
  }

  /// Actualiza un pago
  Future<Map<String, dynamic>> actualizar({
    required int idPago,
    double? monto,
    DateTime? fecha,
    String? metodoPago,
    String? referencia,
    String? notas,
  }) async {
    try {
      await _requireAuth();

      if (monto != null && monto <= 0) {
        throw Exception('El monto debe ser mayor a 0.');
      }
      if (metodoPago != null &&
          !['efectivo', 'transferencia', 'tarjeta'].contains(metodoPago)) {
        throw Exception(
            'Método inválido: use efectivo, transferencia o tarjeta.');
      }

      final body = <String, dynamic>{};
      if (monto != null)
        body['monto_pagado'] = double.parse(monto.toStringAsFixed(2));
      if (fecha != null) body['fecha_pago'] = _formatDate(fecha);
      if (metodoPago != null) body['metodo_pago'] = metodoPago;
      if (referencia != null) body['referencia'] = referencia;
      if (notas != null) body['notas'] = notas;

      if (body.isEmpty) throw Exception('No hay cambios para actualizar.');

      final res = await _http.put(
        '${Endpoints.pagos}/$idPago',
        headers: _headers,
        body: body,
      );

      if (res is Map && res['ok'] == true && res['data'] != null) {
        return _mapPago(Map<String, dynamic>.from(res['data']));
      }

      if (res is Map && res['ok'] == false) {
        final error =
            (res['error'] ?? res['message'] ?? 'Error desconocido').toString();
        final restante = res['restante'];
        if (restante != null) {
          final r = _parseAmount(restante).toStringAsFixed(2);
          throw Exception('$error. Restante: \$$r');
        }
        throw Exception(error);
      }

      throw Exception('Respuesta inesperada del servidor.');
    } catch (e, st) {
      debugPrint('PagosRepository.actualizar error: $e\n$st');
      _rethrowPretty(e);
    }
  }

  /// Anula (soft delete)
  Future<bool> anular({
    required int idPago,
    required String motivo,
  }) async {
    try {
      await _requireAuth();

      final m = motivo.trim();
      if (m.isEmpty) throw Exception('Debe proporcionar un motivo.');

      final url = '${Endpoints.pagos}/$idPago?motivo=${Uri.encodeComponent(m)}';
      await _http.delete(url, headers: _headers);

      return true; // si no lanzó excepción, OK
    } catch (e, st) {
      debugPrint('PagosRepository.anular error: $e\n$st');
      _rethrowPretty(e);
    }
  }
}