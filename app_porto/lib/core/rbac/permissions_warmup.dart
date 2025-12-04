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
;
    
    final auth = AuthScope.of(context);

    // 1. Cargar sesión guardada (token + user)
    await auth.load();


    // 2. Verificar token
    final token = await SessionTokenProvider.instance.readToken();
    

    final store = Permissions.of(context);

    if (token != null && token.isNotEmpty) {
      await store.refresh();
    } else {
      store.clear();
    }

    if (mounted) {
      setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ready ? widget.child : const SizedBox.shrink();
  }
}