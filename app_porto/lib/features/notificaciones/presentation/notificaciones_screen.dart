import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/app_scope.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  bool _loading = true;
  String? _error;

  bool _soloNoLeidas = false;
  List<Map<String, dynamic>> _items = const [];

  Timer? _debounce;

  final _fmt = DateFormat('dd/MM/yyyy HH:mm');

  AppScope get _scope => AppScope.of(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return DateTime.tryParse(s);
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await _scope.notificaciones.listar(
        soloNoLeidas: _soloNoLeidas,
        limit: 200,
        offset: 0,
      );
      setState(() => _items = rows);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _unreadLocal =>
      _items.where((e) => (e['leido'] == false)).length;

  Future<void> _toggleSoloNoLeidas(bool v) async {
    setState(() => _soloNoLeidas = v);
    // Evita spams de llamadas si el usuario toca rápido.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), _cargar);
  }

  Future<void> _marcarLeida(Map<String, dynamic> it) async {
    final id = (it['id_notificacion'] as num?)?.toInt();
    if (id == null) return;
    if (it['leido'] == true) return;

    try {
      await _scope.notificaciones.marcarLeida(id);
      setState(() {
        _items = _items
            .map((e) => (e['id_notificacion'] == id)
                ? {...e, 'leido': true}
                : e)
            .toList(growable: false);
      });
    } catch (_) {
      // No bloquea UX; el Refresh sincroniza.
    }
  }

  Future<void> _marcarTodas() async {
    try {
      await _scope.notificaciones.marcarTodasLeidas();
      setState(() {
        _items = _items
            .map((e) => {...e, 'leido': true})
            .toList(growable: false);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo marcar todas: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _cargar,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Marcar todas como leídas',
            onPressed: (_loading || _items.isEmpty) ? null : _marcarTodas,
            icon: const Icon(Icons.done_all),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorState()
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    children: [
                      _header(context),
                      const SizedBox(height: 12),
                      if (_items.isEmpty) _emptyState(),
                      if (_items.isNotEmpty) _list(context),
                    ],
                  ),
                ),
    );
  }

  Widget _header(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unread = _unreadLocal;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bandeja de notificaciones',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (unread > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border:
                          Border.all(color: cs.primary.withOpacity(0.25)),
                    ),
                    child: Text(
                      '$unread sin leer',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mostrar solo no leídas'),
              value: _soloNoLeidas,
              onChanged: _toggleSoloNoLeidas,
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: _items.length,
        separatorBuilder: (_, __) =>
            Divider(height: 0, color: cs.outlineVariant.withOpacity(0.45)),
        itemBuilder: (context, i) {
          final it = _items[i];
          final leido = (it['leido'] == true);
          final dt = _parseDate(it['fecha_envio']);
          final fecha = dt == null ? '-' : _fmt.format(dt.toLocal());
          final msg = (it['mensaje'] ?? '').toString();

          return ListTile(
            onTap: () => _marcarLeida(it),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: leido
                    ? cs.surfaceContainerHighest
                    : cs.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: leido
                      ? cs.outlineVariant.withOpacity(0.35)
                      : cs.primary.withOpacity(0.25),
                ),
              ),
              child: Icon(
                leido ? Icons.notifications_none : Icons.notifications,
                color: leido ? cs.onSurfaceVariant : cs.primary,
              ),
            ),
            title: Text(
              msg.isEmpty ? '-' : msg,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: leido ? FontWeight.w600 : FontWeight.w900,
              ),
            ),
            subtitle: Text('Enviado: $fecha'),
            trailing: leido
                ? const Icon(Icons.done, size: 18)
                : const Icon(Icons.circle, size: 10),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: const [
          Icon(Icons.notifications_off_outlined, size: 64),
          SizedBox(height: 12),
          Text(
            'No hay notificaciones para mostrar.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
