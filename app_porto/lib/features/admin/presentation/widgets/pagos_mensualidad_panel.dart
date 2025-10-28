import 'package:flutter/material.dart';
import 'package:app_porto/app/app_scope.dart';

double _toDouble(Object? v) {
  if (v is num) return v.toDouble();
  return double.tryParse('${v ?? 0}') ?? 0;
}

/// Panel de pagos por mensualidad para el detalle de Estudiante.
/// - Lista mensualidades del estudiante
/// - Muestra pagos de cada mensualidad
/// - Permite registrar y anular pagos
class PagosMensualidadPanel extends StatefulWidget {
  final int idEstudiante;
  const PagosMensualidadPanel({super.key, required this.idEstudiante});

  @override
  State<PagosMensualidadPanel> createState() => _PagosMensualidadPanelState();
}

class _PagosMensualidadPanelState extends State<PagosMensualidadPanel> {
  // Repos — se inicializan en didChangeDependencies()
  late dynamic _mens;
  late dynamic _pag;

  bool _depsReady = false;
  bool _inited = false;

  int _refresh = 0; // fuerza el rebuild de los FutureBuilder de pagos

  bool _loading = true;
  List<Map<String, dynamic>> _mensList = [];

  @override
  void initState() {
    super.initState();
    // No leer InheritedWidgets aquí.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inited) {
      final scope = AppScope.of(context);
      _mens = scope.mensualidades;
      _pag  = scope.pagos;
      _depsReady = true;
      _inited = true;
      _load(); // ahora es seguro
    }
  }

  Future<void> _load() async {
    if (!_depsReady) return;
    setState(() => _loading = true);
    try {
      final list = await _mens.porEstudiante(widget.idEstudiante);
      if (!mounted) return;
      setState(() => _mensList = List<Map<String, dynamic>>.from(list));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando mensualidades: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _registrarPago(Map<String, dynamic> mensualidad) async {
    final formKey = GlobalKey<FormState>();
    final montoCtl = TextEditingController(
      text: (mensualidad['valor'] ?? '').toString(),
    );
    String metodo = 'efectivo';
    final obsCtl = TextEditingController();
    DateTime? fecha = DateTime.now();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registrar pago'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: montoCtl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Monto a pagar'),
                  validator: (v) {
                    final s = (v ?? '').trim().replaceAll('.', '').replaceAll(',', '.');
                    final value = double.tryParse(s);
                    if (value == null || value <= 0) return 'Monto inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: metodo,
                  decoration: const InputDecoration(labelText: 'Método de pago'),
                  items: const [
                    DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                    DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
                    DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                  ],
                  onChanged: (v) => metodo = v ?? 'efectivo',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: obsCtl,
                  decoration: const InputDecoration(labelText: 'Observaciones (opcional)'),
                  maxLines: 2,
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
                          initialDate: fecha ?? now,
                          firstDate: DateTime(now.year - 1, 1, 1),
                          lastDate: DateTime(now.year + 1, 12, 31),
                        );
                        if (sel != null) setState(() => fecha = sel);
                      },
                      child: Text(
                        fecha != null
                            ? '${fecha!.year}-${fecha!.month.toString().padLeft(2, '0')}-${fecha!.day.toString().padLeft(2, '0')}'
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

    final s = montoCtl.text.trim().replaceAll('.', '').replaceAll(',', '.');
    final monto = double.tryParse(s) ?? 0;
    final iso = fecha != null
        ? '${fecha!.year}-${fecha!.month.toString().padLeft(2, '0')}-${fecha!.day.toString().padLeft(2, '0')}'
        : null;

    try {
      final created = await _pag.crear(
        idMensualidad: mensualidad['id'],
        monto: monto,
        metodo: metodo,
        fechaISO: iso,
        observaciones: obsCtl.text,
      );
      if (!mounted) return;
      if (created != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pago registrado')));
        await _load();
        setState(() => _refresh++); // fuerza recargar FutureBuilder de pagos
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo registrar')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _anularPago(int idPago) async {
    final motivoCtl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Anular pago'),
        content: TextField(
          controller: motivoCtl,
          decoration: const InputDecoration(labelText: 'Motivo de anulación'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Anular')),
        ],
      ),
    );
    if (ok != true) return;
    if (motivoCtl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese un motivo.')));
      }
      return;
    }
    try {
      final ok = await _pag.anular(idPago: idPago, motivo: motivoCtl.text.trim());
      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pago anulado')));
          await _load();
          setState(() => _refresh++);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo anular')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) return const LinearProgressIndicator();

    if (_mensList.isEmpty) {
      return const Text('No hay mensualidades registradas para este estudiante.');
    }

    // Usamos ListView para evitar overflow en Web.
    return ListView.separated(
      itemCount: _mensList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, idx) {
        final m = _mensList[idx];
        final estado = (m['estado'] ?? '').toString();
        final valor  = _toDouble(m['valor']);
        final idMens = m['id'] as int;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            title: Row(
              children: [
                Text('Mensualidad: ${m['mes']}/${m['anio']} • '),
                Chip(
                  label: Text(estado.toUpperCase()),
                  backgroundColor: estado == 'pagado'
                      ? cs.primaryContainer
                      : (estado == 'anulado' ? cs.errorContainer : cs.secondaryContainer),
                ),
                const Spacer(),
                Text('Valor: \$${valor.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            children: [
              FutureBuilder<List<Map<String, dynamic>>>(
                key: ValueKey('mens-$idMens-$_refresh'), // recargar pagos cuando cambia _refresh
                future: _pag.porMensualidad(idMens),
                builder: (_, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: LinearProgressIndicator(),
                    );
                  }
                  final pagos = snap.data ?? [];

                  double total = 0;
                  for (final p in pagos) {
                    final v = _toDouble(p['monto']);
                    if (p['activo'] != false) total += v;
                  }
                  final pendiente = (valor - total).clamp(0, valor);

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text('Pagado: \$${total.toStringAsFixed(2)}'),
                            const SizedBox(width: 16),
                            Text('Pendiente: \$${pendiente.toStringAsFixed(2)}'),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: () => _registrarPago(m),
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar pago'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (pagos.isEmpty)
                          const Text('Sin pagos aún.')
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pagos.length,
                            separatorBuilder: (_, __) => const Divider(height: 8),
                            itemBuilder: (_, i) {
                              final p = pagos[i];
                              final activo = p['activo'] != false;
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  activo ? Icons.check_circle : Icons.cancel,
                                  color: activo ? cs.primary : cs.error,
                                ),
                                title: Text('\$${_fmtMoney(p['monto'])} - ${p['metodo'] ?? ''}'),
                                subtitle: Text('${p['fecha'] ?? ''}${p['obs'] != null ? " • ${p['obs']}" : ""}'),
                                trailing: activo
                                    ? IconButton(
                                        tooltip: 'Anular pago',
                                        icon: const Icon(Icons.undo),
                                        onPressed: () => _anularPago(p['id'] as int),
                                      )
                                    : const SizedBox.shrink(),
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
      },
    );
  }

  String _fmtMoney(Object? v) {
    final d = _toDouble(v);
    return d.toStringAsFixed(2);
  }
}
