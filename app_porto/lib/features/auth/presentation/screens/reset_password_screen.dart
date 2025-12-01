import 'package:flutter/material.dart';
import '../../../../app/app_scope.dart';
import '../../../../core/constants/route_names.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _validating = true;
  bool _tokenOk = false;
  String? _token;
  String? _error;
  bool _success = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readToken();
    });
  }

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
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
      setState(() {
        _validating = false;
        _tokenOk = false;
      });
      return;
    }

    try {
      final scope = AppScope.of(context);
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
        "/auth/password/reset",
        body: {
          "token": _token!,
          "nueva": _passCtrl.text.trim(),
        },
      );

      if (!mounted) return;

      setState(() => _success = true);

      // ✅ Esperar 3 segundos antes de redirigir
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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            "Verificando enlace de seguridad...",
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, ColorScheme cs) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 2,
            color: cs.errorContainer.withOpacity(0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.link_off, size: 64, color: cs.error),
                  const SizedBox(height: 16),
                  Text(
                    "Enlace inválido o expirado",
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: cs.error,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Por motivos de seguridad, los enlaces tienen un tiempo de vida limitado.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        RouteNames.forgotPassword,
                        (_) => false,
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text("Solicitar nuevo enlace"),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.error,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("Volver al login"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text("Nueva contraseña"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        // ✅ Botón de retroceso (solo si el token es válido)
        leading: _tokenOk ? IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Cancelar',
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            RouteNames.auth,
            (_) => false,
          ),
        ) : null,
      ),
      body: _validating
          ? _buildLoadingState(theme)
          : !_tokenOk
              ? _buildErrorState(theme, cs)
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 450),
                      child: Column(
                        children: [
                          // ✅ Hero animado
                          Hero(
                            tag: 'auth-icon',
                            child: Icon(Icons.lock_reset, size: 80, color: cs.primary),
                          ),
                          const SizedBox(height: 24),
                          
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Form(
                                key: _formKey,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      "Restablecer contraseña",
                                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Crea una contraseña segura que no hayas usado antes.",
                                      style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 32),

                                    // ✅ CAMPO PASSWORD CON TOGGLE
                                    TextFormField(
                                      controller: _passCtrl,
                                      obscureText: _obscurePass,
                                      decoration: InputDecoration(
                                        labelText: "Nueva contraseña",
                                        prefixIcon: const Icon(Icons.lock_outline),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        helperText: "Mín. 8 caracteres, 1 mayúscula, 1 número",
                                        helperMaxLines: 2,
                                        suffixIcon: IconButton(
                                          icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                          onPressed: () => setState(() => _obscurePass = !_obscurePass),
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return "Ingresa una contraseña";
                                        if (v.length < 8) return "Mínimo 8 caracteres";
                                        if (!RegExp(r'[A-Z]').hasMatch(v)) return "Falta una mayúscula";
                                        if (!RegExp(r'[0-9]').hasMatch(v)) return "Falta un número";
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // ✅ CAMPO CONFIRMAR CON TOGGLE
                                    TextFormField(
                                      controller: _confirmCtrl,
                                      obscureText: _obscureConfirm,
                                      decoration: InputDecoration(
                                        labelText: "Confirmar contraseña",
                                        prefixIcon: const Icon(Icons.check_circle_outline),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        suffixIcon: IconButton(
                                          icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v != _passCtrl.text) return "Las contraseñas no coinciden";
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 32),

                                    // ✅ BOTÓN CON ÍCONO
                                    SizedBox(
                                      height: 48,
                                      child: FilledButton.icon(
                                        onPressed: (_loading || _success) ? null : _resetPassword,
                                        icon: _loading 
                                          ? const SizedBox.shrink()
                                          : const Icon(Icons.check_circle),
                                        label: _loading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                              )
                                            : const Text("Cambiar contraseña"),
                                        style: FilledButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),

                                    // ✅ MENSAJE ERROR
                                    if (_error != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: cs.errorContainer,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.error_outline, color: cs.error),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _error!,
                                                  style: TextStyle(color: cs.onErrorContainer),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    // ✅ MENSAJE ÉXITO MEJORADO
                                    if (_success)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.green.withOpacity(0.5)),
                                          ),
                                          child: Column(
                                            children: [
                                              const Icon(Icons.check_circle, color: Colors.green, size: 32),
                                              const SizedBox(height: 8),
                                              Text(
                                                "¡Contraseña actualizada!",
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  color: Colors.green[800],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "Redirigiendo al inicio de sesión...",
                                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.green[900]),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // ✅ BOTÓN VOLVER (siempre visible)
                          const SizedBox(height: 24),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                RouteNames.auth,
                                (_) => false,
                              );
                            },
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