import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

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
  static const double _maxCardWidth = 480;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  _AuthMode _mode = _AuthMode.login;
  String _redirectTo = '/';
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // UX: Cierra teclado al tocar fuera
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Volver al inicio',
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                RouteNames.root,
                (_) => false,
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            // Optimización: Fondo extraído para evitar repintado innecesario
            const _BackgroundDecoration(),
            
            // Contenido Principal
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: AuthScreen._maxCardWidth),
                      child: Card(
                        color: cs.surface,
                        elevation: 12,
                        shadowColor: cs.primary.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                          side: BorderSide(
                            color: cs.primary.withOpacity(0.1),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Stack(
                            children: [
                              // Decoración sutil interna de la tarjeta
                              Positioned(
                                top: -100,
                                right: -100,
                                child: Container(
                                  width: 250,
                                  height: 250,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        cs.primary.withOpacity(0.08),
                                        cs.primary.withOpacity(0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: _AuthCard(
                                  mode: _mode,
                                  onModeChange: (m) => setState(() => _mode = m),
                                  redirectTo: _redirectTo,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget optimizado para el fondo que no cambia con el teclado
class _BackgroundDecoration extends StatelessWidget {
  const _BackgroundDecoration();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ]
              : [
                  cs.primary.withOpacity(0.05),
                  cs.surface,
                  cs.primaryContainer.withOpacity(0.1),
                ],
        ),
      ),
    );
  }
}

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

class _AuthCardState extends State<_AuthCard> with SingleTickerProviderStateMixin {
  final _form = GlobalKey<FormState>();
  
  // Controllers
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // FocusNodes para navegación de teclado
  final _nombreFocus = FocusNode();
  final _correoFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _nombreFocus.dispose();
    _correoFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // --- Validadores ---
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
    
    if (!_form.currentState!.validate()) {
      _shakeController.forward(from: 0);
      return;
    }

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

      if (!mounted) return;
      await AuthScope.of(context).signIn(
        token: loginRes.token,
        userJson: jsonEncode(loginRes.usuario.toJson()), 
      );

      if (!mounted) return;
      try {
        await Permissions.of(context).refresh();
      } catch (e) {
        
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        widget.redirectTo.isEmpty ? RouteNames.panel : widget.redirectTo,
        (_) => false,
      );

    } on SocketException catch (_) {
      setState(() => _error = 'Sin conexión a internet.');
      _shakeController.forward(from: 0);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll("Exception: ", ""));
      _shakeController.forward(from: 0);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return AutofillGroup( // UX: Permite autocompletado nativo
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary.withOpacity(0.1), cs.primaryContainer.withOpacity(0.1)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sports_soccer_rounded, size: 32, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.mode == _AuthMode.login ? '¡Bienvenido!' : 'Únete al equipo',
                    style: t.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    widget.mode == _AuthMode.login
                        ? 'Inicia sesión para continuar'
                        : 'Crea tu cuenta en segundos',
                    style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Selector de Modo
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    label: 'Ingresar',
                    isSelected: widget.mode == _AuthMode.login,
                    onTap: () {
                      setState(() => _error = null);
                      widget.onModeChange(_AuthMode.login);
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _ModeButton(
                    label: 'Registro',
                    isSelected: widget.mode == _AuthMode.register,
                    onTap: () {
                      setState(() => _error = null);
                      widget.onModeChange(_AuthMode.register);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Campos del Formulario
          Form(
            key: _form,
            child: Column(
              children: [
                if (widget.mode == _AuthMode.register) ...[
                  _AnimatedTextField(
                    controller: _nombreCtrl,
                    focusNode: _nombreFocus,
                    label: 'Nombre completo',
                    icon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    validator: _validateNombre,
                    onSubmitted: (_) => FocusScope.of(context).requestFocus(_correoFocus),
                  ),
                  const SizedBox(height: 12),
                ],
                
                _AnimatedTextField(
                  controller: _correoCtrl,
                  focusNode: _correoFocus,
                  label: 'Correo electrónico',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: _validateEmail,
                  onSubmitted: (_) => FocusScope.of(context).requestFocus(_passFocus),
                ),
                const SizedBox(height: 12),
                
                _AnimatedTextField(
                  controller: _passCtrl,
                  focusNode: _passFocus,
                  label: 'Contraseña',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscure,
                  autofillHints: widget.mode == _AuthMode.login 
                      ? const [AutofillHints.password] 
                      : const [AutofillHints.newPassword],
                  textInputAction: widget.mode == _AuthMode.login 
                      ? TextInputAction.done 
                      : TextInputAction.next,
                  validator: _validatePassword,
                  onSubmitted: (_) {
                    if (widget.mode == _AuthMode.login) {
                      _submit();
                    } else {
                      FocusScope.of(context).requestFocus(_confirmFocus);
                    }
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                
                if (widget.mode == _AuthMode.register) ...[
                  const SizedBox(height: 12),
                  _AnimatedTextField(
                    controller: _confirmCtrl,
                    focusNode: _confirmFocus,
                    label: 'Confirmar contraseña',
                    icon: Icons.check_circle_outline_rounded,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    validator: _validateConfirm,
                    onSubmitted: (_) => _submit(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: cs.onSurfaceVariant,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ],
                
                // Mensaje de Error Animado (Shake)
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _error != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: AnimatedBuilder(
                            animation: _shakeController,
                            builder: (context, child) {
                              final offset = sin(_shakeController.value * pi * 2) * 5; // Un poco más fuerte
                              return Transform.translate(
                                offset: Offset(offset, 0),
                                child: child,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: cs.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: cs.error.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline_rounded, color: cs.error, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: t.bodySmall?.copyWith(
                                        color: cs.onErrorContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 20),
                
                // Botón Principal
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                      shadowColor: cs.primary.withOpacity(0.4),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.mode == _AuthMode.login ? 'Iniciar Sesión' : 'Crear Cuenta',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Separador
                Row(
                  children: [
                    Expanded(child: Divider(color: cs.outlineVariant.withOpacity(0.5))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "O continúa con",
                        style: t.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: cs.outlineVariant.withOpacity(0.5))),
                  ],
                ),
                const SizedBox(height: 16),
                
                _GoogleLoginButton(redirectTo: widget.redirectTo),

                if (widget.mode == _AuthMode.login)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, RouteNames.forgotPassword),
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(fontWeight: FontWeight.w600, color: cs.primary),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleLoginButton extends StatefulWidget {
  final String redirectTo;
  const _GoogleLoginButton({required this.redirectTo});

  @override
  State<_GoogleLoginButton> createState() => _GoogleLoginButtonState();
}

class _GoogleLoginButtonState extends State<_GoogleLoginButton> {
  bool _loading = false;
  bool _hover = false;

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
          return; // Usuario canceló
        }
        final auth = await googleUser.authentication;
        idToken = auth.idToken;
      } else {
        final auth = firebase_auth.FirebaseAuth.instance;
        final provider = firebase_auth.GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        final result = await auth.signInWithPopup(provider);
        if (result.user != null) {
          idToken = await result.user!.getIdToken(true);
        }
      }

      if (idToken == null) throw Exception("Error al obtener credenciales de Google.");

      final loginRes = await scope.auth.loginGoogle(idToken);

      if (!mounted) return;
      await AuthScope.of(context).signIn(
        token: loginRes.token,
        userJson: jsonEncode(loginRes.usuario.toJson()), 
      );

      if (!mounted) return;
      try {
        await Permissions.of(context).refresh();
      } catch (_) {}

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
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_hover ? 1.02 : 1.0),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: _loading ? null : _loginGoogle,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                color: _hover ? cs.primary.withOpacity(0.5) : cs.outline.withOpacity(0.3),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: _hover ? cs.primary.withOpacity(0.03) : Colors.transparent,
            ),
            child: _loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.primary),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/img/google.png",
                        height: 22,
                        errorBuilder: (_, __, ___) => Icon(Icons.g_mobiledata, size: 28, color: cs.primary),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Continuar con Google",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization? textCapitalization;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;

  const _AnimatedTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization,
    this.validator,
    this.suffixIcon,
    this.autofillHints,
    this.focusNode,
    this.onSubmitted,
  });

  @override
  State<_AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<_AnimatedTextField> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    // Escuchar el foco externo si se provee un FocusNode
    widget.focusNode?.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (widget.focusNode != null) {
      setState(() => _isFocused = widget.focusNode!.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    // Si no se pasa un FocusNode externo, usamos el widget Focus para detectar estado local
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: cs.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization ?? TextCapitalization.none,
        autofillHints: widget.autofillHints,
        onFieldSubmitted: widget.onSubmitted,
        validator: widget.validator,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(widget.icon, size: 22),
          suffixIcon: widget.suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cs.outline.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cs.outline.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cs.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cs.error, width: 1.5),
          ),
          filled: true,
          fillColor: _isFocused ? cs.surface : cs.surfaceContainerHighest.withOpacity(0.3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );

    if (widget.focusNode != null) return child;

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: child,
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}