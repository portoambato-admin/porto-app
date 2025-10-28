import 'package:flutter/material.dart';
import 'package:app_porto/app/app_scope.dart';
import 'dart:async';

double _asDouble(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

class AdminPagosScreen extends StatefulWidget {
  final int? idEstudiante; // opcional: si viene, carga directo
  const AdminPagosScreen({super.key, this.idEstudiante});

  @override
  State<AdminPagosScreen> createState() => _AdminPagosScreenState();
}

class _AdminPagosScreenState extends State<AdminPagosScreen> {
  get _mensualidadesRepo => AppScope.of(context).mensualidades;
  get _pagosRepo => AppScope.of(context).pagos;

  final _qCtl = TextEditingController(); // búsqueda: id estudiante o categoría
  bool _soloActivos = true;
  bool _loading = false;

  int? _idEstudiante;
  String _estado = 'Todos'; // Todos | pendiente | pagado | anulado

  List<Map<String, dynamic>> _mensualidades = [];
  List<Map<String, dynamic>> _pagos = [];

  double get _totalMensualidades =>
      _mensualidades.fold<double>(0, (a, m) => a + _asDouble(m['valor']));
  double get _totalPagadoMens =>
      _mensualidades.fold<double>(0, (a, m) => a + _asDouble(m['pagado']));
  double get _restanteMens =>
      (_totalMensualidades - _totalPagadoMens).clamp(0.0, double.infinity).toDouble();

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final q = _qCtl.text.trim();
      final idNum = int.tryParse(q);

      // 1) Origen por ID estudiante explícito
      final int? idEst = _idEstudiante ?? idNum;

      List<Map<String, dynamic>> mens;
      if (idEst != null) {
        mens = await _mensualidadesRepo.byEstudiante(idEst);
      } else {
        // 2) Sin ID: lista general + filtra por estado y por categoría (cliente)
        mens = await _mensualidadesRepo.listar(
          estado: _estado != 'Todos' ? _estado : null,
        );
        if (q.isNotEmpty) {
          final qLower = q.toLowerCase();
          mens = mens.where((m) {
            final cat = (m['categoriaNombre'] ?? '').toString().toLowerCase();
            // si tu backend trae también nombre del estudiante, agrega aquí otra condición
            return cat.contains(qLower);
          }).toList();
        }
      }

      // Filtra estado si vino por estudiante (por coherencia con UI)
      if (_estado != 'Todos') {
        mens = mens.where((m) => (m['estado'] ?? '') == _estado).toList();
      }

      _mensualidades = mens;

      // 3) Cargar pagos de cada mensualidad (en paralelo y tipado)
      final List<Future<List<Map<String, dynamic>>>> futures =
          mens.map<Future<List<Map<String, dynamic>>>>((m) {
        final idMens = (m['id'] ?? m['id_mensualidad']) as int;
        return _pagosRepo.byMensualidad(
          idMensualidad: idMens,
          soloActivos: _soloActivos,
        );
      }).toList();

      final List<List<Map<String, dynamic>>> pagosPorMens = await Future.wait(futures);

      final flat = <Map<String, dynamic>>[];
      for (var i = 0; i < mens.length; i++) {
        final m = mens[i];
        final idMens = (m['id'] ?? m['id_mensualidad']) as int;
        for (final p in pagosPorMens[i]) {
          flat.add({
            ...p,
            'id_mensualidad': idMens,
            'mes': m['mes'],
            'anio': m['anio'],
            'categoria': m['categoriaNombre'],
          });
        }
      }
      _pagos = flat;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _idEstudiante = widget.idEstudiante;
    // si llegó con idEstudiante, precarga automáticamente
    scheduleMicrotask(_reload);
  }

  Future<void> _crearPago() async {
    // mensualidades con saldo
    final pendientes = _mensualidades.where((m) {
      final valor = _asDouble(m['valor']);
      final pagado = _asDouble(m['pagado']);
      return (valor - pagado) > 0.005 && (m['estado'] != 'anulado');
    }).toList();

    if (pendientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay mensualidades con saldo pendiente.')),
      );
      return;
    }

    final sel = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListView(
        children: [
          const ListTile(
            title: Text('Selecciona una mensualidad'),
            subtitle: Text('Solo con saldo pendiente'),
          ),
          ...pendientes.map((m) {
            final valor = _asDouble(m['valor']);
            final pagado = _asDouble(m['pagado']);
            final restante = (valor - pagado).clamp(0.0, valor).toDouble();
            return ListTile(
              title: Text('${m['mes']}/${m['anio']} • ${m['categoria'] ?? m['categoriaNombre'] ?? ''}'),
              subtitle: Text('Restante: \$${restante.toStringAsFixed(2)}'),
              onTap: () => Navigator.pop(ctx, m),
            );
          }),
          const SizedBox(height: 12),
        ],
      ),
    );

    if (sel == null) return;

    final idMens = (sel['id'] ?? sel['id_mensualidad']) as int;
    final valor = _asDouble(sel['valor']);
    final pagado = _asDouble(sel['pagado']);
    final restante = (valor - pagado).clamp(0.0, valor).toDouble();

    final form = GlobalKey<FormState>();
    final montoCtl = TextEditingController();
    String metodo = 'efectivo';
    String? obs;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar pago'),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Restante \$${restante.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              TextFormField(
                controller: montoCtl,
                decoration: const InputDecoration(labelText: 'Monto'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (val == null || val <= 0) return 'Monto inválido';
                  if (val > restante) return 'No puede superar el restante';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: metodo,
                onChanged: (v) => metodo = v!,
                items: const [
                  DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                  DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
                  DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                ],
                decoration: const InputDecoration(labelText: 'Método de pago'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Observaciones'),
                onChanged: (v) => obs = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final monto = double.parse(montoCtl.text.replaceAll(',', '.'));
      final created = await _pagosRepo.crear(
        idMensualidad: idMens,
        monto: monto,
        metodo: metodo,
        observaciones: obs,
      );
      if (created != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago registrado.')),
        );
        await _reload();
      }
    }
  }

  Widget _toolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          // Buscar por estudiante (ID) o categoría (texto)
          Expanded(
            child: TextField(
              controller: _qCtl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: 'Buscar por estudiante o categoría...',
                suffixIcon: _qCtl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _qCtl.clear();
                          _reload();
                        },
                      ),
              ),
              onSubmitted: (_) => _reload(),
            ),
          ),
          const SizedBox(width: 24),
          // Estado
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String>(
              value: _estado,
              onChanged: (v) async {
                setState(() => _estado = v!);
                await _reload();
              },
              items: const [
                DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                DropdownMenuItem(value: 'pagado', child: Text('Pagado')),
                DropdownMenuItem(value: 'anulado', child: Text('Anulado')),
              ],
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.filter_alt),
                labelText: 'Estado',
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Exportar (placeholder)
          OutlinedButton.icon(
            onPressed: _pagos.isEmpty
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Exportar: implementar CSV/Excel según necesidad.'),
                      ),
                    );
                  },
            icon: const Icon(Icons.download),
            label: const Text('Exportar'),
          ),
        ],
      ),
    );
  }

  Widget _resumen() {
    if (_mensualidades.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _CardResumen(title: 'Total mensualidades', amount: _totalMensualidades),
          _CardResumen(title: 'Pagado', amount: _totalPagadoMens),
          _CardResumen(title: 'Restante', amount: _restanteMens),
          FilterChip(
            selected: _soloActivos,
            label: const Text('Solo pagos activos'),
            onSelected: (v) async {
              setState(() => _soloActivos = v);
              await _reload();
            },
          ),
        ],
      ),
    );
  }

  Widget _pagosList() {
    if (_loading) return const Expanded(child: Center(child: CircularProgressIndicator()));
    if (_pagos.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'No hay datos.\nSugerencia: escribe un ID de estudiante o una categoría y presiona Enter.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        itemCount: _pagos.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final p = _pagos[i];
          final monto = _asDouble(p['monto']);
          final activo = (p['activo'] == true);
          final fecha = (p['fecha'] ?? '').toString();
          final mes = p['mes'];
          final anio = p['anio'];
          final idPago = p['id'] as int;

          return ListTile(
            leading: CircleAvatar(child: Text((i + 1).toString())),
            title: Text('\$${monto.toStringAsFixed(2)} • ${p['metodo'] ?? p['metodo_pago'] ?? ''}'),
            subtitle: Text('Mensualidad $mes/$anio  •  ${p['categoria'] ?? ''}  •  $fecha'),
            trailing: Wrap(
              spacing: 8,
              children: [
                if (activo)
                  IconButton(
                    tooltip: 'Anular',
                    icon: const Icon(Icons.cancel),
                    onPressed: () async {
                      final motivoCtl = TextEditingController();
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Anular pago'),
                          content: TextField(
                            controller: motivoCtl,
                            decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Anular')),
                          ],
                        ),
                      );
                      if (ok == true) {
                        final ok2 = await _pagosRepo.anular(idPago: idPago, motivo: motivoCtl.text);
                        if (ok2 && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pago anulado.')));
                          await _reload();
                        }
                      }
                    },
                  )
                else
                  IconButton(
                    tooltip: 'Reactivar',
                    icon: const Icon(Icons.replay),
                    onPressed: () async {
                      final ok = await _pagosRepo.activar(idPago: idPago);
                      if (ok && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pago reactivado.')));
                        await _reload();
                      }
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagos / Mensualidades')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _toolbar(),
          const Divider(height: 1),
          _resumen(),
          _pagosList(),
        ],
      ),
      floatingActionButton: (_mensualidades.isEmpty)
          ? null
          : FloatingActionButton.extended(
              onPressed: _crearPago,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo pago'),
            ),
    );
  }
}

class _CardResumen extends StatelessWidget {
  final String title;
  final double amount;
  const _CardResumen({required this.title, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('\$${amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
