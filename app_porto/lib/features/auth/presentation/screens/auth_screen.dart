import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

import '../../../../app/app_scope.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/state/auth_state.dart';
import '../../../../core/rbac/permission_gate.dart' show Permissions;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

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
      // ✅ Botón de retroceso personalizado
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver al inicio',
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            RouteNames.root,
            (_) => false,
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.surface, cs.surfaceContainerLow],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AuthScreen._maxCardWidth),
                child: Card(
                  color: cs.surface,
                  elevation: 4,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
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
      ),
    );
  }
}

// BOTÓN DE GOOGLE (Sin cambios, ya está perfecto)
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

      if (!kIsWeb) {
        final googleSignIn = GoogleSignIn(scopes: ['email']);
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          setState(() => _loading = false);
          return;
        }
        final auth = await googleUser.authentication;
        idToken = auth.idToken;
      } else {
        final auth = firebase_auth.FirebaseAuth.instance;
        final provider = firebase_auth.GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        final result = await auth.signInWithPopup(provider);
        if (result.user != null) {
          idToken = await result.user!.getIdToken(true);
        }
      }

      if (idToken == null) throw Exception("Cancelado por el usuario o error de Google.");

      final loginRes = await scope.auth.loginGoogle(idToken);

      await AuthScope.of(context).signIn(
        token: loginRes.token,
        userJson: jsonEncode(loginRes.usuario.toJson()), 
      );

      if (!mounted) return;
      try {
        await Permissions.of(context).refresh();
      } catch (e) {
        debugPrint('[GoogleLogin] Error refrescando permisos: $e');
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        widget.redirectTo,
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
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
        icon: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Image.asset("assets/img/google.png", height: 20, errorBuilder: (_,__,___) => const Icon(Icons.g_mobiledata)),
        label: const Text("Continuar con Google"),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: cs.outline.withOpacity(0.5)),
        ),
      ),
    );
  }
}

// FORMULARIO PRINCIPAL
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

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Ingresa tu correo';
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[A-Za-z]{2,}$');
    if (!regex.hasMatch(value)) return 'Formato de correo inválido';
    return null;
  }

  String? _validateNombre(String? v) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa tu nombre';
    if (text.length < 3) return 'Nombre muy corto';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
    if (widget.mode == _AuthMode.login) return null; 
    if (v.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v != _passCtrl.text) return 'Las contraseñas no coinciden';
    return null;
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
        await scope.http.post(
          '/auth/register', 
          body: {
            'nombre': _nombreCtrl.text.trim(),
            'correo': _correoCtrl.text.trim(),
            'contrasena': _passCtrl.text.trim(),
          },
        );
      }

      final loginRes = await scope.auth.login(
        correo: _correoCtrl.text.trim(),
        contrasena: _passCtrl.text.trim(),
      );

      await AuthScope.of(context).signIn(
        token: loginRes.token,
        userJson: jsonEncode(loginRes.usuario.toJson()), 
      );

      if (!mounted) return;
      try {
        await Permissions.of(context).refresh();
      } catch (e) {
        debugPrint('[Login] Error refrescando permisos: $e');
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        widget.redirectTo.isEmpty ? RouteNames.panel : widget.redirectTo,
        (_) => false,
      );

    } on SocketException catch (_) {
      setState(() => _error = 'Sin conexión a internet.');
    } catch (e) {
      setState(() => _error = e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.sports_soccer, size: 48, color: cs.primary),
        const SizedBox(height: 12),
        Text(
          widget.mode == _AuthMode.login ? '¡Hola de nuevo!' : 'Únete al equipo',
          style: t.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

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
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        Form(
          key: _form,
          child: Column(
            children: [
              if (widget.mode == _AuthMode.register) ...[
                TextFormField(
                  controller: _nombreCtrl,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateNombre,
                ),
                const SizedBox(height: 16),
              ],
              
              TextFormField(
                controller: _correoCtrl,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: _validatePassword,
              ),
              
              if (widget.mode == _AuthMode.register) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscure,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: Icon(Icons.check_circle_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateConfirm,
                ),
              ],
              
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.errorContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: cs.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: t.bodySmall?.copyWith(color: cs.error, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(widget.mode == _AuthMode.login ? 'Iniciar Sesión' : 'Crear Cuenta'),
                ),
              ),
              
              const SizedBox(height: 20),
              
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("O")),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              
              _GoogleLoginButton(redirectTo: widget.redirectTo),

              if (widget.mode == _AuthMode.login)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, RouteNames.forgotPassword),
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}