// lib/core/rbac/permissions_warmup.dart

import 'package:flutter/widgets.dart';
import '../state/auth_state.dart';
import '../services/session_token_provider.dart';
import 'permission_gate.dart';

class PermissionsWarmup extends StatefulWidget {
  final Widget child;
  const PermissionsWarmup({super.key, required this.child});

  @override
  State<PermissionsWarmup> createState() => _PermissionsWarmupState();
}

class _PermissionsWarmupState extends State<PermissionsWarmup> {
  bool _ran = false;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ran) return;
    _ran = true;
    _warmup();
  }

  Future<void> _warmup() async {
    debugPrint('[PermissionsWarmup] 🔄 Iniciando warmup...');
    
    final auth = AuthScope.of(context);

    // 1. Cargar sesión guardada (token + user)
    await auth.load();
    debugPrint('[PermissionsWarmup] ✅ AuthState cargado');

    // 2. Verificar token
    final token = await SessionTokenProvider.instance.readToken();
    debugPrint('[PermissionsWarmup] 🔑 Token => ${token?.substring(0, 20) ?? 'null'}');

    final store = Permissions.of(context);

    if (token != null && token.isNotEmpty) {
      debugPrint('[PermissionsWarmup] 🔄 Refrescando permisos...');
      await store.refresh();
      debugPrint('[PermissionsWarmup] ✅ Permisos cargados');
    } else {
      debugPrint('[PermissionsWarmup] ⚠️ Sin token, limpiando permisos');
      store.clear();
    }

    if (mounted) {
      setState(() => _ready = true);
      debugPrint('[PermissionsWarmup] 🏁 Warmup completado');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ready ? widget.child : const SizedBox.shrink();
  }
}