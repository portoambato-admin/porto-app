import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../features/public/presentation/screen/home_screen.dart';

class NextMatchSection extends StatefulWidget {
  const NextMatchSection({super.key});

  @override
  State<NextMatchSection> createState() => _NextMatchSectionState();
}

class _Fixture {
  final String categoria; // Sub 10, Sub 12...
  final String home;
  final String away;
  final int hour;
  final int minute;

  const _Fixture({
    required this.categoria,
    required this.home,
    required this.away,
    required this.hour,
    required this.minute,
  });
}

class _ScheduledFixture {
  final _Fixture fixture;
  final DateTime dt;
  const _ScheduledFixture(this.fixture, this.dt);
}

class _NextMatchSectionState extends State<NextMatchSection> {
  // ===== CONFIG =====
  static const int kWeekday = DateTime.monday; // cambia al día real
  static final DateTime? kFixedDate = null;      // Ej: DateTime(2026, 1, 22);

  static const String kTournament = 'Torneo FFF';
  static const String kLocation = 'Cámara de Comercio, Ambato';
  static const String kPuntoEncuentro = 'Ingreso puerta principal';
  static const int kPresentarseAntesMin = 20;

  static const List<_Fixture> kFixtures = [
    _Fixture(categoria: 'Sub 10', home: 'PORTO', away: 'MACARA', hour: 14, minute: 50),
    _Fixture(categoria: 'Sub 12', home: 'PORTO', away: 'KVE',    hour: 18, minute: 50),
  ];
  // ================

  late Timer _timer;
  late DateTime _eventDate;
  late List<_ScheduledFixture> _schedule;
  late _ScheduledFixture _next;

  Duration _remain = Duration.zero;

  @override
  void initState() {
    super.initState();
    _recomputeSchedule();
    _calcRemain();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    _calcRemain();
  }

  DateTime _nextWeekdayDate(int weekday) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final delta = (weekday - now.weekday) % 7; // 0..6
    return today.add(Duration(days: delta));
  }

  void _recomputeSchedule() {
    final now = DateTime.now();

    DateTime baseDate;
    if (kFixedDate != null) {
      baseDate = DateTime(kFixedDate!.year, kFixedDate!.month, kFixedDate!.day);
    } else {
      baseDate = _nextWeekdayDate(kWeekday);
    }

    List<_ScheduledFixture> buildFor(DateTime d) {
      final list = kFixtures
          .map((f) => _ScheduledFixture(f, DateTime(d.year, d.month, d.day, f.hour, f.minute)))
          .toList();
      list.sort((a, b) => a.dt.compareTo(b.dt));
      return list;
    }

    var schedule = buildFor(baseDate);

    // Si es semanal y ya pasó todo, mover a la próxima semana
    if (kFixedDate == null && schedule.every((s) => !s.dt.isAfter(now))) {
      baseDate = baseDate.add(const Duration(days: 7));
      schedule = buildFor(baseDate);
    }

    final upcoming = schedule.where((s) => s.dt.isAfter(now)).toList()
      ..sort((a, b) => a.dt.compareTo(b.dt));
    final next = upcoming.isNotEmpty ? upcoming.first : schedule.first;

    _eventDate = baseDate;
    _schedule = schedule;
    _next = next;
  }

  void _calcRemain() {
    final now = DateTime.now();
    _recomputeSchedule();
    setState(() {
      _remain = _next.dt.isAfter(now) ? _next.dt.difference(now) : Duration.zero;
    });
  }

  String _fmtDuration(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    final secs = d.inSeconds % 60;
    if (days > 0) return '${days}d ${hours}h ${mins}m ${secs}s';
    return '${hours}h ${mins}m ${secs}s';
  }

  void _mostrarDetallesPartido() {
    final dateFmt = DateFormat('EEEE d \'de\' MMMM yyyy', 'es');
    final timeFmt = DateFormat('HH:mm', 'es');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Detalle del evento',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              _DetailRow(icon: Icons.emoji_events_outlined, text: kTournament),
              _DetailRow(icon: Icons.event, text: 'Fecha: ${dateFmt.format(_eventDate)}'),
              _DetailRow(icon: Icons.place, text: 'Lugar: $kLocation'),

              const SizedBox(height: 14),
              Text('Partidos',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),

              ..._schedule.map((s) {
                final isNext = s.dt == _next.dt && _remain > Duration.zero;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ScheduleRowCompact(
                    categoria: s.fixture.categoria,
                    versus: '${s.fixture.home} vs ${s.fixture.away}',
                    hora: timeFmt.format(s.dt),
                    highlight: isNext,
                  ),
                );
              }),

              const Divider(height: 24),
              Text('Recomendaciones',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const _Bullet('Presentarse con uniforme completo y bien hidratado.'),
              _Bullet('Llegar $kPresentarseAntesMin minutos antes al $kPuntoEncuentro.'),
              const _Bullet('Evitar comidas pesadas 2 horas antes.'),

              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarProximamente() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Próximamente'),
        content: const Text('La opción "Cómo llegar" estará disponible muy pronto con mapa y rutas.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w >= 900;

    final dateFmt = DateFormat('EEEE d \'de\' MMMM', 'es');
    final timeFmt = DateFormat('HH:mm', 'es');

    final start = _schedule.first.dt;
    final end = _schedule.last.dt;
    final timeRange = '${timeFmt.format(start)} – ${timeFmt.format(end)}';

    final info = LayoutBuilder(
      builder: (context, constraints) {
        // Limitar el ancho del bloque izquierdo para evitar “vacíos” enormes
        final maxW = constraints.maxWidth;
        final leftW = isWide ? (maxW * 0.48).clamp(420.0, 560.0) : maxW;

        final header = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Próximo Evento',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(kTournament,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ChipCompact(text: '${_schedule.length} partidos'),
                const _ChipCompact(text: 'Todas las categorías'),
              ],
            ),
          ],
        );

        final meta = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _MetaLine(icon: Icons.event, text: '${dateFmt.format(_eventDate)} · $timeRange'),
            const SizedBox(height: 6),
            const _MetaLine(icon: Icons.place, text: kLocation),
          ],
        );

        final scheduleBlock = Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.55)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.sports_soccer, size: 18),
                  const SizedBox(width: 8),
                  Text('Partidos',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(_schedule.length, (i) {
                final s = _schedule[i];
                final isNext = s.dt == _next.dt && _remain > Duration.zero;

                return Column(
                  children: [
                    _ScheduleRowCompact(
                      categoria: s.fixture.categoria,
                      versus: '${s.fixture.home} vs ${s.fixture.away}',
                      hora: timeFmt.format(s.dt),
                      highlight: isNext,
                    ),
                    if (i != _schedule.length - 1)
                      Padding(
                        padding: const EdgeInsets.only(left: 40, top: 6, bottom: 6),
                        child: Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.55)),
                      ),
                  ],
                );
              }),
            ],
          ),
        );

        final countdown = Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _remain > Duration.zero
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.28),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.55)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Próximo partido en ${_fmtDuration(_remain)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        );

        final actions = Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _mostrarDetallesPartido,
                icon: const Icon(Icons.info, size: 18),
                label: const Text('Detalles'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _mostrarProximamente,
                icon: const Icon(Icons.map, size: 18),
                label: const Text('Cómo llegar'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        );

        final left = SizedBox(
          width: leftW,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              meta,
              scheduleBlock,
              countdown,
              actions,
            ],
          ),
        );

        final illustration = AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/img/webp/partido.webp',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.black12,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image, size: 56, color: Colors.black45),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.20), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        return isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  left,
                  const SizedBox(width: 22),
                  Expanded(child: illustration),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  left,
                  const SizedBox(height: 14),
                  illustration,
                ],
              );
      },
    );

    return Center(
      child: Container(
        color: const Color(0xFFF7F9FC),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: HomeScreen.maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // menos alto
              child: info,
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== UI =====================

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// Fila compacta: menos alto, menos padding, y sin “vacíos” exagerados
class _ScheduleRowCompact extends StatelessWidget {
  final String categoria;
  final String versus;
  final String hora;
  final bool highlight;

  const _ScheduleRowCompact({
    required this.categoria,
    required this.versus,
    required this.hora,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: highlight ? cs.primaryContainer.withOpacity(0.22) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _Badge(text: categoria),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              versus,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.55)),
              color: highlight ? cs.primary.withOpacity(0.08) : cs.surface,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule, size: 16, color: highlight ? cs.primary : null),
                const SizedBox(width: 6),
                Text(
                  hora,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: highlight ? cs.primary : null,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withOpacity(0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ChipCompact extends StatelessWidget {
  final String text;
  const _ChipCompact({required this.text});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 10),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.55),
      side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.45)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
