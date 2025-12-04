import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para AutofillHints
import '../../../../app/app_scope.dart';
import '../../../../core/constants/route_names.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // FocusNodes para mejorar la navegación por teclado
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _loading = false;
  bool _validating = true;
  bool _tokenOk = false;
  String? _token;
  String? _error;
  bool _success = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    // Animación de entrada
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();

    // Animación de error (sacudida)
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readToken();
    });
  }

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    _animController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _readToken() async {
    final uri = Uri.base;
    String? token = uri.queryParameters["token"];

    if (token == null || token.isEmpty) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['token'] != null) {
        token = args['token'].toString();
      }
    }

    _token = token;

    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _validating = false;
          _tokenOk = false;
        });
      }
      return;
    }

    try {
      final scope = AppScope.of(context);
      // Validar token con el backend
      await scope.http.get("/auth/password/validate/$token");

      if (!mounted) return;
      setState(() {
        _tokenOk = true;
        _validating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _tokenOk = false;
        _validating = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    // Cerrar teclado
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      _shakeController.forward(from: 0);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = false;
    });

    try {
      final scope = AppScope.of(context);

      await scope.http.post(
        "/auth/password/reset",
        body: {
          "token": _token!,
          "nueva": _passCtrl.text.trim(),
        },
      );

      if (!mounted) return;

      setState(() => _success = true);

      // Esperar un poco para que el usuario vea el éxito antes de redirigir
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.auth,
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = "Error al actualizar. Intenta nuevamente.");
      _shakeController.forward(from: 0);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildLoadingState(ColorScheme cs) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withOpacity(0.1),
                    cs.primaryContainer.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Verificando enlace de seguridad...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme cs, TextTheme textTheme) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shadowColor: cs.error.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: cs.error.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            cs.error.withOpacity(0.15),
                            cs.errorContainer.withOpacity(0.15),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.link_off_rounded,
                        size: 56,
                        color: cs.error,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Enlace inválido o expirado",
                      style: textTheme.titleLarge?.copyWith(
                        color: cs.error,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Por motivos de seguridad, los enlaces tienen un tiempo de vida limitado.",
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            RouteNames.forgotPassword,
                            (_) => false,
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Solicitar nuevo enlace",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          RouteNames.auth,
                          (_) => false,
                        );
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Text(
                        "Volver al login",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // UX: Cierra teclado al tocar fuera
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: _tokenOk
              ? Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Cancelar',
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      RouteNames.auth,
                      (_) => false,
                    ),
                  ),
                )
              : null,
        ),
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // Optimización: Fondo estático extraído
            const _BackgroundDecoration(),

            // Contenido Principal
            SafeArea(
              child: _validating
                  ? _buildLoadingState(cs)
                  : !_tokenOk
                      ? _buildErrorState(cs, textTheme)
                      : Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 450),
                                child: AutofillGroup( // UX: Autocompletado de contraseña
                                  child: Column(
                                    children: [
                                      // Icono principal
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              cs.primary.withOpacity(0.15),
                                              cs.primaryContainer.withOpacity(0.15),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: cs.primary.withOpacity(0.2),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.lock_reset_rounded,
                                          size: 64,
                                          color: cs.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                  
                                      Card(
                                        elevation: 12,
                                        shadowColor: cs.primary.withOpacity(0.2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                          side: BorderSide(
                                            color: cs.primary.withOpacity(0.1),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(24),
                                          child: Stack(
                                            children: [
                                              // Efecto de fondo interno
                                              Positioned(
                                                top: -80,
                                                right: -80,
                                                child: Container(
                                                  width: 180,
                                                  height: 180,
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
                                                padding: const EdgeInsets.all(28),
                                                child: Form(
                                                  key: _formKey,
                                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                                    children: [
                                                      Text(
                                                        "Restablecer contraseña",
                                                        style: textTheme.headlineSmall?.copyWith(
                                                          fontWeight: FontWeight.bold,
                                                          letterSpacing: -0.5,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        "Crea una contraseña segura que no hayas usado antes",
                                                        style: textTheme.bodyMedium?.copyWith(
                                                          color: cs.onSurfaceVariant,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                      const SizedBox(height: 24),
                                  
                                                      _PasswordField(
                                                        controller: _passCtrl,
                                                        focusNode: _passFocus,
                                                        label: "Nueva contraseña",
                                                        obscureText: _obscurePass,
                                                        autofillHints: const [AutofillHints.newPassword],
                                                        textInputAction: TextInputAction.next,
                                                        onSubmitted: (_) => FocusScope.of(context).requestFocus(_confirmFocus),
                                                        onToggleVisibility: () => setState(() => _obscurePass = !_obscurePass),
                                                        validator: (v) {
                                                          if (v == null || v.isEmpty) return "Ingresa una contraseña";
                                                          if (v.length < 8) return "Mínimo 8 caracteres";
                                                          if (!RegExp(r'[A-Z]').hasMatch(v)) return "Falta una mayúscula";
                                                          if (!RegExp(r'[0-9]').hasMatch(v)) return "Falta un número";
                                                          return null;
                                                        },
                                                      ),
                                                      const SizedBox(height: 16),
                                  
                                                      _PasswordField(
                                                        controller: _confirmCtrl,
                                                        focusNode: _confirmFocus,
                                                        label: "Confirmar contraseña",
                                                        icon: Icons.check_circle_outline_rounded,
                                                        obscureText: _obscureConfirm,
                                                        autofillHints: const [AutofillHints.newPassword],
                                                        textInputAction: TextInputAction.done,
                                                        onSubmitted: (_) {
                                                          if (!_loading && !_success) _resetPassword();
                                                        },
                                                        onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                                        validator: (v) {
                                                          if (v != _passCtrl.text) return "Las contraseñas no coinciden";
                                                          return null;
                                                        },
                                                      ),
                                                      const SizedBox(height: 24),
                                  
                                                      SizedBox(
                                                        height: 48,
                                                        child: FilledButton(
                                                          onPressed: (_loading || _success) ? null : _resetPassword,
                                                          style: FilledButton.styleFrom(
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(14),
                                                            ),
                                                            elevation: 2,
                                                            shadowColor: cs.primary.withOpacity(0.4),
                                                          ),
                                                          child: _loading
                                                              ? const SizedBox(
                                                                  height: 20,
                                                                  width: 20,
                                                                  child: CircularProgressIndicator(
                                                                    strokeWidth: 2.5,
                                                                    color: Colors.white,
                                                                  ),
                                                                )
                                                              : const Row(
                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                  children: [
                                                                    Icon(Icons.check_circle_rounded, size: 20),
                                                                    SizedBox(width: 8),
                                                                    Text(
                                                                      "Cambiar contraseña",
                                                                      style: TextStyle(
                                                                        fontSize: 15,
                                                                        fontWeight: FontWeight.bold,
                                                                        letterSpacing: 0.5,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                        ),
                                                      ),
                                  
                                                      // Mensaje de error (Shake)
                                                      AnimatedSize(
                                                        duration: const Duration(milliseconds: 300),
                                                        curve: Curves.easeInOut,
                                                        child: _error != null
                                                            ? Padding(
                                                                padding: const EdgeInsets.only(top: 16),
                                                                child: AnimatedBuilder(
                                                                  animation: _shakeController,
                                                                  builder: (context, child) {
                                                                    final offset = sin(_shakeController.value * pi * 2) * 5;
                                                                    return Transform.translate(
                                                                      offset: Offset(offset, 0),
                                                                      child: child,
                                                                    );
                                                                  },
                                                                  child: Container(
                                                                    padding: const EdgeInsets.all(12),
                                                                    decoration: BoxDecoration(
                                                                      color: cs.errorContainer,
                                                                      borderRadius: BorderRadius.circular(12),
                                                                      border: Border.all(
                                                                        color: cs.error.withOpacity(0.3),
                                                                      ),
                                                                    ),
                                                                    child: Row(
                                                                      children: [
                                                                        Icon(Icons.error_outline_rounded, color: cs.error, size: 20),
                                                                        const SizedBox(width: 10),
                                                                        Expanded(
                                                                          child: Text(
                                                                            _error!,
                                                                            style: textTheme.bodySmall?.copyWith(
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
                                  
                                                      // Mensaje de éxito
                                                      AnimatedSize(
                                                        duration: const Duration(milliseconds: 300),
                                                        curve: Curves.easeInOut,
                                                        child: _success
                                                            ? Padding(
                                                                padding: const EdgeInsets.only(top: 16),
                                                                child: Container(
                                                                  padding: const EdgeInsets.all(16),
                                                                  decoration: BoxDecoration(
                                                                    gradient: LinearGradient(
                                                                      colors: [
                                                                        Colors.green.withOpacity(0.1),
                                                                        Colors.green.withOpacity(0.05),
                                                                      ],
                                                                    ),
                                                                    borderRadius: BorderRadius.circular(14),
                                                                    border: Border.all(
                                                                      color: Colors.green.withOpacity(0.3),
                                                                      width: 1.5,
                                                                    ),
                                                                  ),
                                                                  child: Column(
                                                                    children: [
                                                                      Container(
                                                                        padding: const EdgeInsets.all(8),
                                                                        decoration: BoxDecoration(
                                                                          color: Colors.green.withOpacity(0.2),
                                                                          shape: BoxShape.circle,
                                                                        ),
                                                                        child: const Icon(
                                                                          Icons.check_circle_rounded,
                                                                          color: Colors.green,
                                                                          size: 32,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(height: 12),
                                                                      Text(
                                                                        "¡Contraseña actualizada!",
                                                                        style: textTheme.titleMedium?.copyWith(
                                                                          color: Colors.green[800],
                                                                          fontWeight: FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(height: 4),
                                                                      Text(
                                                                        "Redirigiendo al inicio de sesión...",
                                                                        style: textTheme.bodySmall?.copyWith(
                                                                          color: Colors.green[900],
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              )
                                                            : const SizedBox.shrink(),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  
                                      const SizedBox(height: 20),
                                      TextButton.icon(
                                        onPressed: () {
                                          Navigator.pushNamedAndRemoveUntil(
                                            context,
                                            RouteNames.auth,
                                            (_) => false,
                                          );
                                        },
                                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                                        label: Text(
                                          "Volver al inicio de sesión",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: cs.primary,
                                          ),
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

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _PasswordField({
    required this.controller,
    required this.label,
    this.icon,
    required this.obscureText,
    required this.onToggleVisibility,
    this.validator,
    this.focusNode,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: AnimatedContainer(
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
          validator: widget.validator,
          autofillHints: widget.autofillHints,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: Icon(widget.icon ?? Icons.lock_outline_rounded, size: 22),
            suffixIcon: IconButton(
              icon: Icon(
                widget.obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: cs.onSurfaceVariant,
              ),
              onPressed: widget.onToggleVisibility,
            ),
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
            fillColor: _isFocused
                ? cs.surface
                : cs.surfaceContainerHighest.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }
}