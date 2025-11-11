import 'package:flutter/widgets.dart';
import 'permission_gate.dart'; // Permissions.of

class PermissionsWarmup extends StatefulWidget {
  final Widget child;
  const PermissionsWarmup({super.key, required this.child});

  @override
  State<PermissionsWarmup> createState() => _PermissionsWarmupState();
}

class _PermissionsWarmupState extends State<PermissionsWarmup> {
  bool _done = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_done) return;
    _done = true;
    final store = Permissions.of(context);
    // Evita que un 401 no manejado mate la app en Web
    store.refresh().catchError((_) {
      try { store.clear(); } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
