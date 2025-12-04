import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          const maxWidth = 1400.0;
          final width = constraints.maxWidth > maxWidth ? maxWidth : constraints.maxWidth;

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              child: Column(
                children: [
                  // Header moderno con gradiente
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade900, Colors.blue.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.analytics_outlined,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sistema de Reportes',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Genera reportes detallados del sistema y expórtalos en PDF',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Tabs modernos
                  Container(
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
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: Colors.blue.shade800,
                      unselectedLabelColor: Colors.grey.shade600,
                      indicatorColor: Colors.blue.shade800,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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
                        ReportePagosTab(),
                        ReporteEstudiantesTab(),
                        Center(child: Text('Asistencias')),
                        Center(child: Text('Usuarios')),
                        Center(child: Text('Financiero')),
                        Center(child: Text('Estadísticas')),
                        Center(child: Text('Personalizado')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Tab de Reportes de Pagos
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
  final TextEditingController _estudianteCedulaController = TextEditingController();

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
          _buildModernReportCard(
            icon: Icons.receipt_long,
            title: 'Reporte de Pagos Realizados',
            description: 'Lista detallada de todos los pagos con filtros personalizados',
            color: Colors.blue.shade700,
            onGenerate: () => _generarReportePagos(context),
            filters: [
              _buildDateRangePicker(),
              const SizedBox(height: 12),
              _buildMetodoPagoDropdown(),
              const SizedBox(height: 12),
              _buildEstadoPagoDropdown(),
            ],
          ),
          const SizedBox(height: 16),
          _buildModernReportCard(
            icon: Icons.pending_actions,
            title: 'Mensualidades Pendientes',
            description: 'Reporte de mensualidades vencidas y por vencer',
            color: Colors.orange.shade600,
            onGenerate: () => _generarReportePendientes(context),
          ),
          const SizedBox(height: 16),
          _buildModernReportCard(
            icon: Icons.account_balance_wallet,
            title: 'Resumen de Ingresos',
            description: 'Consolidado de ingresos por período y método de pago',
            color: Colors.green.shade600,
            onGenerate: () => _generarReporteIngresos(context),
            filters: [_buildDateRangePicker()],
          ),
          const SizedBox(height: 16),
          _buildModernReportCard(
            icon: Icons.person_outline,
            title: 'Estado de Cuenta por Estudiante',
            description: 'Historial de pagos y saldo pendiente individual',
            color: Colors.purple.shade600,
            onGenerate: () => _generarEstadoCuenta(context),
            filters: [
              TextFormField(
                controller: _estudianteCedulaController,
                decoration: _modernInputDecoration('Cédula del Estudiante', Icons.person),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernReportCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onGenerate,
    List<Widget>? filters,
  }) {
    return Card(
      elevation: 2,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.2), width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              color.withOpacity(0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (filters != null && filters.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.filter_list, size: 18, color: color),
                          const SizedBox(width: 8),
                          Text(
                            'Filtros',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...filters,
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: onGenerate,
                  icon: const Icon(Icons.picture_as_pdf, size: 20),
                  label: const Text(
                    'Generar PDF',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: color.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _modernInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.blue.shade900),
      prefixIcon: Icon(icon, color: Colors.blue.shade700),
      filled: true,
      fillColor: Colors.blue.shade50.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade800, width: 2),
      ),
      isDense: true,
    );
  }

  Widget _buildDateRangePicker() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _selectDate(context, true),
            child: InputDecorator(
              decoration: _modernInputDecoration('Desde', Icons.calendar_today),
              child: Text(
                _fechaInicio == null ? 'Seleccionar' : DateFormat('dd/MM/yyyy').format(_fechaInicio!),
                style: TextStyle(color: _fechaInicio == null ? Colors.grey : Colors.black87),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () => _selectDate(context, false),
            child: InputDecorator(
              decoration: _modernInputDecoration('Hasta', Icons.calendar_today),
              child: Text(
                _fechaFin == null ? 'Seleccionar' : DateFormat('dd/MM/yyyy').format(_fechaFin!),
                style: TextStyle(color: _fechaFin == null ? Colors.grey : Colors.black87),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetodoPagoDropdown() {
    return DropdownButtonFormField<String>(
      value: _metodoPago,
      decoration: _modernInputDecoration('Método de pago', Icons.payment),
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
      decoration: _modernInputDecoration('Estado', Icons.check_circle_outline),
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

  Future<void> _generarReportePagos(BuildContext context) async {
    _showLoadingAndGenerate(
      context,
      'Generando reporte de pagos...',
      () async {
        await Future.delayed(const Duration(seconds: 2));
        return pw.Document();
      },
    );
  }

  Future<void> _generarReportePendientes(BuildContext context) async {
    _showLoadingAndGenerate(
      context,
      'Generando deudas pendientes...',
      () async {
        await Future.delayed(const Duration(seconds: 2));
        return pw.Document();
      },
    );
  }

  Future<void> _generarReporteIngresos(BuildContext context) async {
    _showLoadingAndGenerate(
      context,
      'Generando resumen de ingresos...',
      () async {
        await Future.delayed(const Duration(seconds: 2));
        return pw.Document();
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

    _showLoadingAndGenerate(
      context,
      'Generando estado de cuenta...',
      () async {
        await Future.delayed(const Duration(seconds: 2));
        return pw.Document();
      },
    );
  }

  Future<void> _showLoadingAndGenerate(
    BuildContext context,
    String loadingText,
    Future<pw.Document> Function() generator,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                loadingText,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final pdf = await generator();
      if (!context.mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF generado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Tab de Estudiantes (simplificado)
class ReporteEstudiantesTab extends StatelessWidget {
  const ReporteEstudiantesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSimpleCard(
            context,
            icon: Icons.people,
            title: 'Lista de Estudiantes Activos',
            description: 'Todos los estudiantes actualmente matriculados',
            color: Colors.indigo.shade600,
          ),
          const SizedBox(height: 16),
          _buildSimpleCard(
            context,
            icon: Icons.people_outline,
            title: 'Lista de Estudiantes Inactivos',
            description: 'Estudiantes dados de baja',
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 16),
          _buildSimpleCard(
            context,
            icon: Icons.category,
            title: 'Estudiantes por Categoría',
            description: 'Distribución de estudiantes en categorías',
            color: Colors.teal.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}