import 'package:flutter/material.dart';
import 'package:app_porto/app/app_scope.dart';
import '../../../core/utils/input_formatters.dart';

class CrearEstudianteMatriculaScreen extends StatefulWidget {
  const CrearEstudianteMatriculaScreen({super.key});

  @override
  State<CrearEstudianteMatriculaScreen> createState() =>
      _CrearEstudianteMatriculaScreenState();
}

class _CrearEstudianteMatriculaScreenState
    extends State<CrearEstudianteMatriculaScreen> {
  // repos
  late dynamic _est;
  late dynamic _cats;
  late dynamic _subs;

  bool _inited = false;

  final _formKey = GlobalKey<FormState>();
  final _nombresCtl = TextEditingController();
  final _apellidosCtl = TextEditingController();
  final _direccionCtl = TextEditingController();
  final _telefonoCtl = TextEditingController();
  final _cicloCtl = TextEditingController();

  DateTime? _nacimiento;
  DateTime? _fechaMatricula;

  int? _catSel;
  int? _subSel;

  List<Map<String, dynamic>> _catsList = [];
  List<Map<String, dynamic>> _subsList = [];

  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    final scope = AppScope.of(context);
    _est  = scope.estudiantes;
    _cats = scope.categorias;
    _subs = scope.subcategorias;
    _inited = true;
    _loadInit();
  }

  Future<void> _loadInit() async {
    try {
      // lista simple: [{id, nombre}]
      final cats = await _cats.simpleList();
      if (!mounted) return;
      setState(() => _catsList = cats);
    } catch (_) {}
  }

  Future<void> _loadSubs(int idCategoria) async {
    try {
      final subs = await _subs.porCategoria(idCategoria); // [{id, nombre, ...}]
      if (!mounted) return;
      setState(() {
        _subsList = subs;
        _subSel = null;
      });
    } catch (_) {}
  }

  Future<void> _pickNacimiento() async {
    final now = DateTime.now();
    final sel = await showDatePicker(
      context: context,
      initialDate: _nacimiento ?? DateTime(now.year - 8, now.month, now.day),
      firstDate: DateTime(now.year - 30, 1, 1),
      lastDate: DateTime(now.year, 12, 31),
    );
    if (sel != null) setState(() => _nacimiento = sel);
  }

  Future<void> _pickFechaMatricula() async {
    final now = DateTime.now();
    final sel = await showDatePicker(
      context: context,
      initialDate: _fechaMatricula ?? now,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (sel != null) setState(() => _fechaMatricula = sel);
  }

  String? _onlyLettersValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Requerido';
    final ok = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(s);
    if (!ok) return 'Solo letras';
    return null;
  }

  String? _telefonoValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    if (!RegExp(r'^\d{6,15}$').hasMatch(s)) return 'Teléfono inválido';
    return null;
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'Seleccionar';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_catSel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría')),
      );
      return;
    }

    final nacISO = _nacimiento == null
        ? null
        : _fmt(_nacimiento);
    final matISO = _fechaMatricula == null
        ? null
        : _fmt(_fechaMatricula);

    setState(() => _saving = true);
    try {
      await _est.crearConMatricula(
        nombres: _nombresCtl.text.trim(),
        apellidos: _apellidosCtl.text.trim(),
        fechaNacimientoISO: nacISO,
        direccion: _direccionCtl.text.trim().isEmpty ? null : _direccionCtl.text.trim(),
        telefono: _telefonoCtl.text.trim().isEmpty ? null : _telefonoCtl.text.trim(),
        idCategoria: _catSel!, // requerido
        ciclo: _cicloCtl.text.trim().isEmpty ? null : _cicloCtl.text.trim(),
        fechaMatriculaISO: matISO,
        idSubcategoria: _subSel, // opcional
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Creado correctamente')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva inscripción (Estudiante + Matrícula)')),
      body: _saving
          ? const LinearProgressIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    // Datos del estudiante
                    SizedBox(
                      width: 420,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Datos del estudiante', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _nombresCtl,
                                inputFormatters: [LettersOnlyFormatter()],
                                decoration: const InputDecoration(labelText: 'Nombres'),
                                validator: _onlyLettersValidator,
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _apellidosCtl,
                                inputFormatters: [LettersOnlyFormatter()],
                                decoration: const InputDecoration(labelText: 'Apellidos'),
                                validator: _onlyLettersValidator,
                              ),
                              const SizedBox(height: 10),
                              InputDecorator(
                                decoration: const InputDecoration(labelText: 'Fecha de nacimiento'),
                                child: Row(
                                  children: [
                                    Text(_fmt(_nacimiento)),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: _pickNacimiento,
                                      icon: const Icon(Icons.calendar_today),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _direccionCtl,
                                decoration: const InputDecoration(labelText: 'Dirección (opcional)'),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _telefonoCtl,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [digitsOnly],
                                decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
                                validator: _telefonoValidator,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Inscripción
                    SizedBox(
                      width: 420,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Inscripción', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<int>(
                                value: _catSel,
                                decoration: const InputDecoration(labelText: 'Categoría'),
                                items: _catsList.map((c) {
                                  return DropdownMenuItem<int>(
                                    value: c['id'] as int,
                                    child: Text(c['nombre'] as String),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  setState(() => _catSel = v);
                                  if (v != null) _loadSubs(v);
                                },
                                validator: (v) => v == null ? 'Requerido' : null,
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<int>(
                                value: _subSel,
                                decoration: const InputDecoration(labelText: 'Subcategoría (opcional)'),
                                items: _subsList.map((s) {
                                  return DropdownMenuItem<int>(
                                    value: s['id'] as int,
                                    child: Text(s['nombre'] as String),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(() => _subSel = v),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _cicloCtl,
                                decoration: const InputDecoration(labelText: 'Ciclo (opcional)'),
                              ),
                              const SizedBox(height: 10),
                              InputDecorator(
                                decoration: const InputDecoration(labelText: 'Fecha de matrícula'),
                                child: Row(
                                  children: [
                                    Text(_fmt(_fechaMatricula)),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: _pickFechaMatricula,
                                      icon: const Icon(Icons.calendar_month),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar'),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
