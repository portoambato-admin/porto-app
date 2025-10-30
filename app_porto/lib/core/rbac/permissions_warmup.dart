// lib/core/rbac/permissions_warmup.dart
import 'package:flutter/widgets.dart';
import 'permission_gate.dart'; // Permissions.of
import 'permissions_store.dart';

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
    if (!_done) {
      _done = true;
      final store = Permissions.of(context);
      store.refresh(); // fire & forget
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
