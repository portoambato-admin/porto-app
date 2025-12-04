import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para AutofillHints
import '../../../../app/app_scope.dart';
import '../../../../core/constants/route_names.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  
  bool _loading = false;
  String? _error;
  bool _success = false;

  Timer? _timer;
  int _secondsRemaining = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
    
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _correoCtrl.dispose();
    _animController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _secondsRemaining = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
        if (mounted) setState(() {});
      } else {
        if (mounted) setState(() => _secondsRemaining--);
      }
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);
  }

  Future<void> _sendRequest() async {
    // Cerrar teclado primero
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

      // Usar un método similar al login, ajusta según tu AuthRepository real
      // scope.http.post(...) o scope.auth.forgotPassword(...)
      await scope.http.post(
        "/auth/password/forgot",
        body: {"correo": _correoCtrl.text.trim()},
      );

      if (!mounted) return;

      setState(() => _success = true);
      _startTimer();

    } catch (e) {
      if (!mounted) return;
      setState(() => _error = "No pudimos procesar la solicitud. Verifica tu conexión.");
      _shakeController.forward(from: 0);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bool isButtonDisabled = _loading || _secondsRemaining > 0;

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
              tooltip: 'Volver al login',
              onPressed: () => Navigator.pushReplacementNamed(context, RouteNames.auth),
            ),
          ),
        ),
        body: Stack(
          children: [
            // Optimización: Fondo estático extraído
            const _BackgroundDecoration(),
            
            // Contenido Principal
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 450),
                      child: AutofillGroup( // UX: Habilita autocompletado
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icono principal con efecto
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
                                Icons.mark_email_unread_rounded,
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
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              "¿Olvidaste tu contraseña?",
                                              style: textTheme.headlineSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: -0.5,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Ingresa tu correo y te enviaremos un enlace para recuperarla",
                                              style: textTheme.bodyMedium?.copyWith(
                                                color: cs.onSurfaceVariant,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 24),
                        
                                            _AnimatedTextField(
                                              controller: _correoCtrl,
                                              enabled: !_loading && !_success,
                                              label: "Correo electrónico",
                                              hint: "nombre@ejemplo.com",
                                              icon: Icons.email_outlined,
                                              keyboardType: TextInputType.emailAddress,
                                              autofillHints: const [AutofillHints.email],
                                              textInputAction: TextInputAction.send,
                                              onSubmitted: (_) {
                                                  if (!isButtonDisabled) _sendRequest();
                                              },
                                              validator: (v) {
                                                if (v == null || v.isEmpty) return "El correo es obligatorio";
                                                if (!_isValidEmail(v)) return "Formato de correo inválido";
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 20),
                        
                                            SizedBox(
                                              height: 48,
                                              child: FilledButton(
                                                onPressed: isButtonDisabled ? null : _sendRequest,
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
                                                    : Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(
                                                            _secondsRemaining > 0
                                                                ? Icons.timer_outlined
                                                                : (_success ? Icons.refresh_rounded : Icons.send_rounded),
                                                            size: 20,
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            _secondsRemaining > 0
                                                                ? "Reenviar en ${_secondsRemaining}s"
                                                                : (_success ? "Reenviar correo" : "Enviar enlace"),
                                                            style: const TextStyle(
                                                              fontSize: 15,
                                                              fontWeight: FontWeight.bold,
                                                              letterSpacing: 0.5,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                            ),
                        
                                            // Mensaje de éxito animado
                                            AnimatedSize(
                                              duration: const Duration(milliseconds: 300),
                                              curve: Curves.easeInOut,
                                              child: _success
                                                  ? Padding(
                                                      padding: const EdgeInsets.only(top: 20),
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
                                                              "¡Correo enviado!",
                                                              style: textTheme.titleMedium?.copyWith(
                                                                color: Colors.green[800],
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Text(
                                                              "Revisa tu bandeja de entrada. Si no aparece, verifica SPAM.",
                                                              textAlign: TextAlign.center,
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
                        
                                            // Mensaje de error animado (Shake)
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
                                                              Icon(
                                                                Icons.error_outline_rounded,
                                                                color: cs.error,
                                                                size: 20,
                                                              ),
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
                              onPressed: () => Navigator.pushReplacementNamed(context, RouteNames.auth),
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

class _AnimatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _AnimatedTextField({
    required this.controller,
    required this.enabled,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<_AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<_AnimatedTextField> {
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
          enabled: widget.enabled,
          keyboardType: widget.keyboardType,
          autofillHints: widget.autofillHints,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: Icon(widget.icon, size: 22),
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