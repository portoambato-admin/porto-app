// lib/features/admin/sections/estudiante_detail_screen.dart
import 'package:flutter/material.dart';
import '../../../app/app_scope.dart';

class EstudianteDetailScreen extends StatefulWidget {
  final int id;
  const EstudianteDetailScreen({super.key, required this.id});

  @override
  State<EstudianteDetailScreen> createState() => _EstudianteDetailScreenState();
}

class _EstudianteDetailScreenState extends State<EstudianteDetailScreen> with SingleTickerProviderStateMixin {
  late final _est  = AppScope.of(context).estudiantes;
  late final _mat  = AppScope.of(context).matriculas;
  late final _cats = AppScope.of(context).categorias;
  late final _asig = AppScope.of(context).subcatEst;
  late final _mens = AppScope.of(context).mensualidades;
  late final _pagos= AppScope.of(context).pagos;

  late final TabController _tab = TabController(length: 3, vsync: this);

  Map<String, dynamic>? _info;
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _matriculas = [];
  List<Map<String, dynamic>> _asignaciones = [];
  List<Map<String, dynamic>> _mensualidades = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final info  = await _est.byId(widget.id);
      final mats  = await _mat.porEstudiante(widget.id);
      final asign = await _asig.porEstudiante(widget.id);
      // mensualidades por estudiante (si tu back aún no lo soporta, verás vacío por ahora)
      final mens  = await _mens.porEstudiante(widget.id);

      setState(() {
        _info = info;
        _matriculas = mats;
        _asignaciones = asign;
        _mensualidades = mens;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ====== Matrículas ======
  Future<void> _nuevaMatricula() async {
    final formKey = GlobalKey<FormState>();
    int? catSel;
    final ciclo = TextEditingController();

    final cats = await _cats.simpleList();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nueva matrícula'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<int>(
                value: catSel,
                items: cats.map((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['nombre'] as String))).toList(),
                onChanged: (v) => catSel = v,
                decoration: const InputDecoration(labelText: 'Categoría', prefixIcon: Icon(Icons.category)),
                validator: (v) => v == null ? 'Selecciona una categoría' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: ciclo,
                decoration: const InputDecoration(labelText: 'Ciclo (opcional)'),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await _mat.crear(idEstudiante: widget.id, idCategoria: catSel!, ciclo: ciclo.text.trim().isEmpty ? null : ciclo.text.trim());
                if (mounted) Navigator.pop(context, true);
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (ok == true) _loadAll();
  }

  Future<void> _editarMatricula(Map<String, dynamic> row) async {
    final formKey = GlobalKey<FormState>();
    int? catSel = row['idCategoria'] as int?;
    final ciclo = TextEditingController(text: row['ciclo'] ?? '');

    final cats = await _cats.simpleList();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar matrícula'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<int>(
                value: catSel,
                items: cats.map((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['nombre'] as String))).toList(),
                onChanged: (v) => catSel = v,
                decoration: const InputDecoration(labelText: 'Categoría', prefixIcon: Icon(Icons.category)),
                validator: (v) => v == null ? 'Selecciona una categoría' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: ciclo,
                decoration: const InputDecoration(labelText: 'Ciclo (opcional)'),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await _mat.update(idMatricula: (row['id'] as num).toInt(), idCategoria: catSel, ciclo: ciclo.text.trim());
                if (mounted) Navigator.pop(context, true);
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (ok == true) _loadAll();
  }

  Future<void> _toggleMatricula(Map<String, dynamic> r) async {
    final activo = r['activo'] == true;
    final id = (r['id'] as num).toInt();
    try {
      if (activo) {
        await _mat.deactivate(id); // ✅ ahora existe en el repo
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Matrícula desactivada')));
      } else {
        await _mat.activate(id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Matrícula activada')));
      }
      _loadAll();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // ====== Asignaciones (subcategorías) ======
  Future<void> _asignarSubcategoria() async {
    final formKey = GlobalKey<FormState>();
    int? subcatSel;

    final subcats = await AppScope.of(context).subcategorias.todas();
    final activas = subcats.where((e) => e['activo'] == true).toList();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Asignar subcategoría'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: DropdownButtonFormField<int>(
              value: subcatSel,
              isExpanded: true,
              items: activas.map((s) => DropdownMenuItem(
                value: s['id'] as int,
                child: Text('${s['categoriaNombre'] ?? '—'}  •  ${s['nombre']}'),
              )).toList(),
              onChanged: (v) => subcatSel = v,
              validator: (v) => v == null ? 'Selecciona una subcategoría' : null,
              decoration: const InputDecoration(labelText: 'Subcategoría', prefixIcon: Icon(Icons.label)),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await _asig.asignar(idEstudiante: widget.id, idSubcategoria: subcatSel!);
                if (mounted) Navigator.pop(context, true);
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Asignar'),
          ),
        ],
      ),
    );

    if (ok == true) _loadAll();
  }

  Future<void> _eliminarAsignacion(Map<String, dynamic> r) async {
    final idSubcat = (r['idSubcategoria'] as num?)?.toInt();
    if (idSubcat == null) return;
    try {
      await _asig.eliminar(idEstudiante: widget.id, idSubcategoria: idSubcat);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asignación eliminada')));
      _loadAll();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // ====== Pagos de mensualidades ======
  Future<void> _registrarPago(Map<String, dynamic> mensualidad) async {
    final formKey = GlobalKey<FormState>();
    final monto = TextEditingController(text: (mensualidad['valor'] ?? '').toString());
    String metodo = 'efectivo';
    final obs = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registrar pago'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: monto,
                decoration: const InputDecoration(labelText: 'Monto'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final x = double.tryParse((v ?? '').replaceAll(',', '.'));
                  return (x == null || x <= 0) ? 'Monto inválido' : null;
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: metodo,
                items: const [
                  DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                  DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
                  DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                ],
                onChanged: (v) => metodo = v ?? 'efectivo',
                decoration: const InputDecoration(labelText: 'Método de pago'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: obs,
                decoration: const InputDecoration(labelText: 'Observaciones (opcional)'),
                maxLines: 2,
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final v = double.parse(monto.text.replaceAll(',', '.'));
                await _pagos.crear(
                  idMensualidad: (mensualidad['id'] as num).toInt(),
                  monto: v,
                  metodo: metodo,
                  observaciones: obs.text.trim().isEmpty ? null : obs.text.trim(),
                );
                if (mounted) Navigator.pop(context, true);
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );

    if (ok == true) _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final title = _info == null ? 'Estudiante' : '${_info!['nombres']} ${_info!['apellidos']}';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Matrículas'),
            Tab(text: 'Subcategorías'),
            Tab(text: 'Pagos'),
          ],
        ),
      ),
      floatingActionButton: switch (_tab.index) {
        0 => FloatingActionButton.extended(onPressed: _nuevaMatricula, icon: const Icon(Icons.add), label: const Text('Nueva matrícula')),
        1 => FloatingActionButton.extended(onPressed: _asignarSubcategoria, icon: const Icon(Icons.add), label: const Text('Asignar subcategoría')),
        _ => null,
      },
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? Center(child: Text(_error!))
              : TabBarView(
                  controller: _tab,
                  children: [
                    _tabMatriculas(),
                    _tabSubcategorias(),
                    _tabPagos(),
                  ],
                ),
    );
  }

  Widget _tabMatriculas() {
    if (_matriculas.isEmpty) return const Center(child: Text('Sin matrículas'));
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _matriculas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final r = _matriculas[i];
        final activo = r['activo'] == true;
        return Card(
          child: ListTile(
            leading: Icon(activo ? Icons.check_circle : Icons.cancel),
            title: Text(r['categoriaNombre'] ?? '—'),
            subtitle: Text('Ciclo: ${r['ciclo'] ?? '—'}   •   Fecha: ${r['fecha'] ?? '—'}'),
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => _editarMatricula(r)),
                IconButton(
                  icon: Icon(activo ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => _toggleMatricula(r),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tabSubcategorias() {
    if (_asignaciones.isEmpty) return const Center(child: Text('Sin asignaciones'));
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _asignaciones.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final r = _asignaciones[i];
        return Card(
          child: ListTile(
            title: Text(r['subcategoria'] ?? '—'),
            subtitle: Text('Categoría: ${r['categoria'] ?? '—'}   •   Unión: ${r['fechaUnion'] ?? '—'}'),
            trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => _eliminarAsignacion(r)),
          ),
        );
      },
    );
  }

  Widget _tabPagos() {
    // Por ahora mostramos solo mensualidades; las compras/ventas las metemos luego.
    if (_mensualidades.isEmpty) {
      return const Center(child: Text('Sin mensualidades registradas para este estudiante'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _mensualidades.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final m = _mensualidades[i];
        final estado = (m['estado'] ?? 'pendiente').toString();
        final isPagado = estado.toLowerCase() == 'pagado';
        final chipColor = isPagado ? Colors.green : (estado == 'anulado' ? Colors.grey : Colors.orange);
        return Card(
          child: ListTile(
            title: Text('Mensualidad ${m['mes']}/${m['anio']}  •  \$${(m['valor'] ?? 0)}'),
            subtitle: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(label: Text(estado.toUpperCase()), backgroundColor: chipColor.withOpacity(.15)),
              ],
            ),
            trailing: isPagado
                ? const Icon(Icons.check, color: Colors.green)
                : TextButton.icon(
                    onPressed: () => _registrarPago(m),
                    icon: const Icon(Icons.attach_money),
                    label: const Text('Pagar'),
                  ),
          ),
        );
      },
    );
  }
}
