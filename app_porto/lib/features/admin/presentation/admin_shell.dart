import 'package:flutter/material.dart';
import 'widgets/admin_section_tabs.dart';
import '../../../core/state/auth_state.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.current,
    required this.title,
    required this.child,
    this.actions,
    this.fab,
    this.bottomExtra, // ← NUEVO: sub-tabs o lo que quieras debajo de los tabs de sección
  });

  final AdminSection current;
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? fab;
  final Widget? bottomExtra;

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.block, size: 48),
                  const SizedBox(height: 12),
                  const Text('No tienes acceso a esta sección'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/', (r) => false),
                    child: const Text('Volver al inicio'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final double bottomH = bottomExtra == null ? 48 : 96;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(bottomH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdminSectionTabs(current: current),
              if (bottomExtra != null)
                Material(color: Colors.transparent, child: bottomExtra!),
            ],
          ),
        ),
      ),
      body: child,
      floatingActionButton: fab,
    );
  }
}
