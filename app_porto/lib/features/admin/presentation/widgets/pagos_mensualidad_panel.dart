// lib/features/admin/widgets/pagos_mensualidad_panel.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_porto/app/app_scope.dart';

/// Panel completo de gestión de pagos por mensualidad
class PagosMensualidadPanel extends StatefulWidget {
  final int idEstudiante;
  const PagosMensualidadPanel({super.key, required this.idEstudiante});

  @override
  State<PagosMensualidadPanel> createState() => _PagosMensualidadPanelState();
}

class _PagosMensualidadPanelState extends State<PagosMensualidadPanel> {
  late dynamic _mensRepo;
  late dynamic _pagosRepo;

  bool _loading = true;
  List<Map<String, dynamic>> _mensualidades = [];
  
  final _fmtMoney = NumberFormat.currency(locale: 'es_EC', symbol: '\$');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppScope.of(context);
    _mensRepo = scope.mensualidades;
    _pagosRepo = scope.pagos;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _mensRepo.porEstudiante(widget.idEstudiante);
      if (mounted) {
        setState(() => _mensualidades = List<Map<String, dynamic>>.from(list));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _registrarPago(Map<String, dynamic> mensualidad) async {
    final resumen = await _pagosRepo.resumen(mensualidad['id']);
    
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (_) => _PagoDialog(
        mensualidad: mensualidad,
        restante: resumen?['pendiente'] ?? mensualidad['valor'],
      ),
    );

    if (result == null) return;

    try {
      await _pagosRepo.crear(
        idMensualidad: mensualidad['id'],
        monto: result['monto'] as double,
        fecha: result['fecha'] as DateTime,
        metodoPago: result['metodo'] as String,
        referencia: result['referencia'] as String?,
        notas: result['notas'] as String?,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Pago registrado')),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _anularPago(int idPago) async {
    final motivoCtl = TextEditingController();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Anular pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Esta acción no se puede deshacer.'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoCtl,
              decoration: const InputDecoration(
                labelText: 'Motivo de anulación *',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (motivoCtl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingrese un motivo')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Anular'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final ok = await _pagosRepo.anular(
        idPago: idPago,
        motivo: motivoCtl.text.trim(),
      );

      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Pago anulado')),
          );
          await _load();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo anular el pago')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mensualidades.isEmpty) {
      return const Center(
        child: Text('No hay mensualidades registradas'),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _mensualidades.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, idx) {
          final m = _mensualidades[idx];
          return _MensualidadCard(
            mensualidad: m,
            pagosRepo: _pagosRepo,
            fmtMoney: _fmtMoney,
            onRegistrarPago: () => _registrarPago(m),
            onAnularPago: _anularPago,
          );
        },
      ),
    );
  }
}

/// Card individual de mensualidad con sus pagos
class _MensualidadCard extends StatefulWidget {
  final Map<String, dynamic> mensualidad;
  final dynamic pagosRepo;
  final NumberFormat fmtMoney;
  final VoidCallback onRegistrarPago;
  final Future<void> Function(int) onAnularPago;

  const _MensualidadCard({
    required this.mensualidad,
    required this.pagosRepo,
    required this.fmtMoney,
    required this.onRegistrarPago,
    required this.onAnularPago,
  });

  @override
  State<_MensualidadCard> createState() => _MensualidadCardState();
}

class _MensualidadCardState extends State<_MensualidadCard> {
  Map<String, dynamic>? _resumen;
  List<Map<String, dynamic>>? _pagos;
  bool _loading = false;

  Future<void> _loadData() async {
    if (_loading) return;
    
    setState(() => _loading = true);
    try {
      final resumen = await widget.pagosRepo.resumen(widget.mensualidad['id']);
      final pagos = await widget.pagosRepo.porMensualidad(widget.mensualidad['id']);
      
      if (mounted) {
        setState(() {
          _resumen = resumen;
          _pagos = List<Map<String, dynamic>>.from(pagos);
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mensualidad;
    final estado = (m['estado'] ?? 'pendiente').toString();
    final valor = _toDouble(m['valor']);

    final cs = Theme.of(context).colorScheme;
    
    Color estadoColor;
    switch (estado.toLowerCase()) {
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
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onExpansionChanged: (expanded) {
          if (expanded && _resumen == null) {
            _loadData();
          }
        },
        leading: CircleAvatar(
          backgroundColor: estadoColor,
          child: Text('${m['mes']}'),
        ),
        title: Text(
          'Mensualidad ${m['mes']}/${m['anio']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Valor: ${widget.fmtMoney.format(valor)}',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        trailing: Chip(
          label: Text(estado.toUpperCase()),
          backgroundColor: estadoColor,
        ),
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_resumen != null && _pagos != null)
            _buildContent(context)
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final r = _resumen!;
    final pagos = _pagos!;
    
    final valor = _toDouble(r['valor']);
    final pagado = _toDouble(r['pagado']);
    final pendiente = _toDouble(r['pendiente']);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _InfoChip(
                label: 'Valor',
                value: widget.fmtMoney.format(valor),
                icon: Icons.attach_money,
              ),
              _InfoChip(
                label: 'Pagado',
                value: widget.fmtMoney.format(pagado),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              _InfoChip(
                label: 'Pendiente',
                value: widget.fmtMoney.format(pendiente),
                icon: Icons.pending,
                color: pendiente > 0 ? Colors.orange : Colors.grey,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(),
          
          // Header de pagos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pagos (${r['numPagosActivos']})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              FilledButton.icon(
                onPressed: pendiente > 0 ? widget.onRegistrarPago : null,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Registrar pago'),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Lista de pagos
          if (pagos.isEmpty)
            const Text('Sin pagos registrados')
          else
            ...pagos.map((p) => _PagoTile(
              pago: p,
              fmtMoney: widget.fmtMoney,
              onAnular: widget.onAnularPago,
            )),
        ],
      ),
    );
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0.0;
  }
}

/// Chip informativo
class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
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
}

/// Tile de pago individual
class _PagoTile extends StatelessWidget {
  final Map<String, dynamic> pago;
  final NumberFormat fmtMoney;
  final Future<void> Function(int) onAnular;

  const _PagoTile({
    required this.pago,
    required this.fmtMoney,
    required this.onAnular,
  });

  @override
  Widget build(BuildContext context) {
    final activo = pago['activo'] == true;
    final monto = (pago['monto'] is num) 
        ? (pago['monto'] as num).toDouble() 
        : double.tryParse('${pago['monto']}') ?? 0.0;
    
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: activo ? null : cs.errorContainer.withOpacity(0.3),
      child: ListTile(
        dense: true,
        leading: Icon(
          activo ? Icons.check_circle : Icons.cancel,
          color: activo ? Colors.green : Colors.red,
        ),
        title: Row(
          children: [
            Text(
              fmtMoney.format(monto),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: activo ? null : TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text(pago['metodo'] ?? ''),
              labelStyle: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fecha: ${pago['fecha'] ?? ''}'),
            if (pago['referencia'] != null && '${pago['referencia']}'.isNotEmpty)
              Text('Ref: ${pago['referencia']}'),
            if (pago['notas'] != null && '${pago['notas']}'.isNotEmpty)
              Text('Notas: ${pago['notas']}'),
            if (!activo && pago['motivoAnulacion'] != null)
              Text(
                'Anulado: ${pago['motivoAnulacion']}',
                style: TextStyle(
                  color: cs.error,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: activo
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                tooltip: 'Anular pago',
                onPressed: () => onAnular(pago['id'] as int),
              )
            : null,
      ),
    );
  }
}

/// Diálogo para registrar pago
class _PagoDialog extends StatefulWidget {
  final Map<String, dynamic> mensualidad;
  final double restante;

  const _PagoDialog({
    required this.mensualidad,
    required this.restante,
  });

  @override
  State<_PagoDialog> createState() => _PagoDialogState();
}

class _PagoDialogState extends State<_PagoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _montoCtl = TextEditingController();
  
  DateTime _fecha = DateTime.now();
  String _metodo = 'efectivo';
  String? _referencia;
  String? _notas;

  final _fmtInput = NumberFormat.simpleCurrency(locale: 'es_EC', name: '', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _montoCtl.text = _fmtInput.format(widget.restante.clamp(0, double.infinity));
  }

  double _parseMonto() {
    String s = _montoCtl.text.trim().replaceAll(' ', '').replaceAll('\$', '');
    
    if (s.contains(',') && s.contains('.')) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else if (s.contains(',')) {
      s = s.replaceAll(',', '.');
    }
    
    return double.tryParse(s) ?? 0.0;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final monto = _parseMonto();
    
    Navigator.pop(context, {
      'monto': monto,
      'fecha': _fecha,
      'metodo': _metodo,
      'referencia': _referencia,
      'notas': _notas,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar pago'),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _montoCtl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Monto *',
                    prefixText: '\$ ',
                    helperText: 'Restante: ${_fmtInput.format(widget.restante)}',
                  ),
                  validator: (v) {
                    final monto = _parseMonto();
                    if (monto <= 0) return 'Ingrese un monto válido';
                    if (monto > widget.restante) {
                      return 'Sobrepago. Máximo: ${_fmtInput.format(widget.restante)}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: InputDatePickerFormField(
                        firstDate: DateTime(2020, 1, 1),
                        lastDate: DateTime(2100, 12, 31),
                        initialDate: _fecha,
                        fieldLabelText: 'Fecha de pago',
                        onDateSubmitted: (d) => setState(() => _fecha = d),
                        onDateSaved: (d) => setState(() => _fecha = d),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: _metodo,
                  decoration: const InputDecoration(labelText: 'Método de pago *'),
                  items: const [
                    DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                    DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
                    DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                  ],
                  onChanged: (v) => setState(() => _metodo = v ?? 'efectivo'),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  initialValue: _referencia,
                  decoration: const InputDecoration(
                    labelText: 'Referencia (opcional)',
                  ),
                  onChanged: (v) => _referencia = v,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  initialValue: _notas,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                  ),
                  maxLines: 2,
                  onChanged: (v) => _notas = v,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Registrar'),
        ),
      ],
    );
  }
}