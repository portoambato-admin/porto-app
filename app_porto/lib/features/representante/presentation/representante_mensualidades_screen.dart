import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/app_scope.dart';

class RepresentanteMensualidadDetalleScreen extends StatefulWidget {
  final int idMensualidad;
  const RepresentanteMensualidadDetalleScreen({
    super.key,
    required this.idMensualidad,
  });

  @override
  State<RepresentanteMensualidadDetalleScreen> createState() =>
      _RepresentanteMensualidadDetalleScreenState();
}

class _RepresentanteMensualidadDetalleScreenState
    extends State<RepresentanteMensualidadDetalleScreen> {
  final _fmtMoney = NumberFormat.currency(locale: 'es_EC', symbol: r'$');
  final _fmtDate = DateFormat('dd/MM/yyyy', 'es_EC');

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _detalle;
  Map<String, dynamic>? _resumen;
  List<Map<String, dynamic>> _pagos = const [];

  double _asDouble(dynamic v) =>
      (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;

  int _asInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
      _detalle = null;
      _resumen = null;
      _pagos = const [];
    });

    try {
      final repo = AppScope.of(context).representante;
      final det = await repo.detalleMensualidad(widget.idMensualidad);
      final res = await repo.resumenMensualidad(widget.idMensualidad);
      final pagos = await repo.pagosPorMensualidad(widget.idMensualidad);
      setState(() {
        _detalle = det;
        _resumen = res;
        _pagos = pagos;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pagado':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'vencido':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'pagado':
        return Icons.check_circle;
      case 'pendiente':
        return Icons.pending;
      case 'vencido':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _formatMetodoPago(String metodo) {
    final map = {
      'efectivo': 'Efectivo',
      'transferencia': 'Transferencia',
      'tarjeta': 'Tarjeta',
    };
    return map[metodo.toLowerCase()] ?? metodo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de mensualidad'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _cargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _cargar,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _detalle == null
                  ? const Center(
                      child: Text('Mensualidad no encontrada.'),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: _buildBody(context),
                    ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final d = _detalle!;
    final mes = _asInt(d['mes']);
    final anio = _asInt(d['anio']);
    final estado = (d['estado'] ?? 'pendiente').toString();
    final valor = _asDouble(d['valor']);
    final nombres = (d['nombres'] ?? '').toString();
    final apellidos = (d['apellidos'] ?? '').toString();

    final r = _resumen ?? const <String, dynamic>{};
    final pagado = _asDouble(r['pagado']);
    final pendiente = _asDouble(r['pendiente']);
    final nActivos = _asInt(
      r['num_pagos_activos'] ?? r['numPagosActivos'] ?? 0,
    );
    final nAnulados = _asInt(
      r['num_pagos_anulados'] ?? r['numPagosAnulados'] ?? 0,
    );

    final estadoColor = _getEstadoColor(estado);
    final estadoIcon = _getEstadoIcon(estado);

    // Calcular porcentaje pagado
    final porcentajePagado = valor > 0 ? (pagado / valor) * 100 : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header con información principal
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: estadoColor.withOpacity(0.2),
                      child: Icon(estadoIcon, size: 32, color: estadoColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$apellidos $nombres'.trim().isEmpty
                                ? 'Estudiante'
                                : '$apellidos $nombres',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_mesNombre(mes)} $anio',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(estadoIcon, size: 16, color: estadoColor),
                      const SizedBox(width: 6),
                      Text(
                        estado.toUpperCase(),
                        style: TextStyle(
                          color: estadoColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Resumen financiero
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen financiero',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Divider(height: 24),
                _buildFinancialRow('Valor total', valor, Colors.blue),
                const SizedBox(height: 12),
                _buildFinancialRow('Pagado', pagado, Colors.green),
                const SizedBox(height: 12),
                _buildFinancialRow('Pendiente', pendiente, Colors.orange),
                const SizedBox(height: 16),
                // Barra de progreso
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progreso de pago',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${porcentajePagado.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: porcentajePagado / 100,
                        minHeight: 12,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          porcentajePagado >= 100
                              ? Colors.green
                              : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatChip(
                        'Pagos activos',
                        '$nActivos',
                        Icons.check_circle_outline,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatChip(
                        'Pagos anulados',
                        '$nAnulados',
                        Icons.cancel_outlined,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Lista de pagos
        Text(
          'Historial de pagos',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),

        if (_pagos.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No hay pagos registrados',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ..._pagos.map((p) => _buildPagoCard(p)),
      ],
    );
  }

  Widget _buildFinancialRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        Text(
          _fmtMoney.format(value),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagoCard(Map<String, dynamic> pago) {
    final monto = _asDouble(pago['monto_pagado'] ?? pago['monto']);
    final fecha = (pago['fecha_pago'] ?? pago['fecha'] ?? '').toString();
    final metodo = (pago['metodo_pago'] ?? pago['metodo'] ?? 'No especificado').toString();
    final activo = (pago['activo'] ?? true) == true;
    
    // Campos opcionales que pueden no existir en la BD
    final referencia = pago.containsKey('referencia') 
        ? (pago['referencia'] ?? '').toString() 
        : '';
    final notas = pago.containsKey('notas') 
        ? (pago['notas'] ?? '').toString() 
        : '';
    final motivoAnulacion = pago.containsKey('motivo_anulacion')
        ? (pago['motivo_anulacion'] ?? '').toString()
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: activo ? null : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: activo
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    activo ? Icons.payments : Icons.cancel,
                    color: activo ? Colors.green : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fmtMoney.format(monto),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration:
                              activo ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      if (!activo)
                        const Text(
                          'ANULADO',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                if (activo)
                  Chip(
                    label: const Text(
                      'ACTIVO',
                      style: TextStyle(fontSize: 10),
                    ),
                    backgroundColor: Colors.green.withOpacity(0.2),
                    labelStyle: const TextStyle(color: Colors.green),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.calendar_today,
              'Fecha',
              _tryFormatDate(fecha),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.payment,
              'Método',
              _formatMetodoPago(metodo),
            ),
            if (referencia.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.receipt,
                'Referencia',
                referencia,
              ),
            ],
            if (notas.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.note,
                'Notas',
                notas,
              ),
            ],
            if (!activo && motivoAnulacion.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Motivo de anulación: $motivoAnulacion',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _tryFormatDate(String dateStr) {
    if (dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return _fmtDate.format(date);
    } catch (e) {
      return dateStr;
    }
  }
}