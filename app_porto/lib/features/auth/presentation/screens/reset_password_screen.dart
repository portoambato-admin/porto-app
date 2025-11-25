import 'package:flutter/material.dart';
import '../../../../app/app_scope.dart';

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
    _readToken();
  }

  void _readToken() async {
    final uri = Uri.base;
    final token = uri.queryParameters["token"];
    _token = token;

    if (token == null) {
      setState(() {
        _validating = false;
        _tokenOk = false;
      });
      return;
    }

    try {
      final scope = AppScope.of(context);
      await scope.http.get("/auth/password/validate/$token");

      setState(() {
        _tokenOk = true;
        _validating = false;
      });
    } catch (e) {
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

      setState(() => _success = "Contraseña cambiada correctamente.");
    } catch (e) {
      setState(() => _error = "No se pudo cambiar la contraseña.");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_validating) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_tokenOk) {
      return Scaffold(
        body: Center(
          child: Text(
            "El enlace de recuperación es inválido o ha expirado.",
            style: TextStyle(color: cs.error, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Restablecer contraseña")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Ingresa tu nueva contraseña",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Nueva contraseña",
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Ingrese una contraseña";
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

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: true,
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
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _resetPassword,
                      child: _loading
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : const Text("Cambiar contraseña"),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: TextStyle(color: cs.error)),
                  ],

                  if (_success != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _success!,
                      style: TextStyle(color: cs.primary),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
