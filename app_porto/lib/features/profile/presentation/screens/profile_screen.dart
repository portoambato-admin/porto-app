import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http_parser/http_parser.dart' show MediaType;

import '../../../../core/state/auth_state.dart';
import '../../../../app/app_scope.dart';
import '../../../../core/constants/endpoints.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const double maxContentWidth = 900;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _dniCtrl = TextEditingController(); // ✅ NUEVO: cédula

  Uint8List? _pickedBytes;
  String? _pickedName;

  bool _loading = false;
  String? _avatarUrl;

  // ✅ Helper para desenvolver { usuario: {...} }
  Map<String, dynamic> _unwrapUser(dynamic payload) {
    if (payload is Map && payload['usuario'] is Map) {
      return Map<String, dynamic>.from(payload['usuario'] as Map);
    }
    if (payload is Map) return Map<String, dynamic>.from(payload);
    return <String, dynamic>{};
  }

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
      final raw = await AppScope.of(context).auth.me();
      final me = _unwrapUser(raw); // ✅ desenvolver

      _nameCtrl.text = (me['nombre'] ?? '') as String;
      _emailCtrl.text = (me['correo'] ?? '') as String;
      _dniCtrl.text = (me['cedula'] ?? me['dni'] ?? me['numero_cedula'] ?? '') as String; // ✅
      if (mounted) {
        setState(() => _avatarUrl = (me['avatar_url'] as String?) ?? '');
      }
      await AuthScope.of(context).setUser(me); // ✅ guarda el user real
    } catch (_) {/* opcional: log */}
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

  // ============== Validación cédula Ecuador ==============
  bool _validarCedulaEcu(String? s) {
    final ci = (s ?? '').trim();
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

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final http = AppScope.of(context).http;

      // 1) Subir avatar si corresponde
      String? url = _avatarUrl;
      String? publicId; // ✅ capturar public_id (para avatar_public_id)
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
        if (url == null) throw Exception('Respuesta inválida al subir avatar');
      }

      // 2) Guardar perfil (incluyendo cédula si válida)
      final body = <String, dynamic>{
        'nombre': _nameCtrl.text.trim(),
        if (url != null) 'avatar_url': url,
        if (publicId != null) 'avatar_public_id': publicId, // ✅ opcional para limpieza en Cloudinary
      };
      final dni = _dniCtrl.text.trim();
      if (dni.isNotEmpty) body['cedula'] = dni; // ✅ el back valida y persiste

      final updated = await http.patch(
        Endpoints.me,
        body: body,
        headers: {},
      ) as Map<String, dynamic>;

      // ✅ desenvolver { usuario } y actualizar sesión/estado
      final u = _unwrapUser(updated);
      await AuthScope.of(context).setUser(u);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
      setState(() {
        _avatarUrl = u['avatar_url'] as String?;
        _pickedBytes = null;
        _pickedName = null;
      });
    } catch (e) {
      if (!mounted) return;
      // Nota: tu HttpClient probablemente propaga el message del back (409/400 de cédula)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
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
          title: const Text('Cambiar contraseña'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: actualCtrl,
                    obscureText: hide1,
                    decoration: InputDecoration(
                      labelText: 'Contraseña actual',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(hide1 ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setS(() => hide1 = !hide1),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nuevaCtrl,
                    obscureText: hide2,
                    decoration: InputDecoration(
                      labelText: 'Nueva contraseña',
                      prefixIcon: const Icon(Icons.lock_reset),
                      suffixIcon: IconButton(
                        icon: Icon(hide2 ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setS(() => hide2 = !hide2),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      if (v.length < 6) return 'Mínimo 6 caracteres';
                      if (v.length > 64) return 'Máximo 64 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: repetirCtrl,
                    obscureText: hide3,
                    decoration: InputDecoration(
                      labelText: 'Repetir nueva contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(hide3 ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setS(() => hide3 = !hide3),
                      ),
                    ),
                    validator: (v) => v != nuevaCtrl.text ? 'No coincide' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton.icon(
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
                    const SnackBar(content: Text('Contraseña actualizada')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final avatarWidget = CircleAvatar(
      radius: 48,
      backgroundColor: cs.primaryContainer,
      backgroundImage: _pickedBytes != null
          ? MemoryImage(_pickedBytes!)
          : (_avatarUrl != null && _avatarUrl!.isNotEmpty
              ? NetworkImage(_avatarUrl!) as ImageProvider
              : null),
      child: (_avatarUrl == null || _avatarUrl!.isEmpty) && _pickedBytes == null
          ? const Icon(Icons.person, size: 40)
          : null,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ProfileScreen.maxContentWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _form,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: LayoutBuilder(
                    builder: (ctx, c) {
                      final isNarrow = c.maxWidth < 520;

                      final header = isNarrow
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Center(child: avatarWidget),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: _pickImage,
                                    icon: const Icon(Icons.photo_camera),
                                    label: const Text('Cambiar foto'),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.password),
                                    label: const Text('Cambiar contraseña'),
                                    onPressed: _openChangePasswordDialog,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                avatarWidget,
                                const SizedBox(width: 16),
                                FilledButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.photo_camera),
                                  label: const Text('Cambiar foto'),
                                ),
                                const Spacer(),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.password),
                                  label: const Text('Cambiar contraseña'),
                                  onPressed: _openChangePasswordDialog,
                                ),
                              ],
                            );

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          header,
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (v) {
                              final s = v?.trim() ?? '';
                              if (s.isEmpty) return 'Ingresa tu nombre';
                              if (s.length > 40) return 'Máximo 40 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailCtrl,
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'Correo',
                              prefixIcon: Icon(Icons.alternate_email),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _dniCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Cédula (Ecuador)',
                              prefixIcon: const Icon(Icons.badge_outlined),
                              suffixIcon: IconButton(
                                tooltip: 'Verificar cédula',
                                onPressed: () {
                                  final ok = _validarCedulaEcu(_dniCtrl.text);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ok
                                          ? 'Cédula válida'
                                          : 'Cédula inválida'),
                                      backgroundColor:
                                          ok ? Colors.green : Colors.red,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.verified_outlined),
                              ),
                            ),
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return null; // opcional
                              return _validarCedulaEcu(s)
                                  ? null
                                  : 'Cédula inválida';
                            },
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: isNarrow ? Alignment.center : Alignment.centerRight,
                            child: SizedBox(
                              width: isNarrow ? double.infinity : null,
                              child: FilledButton.icon(
                                onPressed: _loading ? null : _save,
                                icon: _loading
                                    ? const SizedBox(
                                        height: 18, width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.save),
                                label: const Text('Guardar'),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
