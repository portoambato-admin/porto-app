import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../state/auth_state.dart'; // ⬅️ NUEVO

enum _AuthMode { login, register }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  static const double _maxCardWidth = 420;

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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AuthScreen._maxCardWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 0,
              color: cs.surface,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: _MinimalAuthCard(
                  mode: _mode,
                  onModeChange: (m) => setState(() => _mode = m),
                  redirectTo: _redirectTo,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MinimalAuthCard extends StatefulWidget {
  const _MinimalAuthCard({
    required this.mode,
    required this.onModeChange,
    required this.redirectTo,
  });

  final _AuthMode mode;
  final ValueChanged<_AuthMode> onModeChange;
  final String redirectTo;

  @override
  State<_MinimalAuthCard> createState() => _MinimalAuthCardState();
}

class _MinimalAuthCardState extends State<_MinimalAuthCard> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _pass   = TextEditingController();
  final _correoFocus = FocusNode();
  final _passFocus   = FocusNode();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _pass.dispose();
    _correoFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Ingresa tu correo';
    final emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
    if (!emailRe.hasMatch(value)) return 'Correo no válido';
    if (value.length > 50) return 'Máximo 50 caracteres';
    return null;
  }

  String? _validatePass(String? v, {required bool isRegister}) {
    if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
    if (isRegister && v.length < 6) return 'Mínimo 6 caracteres';
    if (v.length > 20) return 'Máximo 20 caracteres';
    return null;
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      late final Map<String, String> result;
      if (widget.mode == _AuthMode.login) {
        result = await ApiService.login(
          correo: _correo.text.trim(),
          contrasena: _pass.text,
        );
      } else {
        result = await ApiService.registerAndLogin(
          nombre: _nombre.text.trim(),
          correo: _correo.text.trim(),
          contrasena: _pass.text,
        );
      }

      final token = result['token'];
      final usuarioJson = result['usuarioJson'];
      if (token == null || usuarioJson == null) {
        throw Exception('Respuesta incompleta del servidor.');
      }

      // ⬇️ Guarda y notifica a toda la app
      await AuthScope.of(context).signIn(token: token, userJson: usuarioJson);

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, widget.redirectTo, (r) => false);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception:', '').trim());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sports_soccer, size: 20),
              const SizedBox(width: 8),
              Text('PortoAmbato', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        SegmentedButton<_AuthMode>(
          segments: const [
            ButtonSegment(value: _AuthMode.login, label: Text('Ingresar'), icon: Icon(Icons.login)),
            ButtonSegment(value: _AuthMode.register, label: Text('Registro'), icon: Icon(Icons.person_add)),
          ],
          selected: {widget.mode},
          onSelectionChanged: (s) { if (s.isNotEmpty) widget.onModeChange(s.first); },
          showSelectedIcon: false,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            widget.mode == _AuthMode.login ? 'Bienvenido' : 'Crear cuenta',
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
                  controller: _nombre,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [ LengthLimitingTextInputFormatter(40) ],
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa tu nombre'
                      : (v.trim().length > 40 ? 'Máximo 40 caracteres' : null),
                  onFieldSubmitted: (_) => _correoFocus.requestFocus(),
                ),
                const SizedBox(height: 10),
              ],
              TextFormField(
                controller: _correo,
                focusNode: _correoFocus,
                autofocus: true,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(50),
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                validator: _validateEmail,
                onFieldSubmitted: (_) => _passFocus.requestFocus(),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _pass,
                focusNode: _passFocus,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(20),
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Mostrar' : 'Ocultar',
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => _validatePass(v, isRegister: widget.mode == _AuthMode.register),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : Text(widget.mode == _AuthMode.login ? 'Ingresar' : 'Registrarme'),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {}, // TODO: recuperar contraseña cuando exista
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact), // más compatible
            child: const Text('¿Olvidaste tu contraseña?'),
          ),
        ),
      ],
    );
  }
}
