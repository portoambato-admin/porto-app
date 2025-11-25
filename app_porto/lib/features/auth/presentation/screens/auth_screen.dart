import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';

import '../../../../app/app_scope.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/state/auth_state.dart';
import '../../../../core/rbac/permission_gate.dart' show Permissions;
import '../../../../core/services/session_token_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

// =========================================================
//                AUTH SCREEN PRINCIPAL
// =========================================================

enum _AuthMode { login, register }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  static const double _maxCardWidth = 450;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _AuthMode _mode = _AuthMode.login;
  String _redirectTo = '/';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['redirectTo'] is String) {
      _redirectTo = args['redirectTo'] as String;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      // AGREGADO: Center + SingleChildScrollView para evitar errores de overflow
      // si el teclado aparece o la pantalla es muy pequeña.
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AuthScreen._maxCardWidth),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: cs.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                  child: _AuthCard(
                    mode: _mode,
                    onModeChange: (m) => setState(() => _mode = m),
                    redirectTo: _redirectTo,
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

// =========================================================
//                GOOGLE LOGIN BUTTON
// =========================================================

class _GoogleLoginButton extends StatefulWidget {
  final String redirectTo;

  const _GoogleLoginButton({required this.redirectTo});

  @override
  State<_GoogleLoginButton> createState() => _GoogleLoginButtonState();
}

class _GoogleLoginButtonState extends State<_GoogleLoginButton> {
  bool _loading = false;
Future<void> _loginGoogle() async {
  if (_loading) return;

  setState(() => _loading = true);

  try {
    final scope = AppScope.of(context);
    String? idToken;

    // ANDROID / IOS
    if (!kIsWeb) {
      final googleSignIn = GoogleSignIn(scopes: ['email']);
      GoogleSignInAccount? googleUser = await googleSignIn.signInSilently();
      googleUser ??= await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _loading = false);
        return;
      }

      final auth = await googleUser.authentication;
      idToken = auth.idToken;
    }

    // WEB ✅ CORRECCIÓN AQUÍ
    else {
        final auth = firebase_auth.FirebaseAuth.instance;
        final provider = firebase_auth.GoogleAuthProvider();

        // Agregamos scopes para asegurar que nos devuelva el idToken
        provider.addScope('email');
        provider.addScope('profile');

        final result = await auth.signInWithPopup(provider);
        
        // ❌ ANTES (Token de Firebase - ESTO DABA ERROR EN TU BACKEND):
        // idToken = await result.user?.getIdToken();

        // ✅ AHORA (Token de Google - ESTO ES LO QUE TU BACKEND ESPERA):
        final credential = result.credential as firebase_auth.OAuthCredential?;
        idToken = credential?.idToken;
      }

    if (idToken == null) {
      throw Exception("No se pudo obtener el token de Google");
    }

    // LOGIN EN TU BACKEND
    final loginRes = await scope.auth.loginGoogle(idToken);

    await AuthScope.of(context).signIn(
      token: loginRes.token,
      userJson: jsonEncode(loginRes.user),
    );

    SessionTokenProvider.instance.clearCache();
    await Permissions.of(context).refresh();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      widget.redirectTo,
      (_) => false,
    );
  } catch (e) {
    debugPrint("GOOGLE LOGIN ERROR: $e");
    
    String errorMsg = "Error al iniciar sesión con Google";
    
    if (e.toString().contains('popup-closed-by-user')) {
      errorMsg = "Cerraste la ventana de inicio de sesión";
    } else if (e.toString().contains('popup-blocked')) {
      errorMsg = "El navegador bloqueó la ventana emergente";
    }
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMsg),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : _loginGoogle,
        // CORRECCIÓN: ErrorBuilder para que no explote si falta la imagen
        icon: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Image.asset(
                "assets/img/google.png",
                height: 20,
                // Si no encuentra la imagen, pone este icono automáticamente
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.g_mobiledata, size: 28),
              ),
        label: const Text("Continuar con Google"),
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.onSurface,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// =========================================================
//                AUTH CARD
// =========================================================

class _AuthCard extends StatefulWidget {
  final _AuthMode mode;
  final ValueChanged<_AuthMode> onModeChange;
  final String redirectTo;

  const _AuthCard({
    required this.mode,
    required this.onModeChange,
    required this.redirectTo,
  });

  @override
  State<_AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<_AuthCard> {
  final _form = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final FocusNode _correoFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _correoFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  // --- VALIDACIONES (Mismo código de antes) ---
  final List<String> _dominiosProhibidos = const [
    'tempmail', '10minutemail', 'mailinator', 'discard', 'guerrillamail', 'yopmail',
  ];
  final List<String> _contrasenasProhibidas = const [
    '12345678', 'password', 'qwerty123', 'abc12345', '123456789', 'porto123', 'admin123',
  ];

  String? _validateEmail(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Ingresa tu correo';
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[A-Za-z]{2,}$');
    if (!regex.hasMatch(value)) return 'Correo no válido';
    if (widget.mode == _AuthMode.register) {
      final dominio = value.split('@').last.toLowerCase();
      for (final bad in _dominiosProhibidos) {
        if (dominio.contains(bad)) return 'Dominio no permitido';
      }
    }
    if (value.length > 60) return 'Máximo 60 caracteres';
    return null;
  }

  String? _validateNombre(String? v) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa tu nombre completo';
    if (!RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúñÑ ]+$').hasMatch(text)) return 'Solo letras y espacios';
    if (!text.contains(' ')) return 'Incluye al menos un apellido';
    if (text.length < 5) return 'Nombre demasiado corto';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
    if (widget.mode == _AuthMode.login) return null;
    if (v.length < 8) return 'Mínimo 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Falta mayúscula';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Falta minúscula';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Falta número';
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(v)) return 'Falta caracter especial';
    if (_contrasenasProhibidas.contains(v.toLowerCase())) return 'Contraseña muy común';
    return null;
  }

  String? _validateConfirmPassword(String? _) {
    if (_confirmCtrl.text.isEmpty) return 'Confirma tu contraseña';
    if (_confirmCtrl.text != _passCtrl.text) return 'Las contraseñas no coinciden';
    return null;
  }

  int _passwordStrength(String v) {
    int score = 0;
    if (v.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(v)) score++;
    if (RegExp(r'[a-z]').hasMatch(v)) score++;
    if (RegExp(r'[0-9]').hasMatch(v)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(v)) score++;
    return score;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final scope = AppScope.of(context);
      if (widget.mode == _AuthMode.register) {
        await scope.http.post('/auth/register', body: {
          'nombre': _nombreCtrl.text.trim(),
          'correo': _correoCtrl.text.trim(),
          'contrasena': _passCtrl.text.trim(),
        });
      }

      final loginRes = await scope.auth.login(
        correo: _correoCtrl.text.trim(),
        contrasena: _passCtrl.text.trim(),
      );

      await AuthScope.of(context).signIn(
        token: loginRes.token,
        userJson: jsonEncode(loginRes.user),
      );

      SessionTokenProvider.instance.clearCache();
      try { await Permissions.of(context).refresh(); } catch (_) {}

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        widget.redirectTo.isEmpty ? RouteNames.root : widget.redirectTo,
        (_) => false,
      );
    } on SocketException catch (_) {
      setState(() => _error = 'Sin conexión a internet.');
    } catch (e) {
      String msg = e.toString().replaceAll("Exception: ", "");
      if (msg.toLowerCase().contains('connection refused') || msg.contains('unreachable')) {
        msg = 'No se pudo conectar con el servidor.';
      } else if (msg.toLowerCase().contains("clientexception")) {
         msg = "Error de conexión inesperado.";
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final strength = _passwordStrength(_passCtrl.text);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 22, color: cs.primary),
            const SizedBox(width: 8),
            Text('PortoAmbato', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),

        const SizedBox(height: 16),

        // CORRECCIÓN: Padding interno vertical reducido para que el texto no se corte
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<_AuthMode>(
            segments: const [
              ButtonSegment(value: _AuthMode.login, label: Text('Ingresar')),
              ButtonSegment(value: _AuthMode.register, label: Text('Registro')),
            ],
            selected: {widget.mode},
            onSelectionChanged: (s) {
              setState(() => _error = null);
              widget.onModeChange(s.first);
            },
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact, // Hace el botón un poco más denso
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),

        const SizedBox(height: 14),

        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            widget.mode == _AuthMode.login ? 'Bienvenido' : 'Crear cuenta',
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 8),

        Form(
          key: _form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              if (widget.mode == _AuthMode.register) ...[
                TextFormField(
                  controller: _nombreCtrl,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [LengthLimitingTextInputFormatter(40)],
                  decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person)),
                  validator: _validateNombre,
                ),
                const SizedBox(height: 10),
              ],

              TextFormField(
                controller: _correoCtrl,
                focusNode: _correoFocus,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                inputFormatters: [
                  LengthLimitingTextInputFormatter(60),
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.alternate_email)),
                validator: _validateEmail,
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _passCtrl,
                focusNode: _passFocus,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.password],
                onChanged: (_) {
                  if (widget.mode == _AuthMode.register && _confirmCtrl.text.isNotEmpty) {
                    _form.currentState?.validate();
                  }
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: _validatePassword,
              ),

              if (widget.mode == _AuthMode.register) ...[
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: strength / 5,
                  backgroundColor: cs.surfaceVariant,
                  color: {0: Colors.red, 1: Colors.red, 2: Colors.orange, 3: Colors.yellow, 4: Colors.lightGreen, 5: Colors.green}[strength],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(['Muy débil', 'Débil', 'Regular', 'Buena', 'Fuerte', 'Excelente'][strength], style: t.bodySmall),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(labelText: 'Confirmar contraseña', prefixIcon: Icon(Icons.lock_outline)),
                  validator: _validateConfirmPassword,
                ),
              ],

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(widget.mode == _AuthMode.login ? 'Ingresar' : 'Registrarme'),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              _GoogleLoginButton(redirectTo: widget.redirectTo),

              if (_error != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_error!, style: t.bodySmall?.copyWith(color: cs.error)),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            TextButton.icon(
              onPressed: _loading ? null : () => Navigator.of(context).canPop() ? Navigator.of(context).pop() : Navigator.pushReplacementNamed(context, RouteNames.root),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Recuperar contraseña'),
                  content: const Text('Muy pronto podrás recuperar tu contraseña desde aquí.'),
                  actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Entendido'))],
                ),
              ),
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ],
        ),
      ],
    );
  }
}