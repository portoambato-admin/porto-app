import 'package:flutter/material.dart';
import '../../../../app/app_scope.dart';

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
  String? _success;

  @override
  void dispose() {
    _correoCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      final scope = AppScope.of(context);

      await scope.http.post(
        "/auth/password/forgot",
        body: {"correo": _correoCtrl.text.trim()},
      );

      setState(() {
        _success =
            "Revisa tu correo. Si existe una cuenta, recibirás un enlace para restablecer tu contraseña.";
      });
    } catch (e) {
      setState(() => _error = "No se pudo procesar la solicitud.");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Recuperar contraseña")),
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
                    "Ingresa tu correo y te enviaremos un enlace.",
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // CORREO
                  TextFormField(
                    controller: _correoCtrl,
                    decoration: const InputDecoration(
                      labelText: "Correo",
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Ingrese su correo";
                      if (!v.contains("@") || !v.contains(".")) {
                        return "Correo no válido";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // BOTÓN
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _sendRequest,
                      child: _loading
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : const Text("Enviar enlace"),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_error != null)
                    Text(_error!, style: TextStyle(color: cs.error)),

                  if (_success != null)
                    Text(
                      _success!,
                      style: TextStyle(color: cs.primary),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
