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

  DateTime? _nacimiento;
  DateTime? _fechaMatricula;

  int? _catSel;
  int? _subSel;

  List<Map<String, dynamic>> _catsList = [];
  List<Map<String, dynamic>> _subsList = [];

  bool _saving = false;
  bool _loadingSubs = false;

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

  Future<void> _pickNacimiento() async {
    final now = DateTime.now();
    final sel = await showDatePicker(
      context: context,
      initialDate: _nacimiento ?? DateTime(now.year - 8, now.month, now.day),
      firstDate: DateTime(now.year - 30, 1, 1),
      lastDate: DateTime(now.year, 12, 31),
      locale: const Locale('es', 'ES'),
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
      locale: const Locale('es', 'ES'),
    );
    if (sel != null) setState(() => _fechaMatricula = sel);
  }

  String? _onlyLettersValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Este campo es requerido';
    final ok = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(s);
    if (!ok) return 'Solo se permiten letras';
    return null;
  }

  String? _telefonoValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    if (!RegExp(r'^\d{6,15}$').hasMatch(s)) return 'Teléfono inválido (6-15 dígitos)';
    return null;
  }

  bool _validarCedulaEcu(String? s) {
    final ci = (s ?? '').trim();
    if (ci.isEmpty) return true;
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
    if (d == null) return 'Seleccionar';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_catSel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Por favor selecciona una categoría'),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final nacISO = _nacimiento == null
        ? null
        : '${_nacimiento!.year}-${_nacimiento!.month.toString().padLeft(2, '0')}-${_nacimiento!.day.toString().padLeft(2, '0')}';
    final matISO = _fechaMatricula == null
        ? null
        : '${_fechaMatricula!.year}-${_fechaMatricula!.month.toString().padLeft(2, '0')}-${_fechaMatricula!.day.toString().padLeft(2, '0')}';
    final ced = _cedulaCtl.text.trim().isEmpty ? null : _cedulaCtl.text.trim();

    setState(() => _saving = true);
    try {
      await _est.crearConMatricula(
        nombres: _nombresCtl.text.trim(),
        apellidos: _apellidosCtl.text.trim(),
        cedula: ced,
        fechaNacimientoISO: nacISO,
        direccion: _direccionCtl.text.trim().isEmpty ? null : _direccionCtl.text.trim(),
        telefono: _telefonoCtl.text.trim().isEmpty ? null : _telefonoCtl.text.trim(),
        idCategoria: _catSel!,
        ciclo: _cicloCtl.text.trim().isEmpty ? null : _cicloCtl.text.trim(),
        fechaMatriculaISO: matISO,
        idSubcategoria: _subSel,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Estudiante inscrito correctamente'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Nueva Inscripción'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: _saving
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primaryContainer.withOpacity(0.1),
                    theme.colorScheme.surface,
                  ],
                ),
              ),
              child: Center(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Guardando información',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Por favor espera...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primaryContainer.withOpacity(0.05),
                    theme.colorScheme.surface,
                    theme.colorScheme.secondaryContainer.withOpacity(0.03),
                  ],
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 48 : (isTablet ? 32 : 16),
                  vertical: isDesktop ? 32 : 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isDesktop ? 1400 : 1200),
                      child: Column(
                        children: [
                          // Header más atractivo
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primaryContainer,
                                  theme.colorScheme.primaryContainer.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.primary.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.person_add_alt_1_rounded,
                                    color: theme.colorScheme.onPrimary,
                                    size: isDesktop ? 36 : 28,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Registrar Nuevo Estudiante',
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Complete el formulario con los datos del estudiante',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: isDesktop ? 40 : 24),

                          // Layout responsivo
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth > 900) {
                                // Desktop: 2 columnas
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildDatosPersonales(theme)),
                                    const SizedBox(width: 24),
                                    Expanded(child: _buildDatosMatricula(theme)),
                                  ],
                                );
                              } else {
                                // Mobile/Tablet: 1 columna
                                return Column(
                                  children: [
                                    _buildDatosPersonales(theme),
                                    const SizedBox(height: 24),
                                    _buildDatosMatricula(theme),
                                  ],
                                );
                              }
                            },
                          ),

                          const SizedBox(height: 32),

                          // Botones de acción mejorados
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: theme.colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close_rounded),
                                  label: const Text('Cancelar'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                FilledButton.icon(
                                  onPressed: _submit,
                                  icon: const Icon(Icons.check_circle_rounded),
                                  label: const Text('Guardar Inscripción'),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildDatosPersonales(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.secondaryContainer.withOpacity(0.4),
                  theme.colorScheme.secondaryContainer.withOpacity(0.1),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_circle_rounded,
                    color: theme.colorScheme.onSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Datos Personales',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildTextField(
                  controller: _nombresCtl,
                  label: 'Nombres',
                  icon: Icons.person_outline_rounded,
                  validator: _onlyLettersValidator,
                  formatters: [LettersOnlyFormatter()],
                  required: true,
                  theme: theme,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _apellidosCtl,
                  label: 'Apellidos',
                  icon: Icons.person_outline_rounded,
                  validator: _onlyLettersValidator,
                  formatters: [LettersOnlyFormatter()],
                  required: true,
                  theme: theme,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _cedulaCtl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Cédula (Ecuador)',
                    hintText: '1234567890',
                    prefixIcon: Icon(Icons.badge_outlined, color: theme.colorScheme.primary),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        tooltip: 'Verificar cédula',
                        onPressed: () {
                          final ok = _validarCedulaEcu(_cedulaCtl.text);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(
                                    ok ? Icons.check_circle_rounded : Icons.error_rounded,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(ok ? '✓ Cédula válida' : '✗ Cédula inválida'),
                                ],
                              ),
                              backgroundColor: ok ? Colors.green.shade600 : Colors.red.shade600,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.verified_user_rounded,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                  validator: (v) => _validarCedulaEcu(v) ? null : 'Cédula inválida',
                ),
                const SizedBox(height: 20),
                _buildDatePicker(
                  label: 'Fecha de Nacimiento',
                  icon: Icons.cake_rounded,
                  date: _nacimiento,
                  onTap: _pickNacimiento,
                  theme: theme,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _direccionCtl,
                  label: 'Dirección',
                  icon: Icons.home_rounded,
                  maxLines: 2,
                  theme: theme,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _telefonoCtl,
                  label: 'Teléfono',
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  formatters: [digitsOnly],
                  validator: _telefonoValidator,
                  theme: theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatosMatricula(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.tertiaryContainer.withOpacity(0.4),
                  theme.colorScheme.tertiaryContainer.withOpacity(0.1),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: theme.colorScheme.onTertiary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Datos de Matrícula',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  value: _catSel,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Categoría *',
                    prefixIcon: Icon(Icons.category_rounded, color: theme.colorScheme.primary),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
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
                  validator: (v) => v == null ? 'Seleccione una categoría' : null,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  value: _subSel,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Subcategoría',
                    hintText: _loadingSubs
                        ? 'Cargando...'
                        : (_catSel == null ? 'Primero seleccione categoría' : 'Opcional'),
                    prefixIcon: Icon(Icons.subdirectory_arrow_right_rounded,
                        color: theme.colorScheme.primary),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  items: _subsList.map((s) {
                    return DropdownMenuItem<int>(
                      value: s['id'] as int,
                      child: Text(s['nombre'] as String),
                    );
                  }).toList(),
                  onChanged: _loadingSubs || _catSel == null
                      ? null
                      : (v) => setState(() => _subSel = v),
                ),
                if (_loadingSubs)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(
                      borderRadius: BorderRadius.circular(8),
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _cicloCtl,
                  label: 'Ciclo',
                  icon: Icons.calendar_view_month_rounded,
                  hint: 'Ej: 2024-2025',
                  theme: theme,
                ),
                const SizedBox(height: 20),
                _buildDatePicker(
                  label: 'Fecha de Matrícula',
                  icon: Icons.event_rounded,
                  date: _fechaMatricula,
                  onTap: _pickFechaMatricula,
                  theme: theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    String? hint,
    String? Function(String?)? validator,
    List<TextInputFormatter>? formatters,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      inputFormatters: formatters,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 2,
          ),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDatePicker({
    required String label,
    required IconData icon,
    required DateTime? date,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: theme.colorScheme.primary),
          suffixIcon: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: theme.colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
        ),
        child: Text(
          _fmt(date),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: date == null
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
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
    super.dispose();
  }
}