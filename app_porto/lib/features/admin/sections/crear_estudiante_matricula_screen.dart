import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late dynamic _est;
  late dynamic _cats;
  late dynamic _subs;

  bool _inited = false;

  final _formKey = GlobalKey<FormState>();
  final _nombresCtl = TextEditingController();
  final _apellidosCtl = TextEditingController();
  final _cedulaCtl = TextEditingController();
  final _direccionCtl = TextEditingController();
  final _telefonoCtl = TextEditingController();
  final _cicloCtl = TextEditingController();
  // Controladores de texto para las fechas (para mostrar el valor formateado)
  final _nacimientoTxt = TextEditingController();
  final _matriculaTxt = TextEditingController();

  DateTime? _nacimiento;
  DateTime? _fechaMatricula;

  int? _catSel;
  int? _subSel;

  List<Map<String, dynamic>> _catsList = [];
  List<Map<String, dynamic>> _subsList = [];

  bool _saving = false;
  bool _loadingSubs = false;

  @override
  void initState() {
    super.initState();
    // Inicializar fechas por defecto
    _fechaMatricula = DateTime.now();
    _matriculaTxt.text = _fmt(_fechaMatricula);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    final scope = AppScope.of(context);
    _est = scope.estudiantes;
    _cats = scope.categorias;
    _subs = scope.subcategorias;
    _inited = true;
    _loadInit();
  }

  Future<void> _loadInit() async {
    try {
      final cats = await _cats.simpleList();
      if (!mounted) return;
      setState(() => _catsList = cats);
    } catch (_) {}
  }

  Future<void> _loadSubs(int idCategoria) async {
    setState(() {
      _loadingSubs = true;
      _subSel = null;
      _subsList = [];
    });

    try {
      final subs = await _subs.porCategoria(idCategoria);
      if (!mounted) return;
      setState(() {
        _subsList = subs;
        _loadingSubs = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSubs = false);
    }
  }

  // Selector de fecha con tema Azul
  Future<void> _pickDate(bool isNacimiento) async {
    final now = DateTime.now();
    final initial = isNacimiento 
        ? (_nacimiento ?? DateTime(now.year - 10, 1, 1)) 
        : (_fechaMatricula ?? now);
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: isNacimiento ? now : DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade800, // Azul fuerte para selección
              onPrimary: Colors.white,
              onSurface: Colors.blue.shade900,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blue.shade800),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isNacimiento) {
          _nacimiento = picked;
          _nacimientoTxt.text = _fmt(picked);
        } else {
          _fechaMatricula = picked;
          _matriculaTxt.text = _fmt(picked);
        }
      });
    }
  }

  String? _onlyLettersValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Requerido';
    if (s.length < 3) return 'Mínimo 3 caracteres';
    final ok = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(s);
    if (!ok) return 'Solo letras';
    return null;
  }

  String? _telefonoValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    if (!RegExp(r'^\d{7,10}$').hasMatch(s)) return 'Teléfono inválido (7-10 dígitos)';
    return null;
  }

  bool _validarCedulaEcu(String? s) {
    final ci = (s ?? '').trim();
    if (ci.isEmpty) return true; // Opcional si está vacío en backend
    if (!RegExp(r'^\d{10}$').hasMatch(ci)) return false;
    final prov = int.tryParse(ci.substring(0, 2)) ?? -1;
    if (!((prov >= 1 && prov <= 24) || prov == 30)) return false;
    final tercero = int.parse(ci[2]);
    if (tercero >= 6) return false;

    int suma = 0;
    for (int i = 0; i < 9; i++) {
      final d = int.parse(ci[i]);
      if (i % 2 == 0) {
        int k = d * 2;
        if (k >= 10) k -= 9;
        suma += k;
      } else {
        suma += d;
      }
    }
    final verif = (10 - (suma % 10)) % 10;
    return verif == int.parse(ci[9]);
  }

  String _fmt(DateTime? d) {
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor corrige los errores en el formulario'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_catSel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar una Categoría'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _est.crearConMatricula(
        nombres: _nombresCtl.text.trim(),
        apellidos: _apellidosCtl.text.trim(),
        cedula: _cedulaCtl.text.trim().isEmpty ? null : _cedulaCtl.text.trim(),
        fechaNacimientoISO: _nacimiento != null ? _fmt(_nacimiento) : null,
        direccion: _direccionCtl.text.trim().isEmpty ? null : _direccionCtl.text.trim(),
        telefono: _telefonoCtl.text.trim().isEmpty ? null : _telefonoCtl.text.trim(),
        idCategoria: _catSel!,
        ciclo: _cicloCtl.text.trim().isEmpty ? null : _cicloCtl.text.trim(),
        fechaMatriculaISO: _fechaMatricula != null ? _fmt(_fechaMatricula) : null,
        idSubcategoria: _subSel,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estudiante inscrito correctamente'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Estilo "Azul Profundo" para inputs
  InputDecoration _blueInputDeco(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: Colors.blue.shade700),
      filled: true,
      fillColor: Colors.blue.shade50.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.blue.shade100),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.blue.shade800, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Nueva Inscripción', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade900,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _saving
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.blue.shade900, strokeWidth: 3),
                  const SizedBox(height: 16),
                  Text('Guardando...', style: TextStyle(color: Colors.blue.shade900, fontSize: 16, fontWeight: FontWeight.bold))
                ],
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.blue.shade50, Colors.white],
                  stops: const [0.0, 0.3],
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 60 : (isTablet ? 32 : 16),
                  vertical: 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Sección 1: Datos Personales
                          _buildSectionTitle('Datos Personales', Icons.person_outline),
                          const SizedBox(height: 16),
                          LayoutBuilder(builder: (ctx, constraints) {
                            return Wrap(
                              spacing: 20, runSpacing: 20,
                              children: [
                                SizedBox(
                                  width: constraints.maxWidth > 600 ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth,
                                  child: TextFormField(
                                    controller: _nombresCtl,
                                    decoration: _blueInputDeco('Nombres *', Icons.badge_outlined),
                                    textCapitalization: TextCapitalization.words,
                                    validator: _onlyLettersValidator,
                                  ),
                                ),
                                SizedBox(
                                  width: constraints.maxWidth > 600 ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth,
                                  child: TextFormField(
                                    controller: _apellidosCtl,
                                    decoration: _blueInputDeco('Apellidos *', Icons.person_outline),
                                    textCapitalization: TextCapitalization.words,
                                    validator: _onlyLettersValidator,
                                  ),
                                ),
                                SizedBox(
                                  width: constraints.maxWidth > 600 ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth,
                                  child: TextFormField(
                                    controller: _cedulaCtl,
                                    decoration: _blueInputDeco('Cédula', Icons.credit_card),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                                    validator: (v) => (v == null || v.isEmpty) ? null : (_validarCedulaEcu(v) ? null : 'Cédula inválida'),
                                  ),
                                ),
                                SizedBox(
                                  width: constraints.maxWidth > 600 ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth,
                                  child: TextFormField(
                                    controller: _nacimientoTxt,
                                    decoration: _blueInputDeco('Fecha Nacimiento', Icons.cake_outlined),
                                    readOnly: true,
                                    onTap: () => _pickDate(true),
                                  ),
                                ),
                                SizedBox(
                                  width: constraints.maxWidth,
                                  child: TextFormField(
                                    controller: _direccionCtl,
                                    decoration: _blueInputDeco('Dirección', Icons.location_on_outlined),
                                    maxLines: 2,
                                  ),
                                ),
                                SizedBox(
                                  width: constraints.maxWidth > 600 ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth,
                                  child: TextFormField(
                                    controller: _telefonoCtl,
                                    decoration: _blueInputDeco('Teléfono', Icons.phone_outlined),
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    validator: _telefonoValidator,
                                  ),
                                ),
                              ],
                            );
                          }),

                          const SizedBox(height: 32),
                          
                          // Sección 2: Datos Académicos
                          _buildSectionTitle('Datos Académicos', Icons.school_outlined),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue.shade100),
                              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Column(
                              children: [
                                DropdownButtonFormField<int>(
                                  value: _catSel,
                                  decoration: _blueInputDeco('Categoría *', Icons.category_outlined),
                                  items: _catsList.map((c) => DropdownMenuItem<int>(
                                    value: c['id'] as int,
                                    child: Text(c['nombre']),
                                  )).toList(),
                                  onChanged: (v) {
                                    setState(() => _catSel = v);
                                    if (v != null) _loadSubs(v);
                                  },
                                  validator: (v) => v == null ? 'Requerido' : null,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        value: _subSel,
                                        decoration: _blueInputDeco(
                                          _loadingSubs ? 'Cargando...' : 'Subcategoría', 
                                          Icons.subdirectory_arrow_right
                                        ),
                                        items: _subsList.map((s) => DropdownMenuItem<int>(
                                          value: s['id'] as int,
                                          child: Text(s['nombre']),
                                        )).toList(),
                                        onChanged: _loadingSubs || _catSel == null ? null : (v) => setState(() => _subSel = v),
                                        disabledHint: Text(_catSel == null ? 'Seleccione Categoría' : 'Sin subcategorías'),
                                      ),
                                    ),
                                    if (_loadingSubs) const Padding(padding: EdgeInsets.only(left: 12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(child: TextFormField(controller: _cicloCtl, decoration: _blueInputDeco('Ciclo', Icons.calendar_month))),
                                    const SizedBox(width: 16),
                                    Expanded(child: TextFormField(
                                      controller: _matriculaTxt,
                                      decoration: _blueInputDeco('Fecha Matrícula', Icons.event_available),
                                      readOnly: true,
                                      onTap: () => _pickDate(false),
                                    )),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Botones
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                                  side: BorderSide(color: Colors.blue.shade800),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text('Cancelar', style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 16),
                              FilledButton.icon(
                                onPressed: _submit,
                                icon: const Icon(Icons.save_as, size: 20),
                                label: const Text('GUARDAR INSCRIPCIÓN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.blue.shade800,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.blue.shade900, size: 24),
        ),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: Colors.blue.shade100, thickness: 2)),
      ],
    );
  }

  @override
  void dispose() {
    _nombresCtl.dispose();
    _apellidosCtl.dispose();
    _cedulaCtl.dispose();
    _direccionCtl.dispose();
    _telefonoCtl.dispose();
    _cicloCtl.dispose();
    _nacimientoTxt.dispose();
    _matriculaTxt.dispose();
    super.dispose();
  }
}