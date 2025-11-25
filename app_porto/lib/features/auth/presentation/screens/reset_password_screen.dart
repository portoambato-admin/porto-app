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
  String? _success;

  @override
  void initState() {
    super.initState();
    // Esperar a que el contexto esté disponible
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
    // 🔵 CORRECCIÓN: Leer el token desde Uri.base (Flutter Web)
    // o desde RouteSettings.arguments (navegación interna)
    final uri = Uri.base;
    String? token = uri.queryParameters["token"];

    // Fallback: intentar leer desde arguments
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

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
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

      setState(() {
        _success = "Contraseña cambiada correctamente.";
      });

      // Redirigir al login después de 2 segundos
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteNames.auth,
          (_) => false,
        );
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _error = "No se pudo cambiar la contraseña. Intenta de nuevo.");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    if (_validating) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Validando enlace..."),
            ],
          ),
        ),
      );
    }

    if (!_tokenOk) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: cs.error,
                ),
                const SizedBox(height: 16),
                Text(
                  "El enlace de recuperación es inválido o ha expirado.",
                  style: t.titleMedium?.copyWith(color: cs.error),
                  textAlign: TextAlign.center,
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
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Restablecer contraseña"),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Ingresa tu nueva contraseña",
                      style: t.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Asegúrate de usar una contraseña segura",
                      style: t.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _passCtrl,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: "Nueva contraseña",
                        prefixIcon: Icon(Icons.lock_outline),
                        helperText: "Mínimo 8 caracteres, 1 mayúscula, 1 número",
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Ingresa una contraseña";
                        }
                        if (v.length < 8) return "Mínimo 8 caracteres";
                        if (!RegExp(r'[A-Z]').hasMatch(v)) {
                          return "Debe incluir una mayúscula";
                        }
                        if (!RegExp(r'[0-9]').hasMatch(v)) {
                          return "Debe incluir un número";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: "Confirmar contraseña",
                        prefixIcon: Icon(Icons.lock),
                      ),
                      validator: (v) {
                        if (v != _passCtrl.text) {
                          return "Las contraseñas no coinciden";
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _resetPassword(),
                    ),

                    const SizedBox(height: 24),

                    FilledButton(
                      onPressed: _loading ? null : _resetPassword,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text("Cambiar contraseña"),
                    ),

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
                    ],

                    if (_success != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: cs.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _success!,
                                style: TextStyle(color: cs.onPrimaryContainer),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

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
        ),
      ),
    );
  }
}