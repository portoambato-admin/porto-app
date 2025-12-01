import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../app/app_scope.dart';
import '../../../../core/constants/route_names.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  
  bool _loading = false;
  String? _error;
  bool _success = false;

  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _correoCtrl.dispose();
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
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
      _success = false;
    });

    try {
      final scope = AppScope.of(context);

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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bool isButtonDisabled = _loading || _secondsRemaining > 0;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text("Recuperar contraseña"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        // ✅ Botón de retroceso personalizado
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver al login',
          onPressed: () => Navigator.pushReplacementNamed(context, RouteNames.auth),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ Hero animado
                Hero(
                  tag: 'auth-icon',
                  child: Icon(
                    Icons.mark_email_unread_outlined, 
                    size: 80, 
                    color: cs.primary
                  ),
                ),
                const SizedBox(height: 24),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "¿Olvidaste tu contraseña?",
                            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Ingresa tu correo y te enviaremos un enlace mágico para recuperarla.",
                            style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          TextFormField(
                            controller: _correoCtrl,
                            enabled: !_loading && !_success,
                            decoration: InputDecoration(
                              labelText: "Correo electrónico",
                              hintText: "nombre@ejemplo.com",
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: cs.surfaceContainerLow,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return "El correo es obligatorio";
                              if (!_isValidEmail(v)) return "Formato de correo inválido";
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: isButtonDisabled ? null : _sendRequest,
                              icon: _loading 
                                ? const SizedBox.shrink()
                                : Icon(_success ? Icons.refresh : Icons.send),
                              label: _loading
                                  ? const SizedBox(
                                      height: 20, width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      _secondsRemaining > 0 
                                      ? "Reenviar en ${_secondsRemaining}s" 
                                      : (_success ? "Reenviar correo" : "Enviar enlace"),
                                    ),
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),

                          // ✅ MENSAJE DE ÉXITO MEJORADO
                          if (_success) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.withOpacity(0.5)),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    "¡Correo enviado!",
                                    style: textTheme.titleMedium?.copyWith(
                                      color: Colors.green[800], 
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Revisa tu bandeja de entrada. Si no aparece, verifica SPAM.",
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodySmall?.copyWith(color: Colors.green[900]),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // ✅ MENSAJE DE ERROR
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cs.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: cs.error),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: TextStyle(color: cs.onErrorContainer),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
                
                // ✅ BOTÓN VOLVER AL LOGIN (siempre visible)
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(context, RouteNames.auth),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("Volver al inicio de sesión"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}