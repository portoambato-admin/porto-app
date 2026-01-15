import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/state/app_settings_state.dart';

class NotificacionesBell extends StatefulWidget {
  const NotificacionesBell({super.key});

  @override
  State<NotificacionesBell> createState() => _NotificacionesBellState();
}

class _NotificacionesBellState extends State<NotificacionesBell>
    with WidgetsBindingObserver {
  Timer? _timer;
  int _unread = 0;

  AppScope get _scope => AppScope.of(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    _timer = Timer.periodic(const Duration(seconds: 25), (_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    try {
      final n = await _scope.notificaciones.unreadCount();
      if (!mounted) return;
      if (n != _unread) setState(() => _unread = n);
    } catch (_) {
      // Silencioso: no interrumpe la UI.
    }
  }

  Future<void> _open() async {
    await Navigator.of(context).pushNamed(RouteNames.notificaciones);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    if (!settings.inAppNotifications) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Notificaciones',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: _open,
            icon: const Icon(Icons.notifications_outlined),
          ),
          if (settings.notificationBadge && _unread > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cs.surface, width: 1),
                ),
                constraints: const BoxConstraints(minWidth: 18),
                child: Text(
                  _unread > 99 ? '99+' : '$_unread',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
