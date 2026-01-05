import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http_parser/http_parser.dart' show MediaType;

import '../../../../core/state/auth_state.dart';
import '../../../../app/app_scope.dart';
import '../../../../core/constants/endpoints.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const double maxContentWidth = 700;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();

  Uint8List? _pickedBytes;
  String? _pickedName;

  bool _loading = false;
  String? _avatarUrl;
  bool _cedulaVerificada = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMe());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _dniCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMe() async {
    try {
      final usuario = await AppScope.of(context).auth.me();
      
      _nameCtrl.text = usuario.nombre;
      _emailCtrl.text = usuario.correo;
      _dniCtrl.text = usuario.cedula ?? '';
      
      if (mounted) {
        setState(() {
          _avatarUrl = usuario.avatarUrl ?? '';
          _cedulaVerificada = _dniCtrl.text.isNotEmpty && _validarCedulaEcu(_dniCtrl.text);
        });
      }
      await AuthScope.of(context).setUser(usuario.toJson());
    } catch (e) {
      
    }
  }

  MediaType? _typeFor(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'webp':
        return MediaType('image', 'webp');
      default:
        return null;
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    setState(() {
      _pickedBytes = result.files.single.bytes!;
      _pickedName = result.files.single.name;
    });
  }

  bool _validarCedulaEcu(String? s) {
    final ci = (s ?? '').trim();
    if (ci.isEmpty) return false;
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

  void _verificarCedula() {
    final ok = _validarCedulaEcu(_dniCtrl.text);
    if (ok) {
      setState(() => _cedulaVerificada = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Cédula válida y verificada'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Text('Cédula inválida'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final http = AppScope.of(context).http;

      String? url = _avatarUrl;
      String? publicId;
      
      if (_pickedBytes != null && _pickedName != null) {
        final res = await http.uploadBytes(
          Endpoints.meAvatar,
          bytes: _pickedBytes!,
          filename: _pickedName!,
          field: 'file',
          contentType: _typeFor(_pickedName!),
        );
        if (res is Map) {
          url = (res['avatar_url'] ?? res['url'] ?? res['avatar']) as String?;
          publicId = res['public_id'] as String?;
        }
      }

      final body = <String, dynamic>{
        'nombre': _nameCtrl.text.trim(),
        if (url != null) 'avatar_url': url,
        if (publicId != null) 'avatar_public_id': publicId,
      };
      final dni = _dniCtrl.text.trim();
      if (dni.isNotEmpty) body['cedula'] = dni;

      final updated = await http.patch(
        Endpoints.me,
        body: body,
        headers: {},
      );

      Map<String, dynamic> userData;
      if (updated is Map && updated['usuario'] is Map) {
        userData = Map<String, dynamic>.from(updated['usuario'] as Map);
      } else if (updated is Map) {
        userData = Map<String, dynamic>.from(updated);
      } else {
        throw Exception('Respuesta inválida del servidor');
      }

      await AuthScope.of(context).setUser(userData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado exitosamente'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
      
      setState(() {
        _avatarUrl = userData['avatar_url'] as String?;
        _pickedBytes = null;
        _pickedName = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openChangePasswordDialog() async {
    final formKey = GlobalKey<FormState>();
    final actualCtrl = TextEditingController();
    final nuevaCtrl = TextEditingController();
    final repetirCtrl = TextEditingController();
    bool hide1 = true, hide2 = true, hide3 = true;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.blue.shade700],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_reset, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Cambiar contraseña',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                )
              ],
            ),
          ),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPasswordInput(
                    actualCtrl,
                    'Contraseña actual',
                    hide1,
                    (v) => setS(() => hide1 = v),
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordInput(
                    nuevaCtrl,
                    'Nueva contraseña',
                    hide2,
                    (v) => setS(() => hide2 = v),
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordInput(
                    repetirCtrl,
                    'Confirmar contraseña',
                    hide3,
                    (v) => setS(() => hide3 = v),
                    validator: (v) => v != nuevaCtrl.text ? 'No coinciden' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final http = AppScope.of(context).http;
                  await http.patch(
                    Endpoints.mePassword,
                    body: {
                      'contrasena_actual': actualCtrl.text,
                      'nueva_contrasena': nuevaCtrl.text,
                    },
                    headers: {},
                  );
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contraseña actualizada'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll("Exception: ", "")),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordInput(
    TextEditingController ctrl,
    String label,
    bool obscure,
    Function(bool) onToggle, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      decoration: _modernInput(label, Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: Colors.grey,
          ),
          onPressed: () => onToggle(!obscure),
        ),
      ),
      validator: validator ??
          (v) {
            if (v == null || v.isEmpty) return 'Requerido';
            if (v.length < 6) return 'Mínimo 6 caracteres';
            return null;
          },
    );
  }

  InputDecoration _modernInput(String label, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.blue.shade900),
      prefixIcon: Icon(icon, color: Colors.blue.shade700),
      filled: true,
      fillColor: Colors.blue.shade50.withOpacity(0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.blue.shade900, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.error),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final avatarWidget = Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: CircleAvatar(
            radius: 42,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: _pickedBytes != null
                ? MemoryImage(_pickedBytes!)
                : (_avatarUrl != null && _avatarUrl!.isNotEmpty
                    ? NetworkImage(_avatarUrl!) as ImageProvider
                    : null),
            child: (_avatarUrl == null || _avatarUrl!.isEmpty) && _pickedBytes == null
                ? Icon(Icons.person, size: 42, color: Colors.grey.shade400)
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Material(
            color: Colors.blue.shade800,
            shape: const CircleBorder(),
            elevation: 3,
            child: InkWell(
              onTap: _pickImage,
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(7),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
              ),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: cs.surface,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ProfileScreen.maxContentWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  
                  // Avatar
                  avatarWidget,
                  const SizedBox(height: 16),

                  Text(
                    _nameCtrl.text.isEmpty ? 'Usuario' : _nameCtrl.text,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _emailCtrl.text,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Formulario
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información Personal',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: _modernInput('Nombre completo', Icons.person_outline),
                            validator: (v) {
                              final s = v?.trim() ?? '';
                              if (s.isEmpty) return 'Ingresa tu nombre';
                              if (s.length > 40) return 'Máximo 40 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          
                          TextFormField(
                            controller: _dniCtrl,
                            enabled: !_cedulaVerificada,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: _modernInput('Cédula (Ecuador)', Icons.badge_outlined)
                                .copyWith(
                              helperText: _cedulaVerificada 
                                  ? 'Cédula verificada ✓' 
                                  : 'Formato: 10 dígitos',
                              suffixIcon: _cedulaVerificada
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : IconButton(
                                      tooltip: 'Verificar cédula',
                                      onPressed: _verificarCedula,
                                      icon: Icon(Icons.verified_outlined, color: Colors.blue.shade700),
                                    ),
                            ),
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return null;
                              if (_cedulaVerificada) return null;
                              return _validarCedulaEcu(s) ? null : 'Cédula inválida';
                            },
                          ),
                          const SizedBox(height: 14),
                          
                          TextFormField(
                            controller: _emailCtrl,
                            enabled: false,
                            decoration: _modernInput(
                              'Correo electrónico',
                              Icons.email_outlined,
                            ).copyWith(
                              fillColor: Colors.grey.shade100,
                            ),
                          ),
                          
                          const SizedBox(height: 24),

                          // Botón guardar
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: FilledButton.icon(
                              onPressed: _loading ? null : _save,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.blue.shade800,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                              icon: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_rounded),
                              label: Text(
                                _loading ? 'Guardando...' : 'GUARDAR CAMBIOS',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          
                          // Sección Seguridad
                          const Divider(height: 24),
                          const Text(
                            'Seguridad',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 10),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: OutlinedButton.icon(
                              onPressed: _openChangePasswordDialog,
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: BorderSide(color: Colors.blue.shade200),
                                foregroundColor: Colors.blue.shade800,
                              ),
                              icon: const Icon(Icons.lock_outline),
                              label: const Text('Cambiar Contraseña'),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}