import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/home_screen.dart';

class NextMatchSection extends StatefulWidget {
  const NextMatchSection({super.key});

  @override
  State<NextMatchSection> createState() => _NextMatchSectionState();
}

class _NextMatchSectionState extends State<NextMatchSection> {
  // ========== CONFIGURA AQUÍ ==========
  // Día de la semana (usa constantes de DateTime): 
  // DateTime.monday ... DateTime.sunday
  static const int kWeekday = DateTime.sunday; // Ej: sábado
  static const int kHour = 11;    // 0-23
  static const int kMinute = 0; // 0-59

  // Datos del partido
  final Map<String, dynamic> _match = {
    'opponent': 'KVE',
    'category': 'Formativa',
    'tournament': 'Copa la Hora',
    'homeAway': 'Sub-6', // 'Visitante'
    'location': 'Estadio Bellavista, Ambato',
    'puntoEncuentro': 'Ingreso puerta principal',
    'presentarseAntesMin': 20,
  };
  // ====================================

  late Timer _timer;
  late DateTime _matchDateTime;
  Duration _remain = Duration.zero;

  @override
  void initState() {
    super.initState();
    _matchDateTime = _computeNextDateTime(kWeekday, kHour, kMinute);
    _calcRemain();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Calcula la próxima fecha que coincide con (weekday, hour, minute)
  DateTime _computeNextDateTime(int weekday, int hour, int minute) {
    final now = DateTime.now();
    // Punto base: hoy a la hora indicada
    DateTime candidate = DateTime(now.year, now.month, now.day, hour, minute);
    // Ajuste al weekday deseado
    final int delta = (weekday - candidate.weekday) % 7; // 0..6
    candidate = candidate.add(Duration(days: delta));
    // Si ya pasó hoy esa hora, saltar a la próxima semana
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 7));
    }
    return candidate;
  }

  void _tick() {
    if (!mounted) return;
    _calcRemain();
  }

  void _calcRemain() {
    final now = DateTime.now();
    setState(() {
      _remain = _matchDateTime.isAfter(now) ? _matchDateTime.difference(now) : Duration.zero;
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

  // --- UI helpers ---
  void _mostrarDetallesPartido() {
    final rival = _match['opponent'] as String;
    final sede = _match['location'] as String;
    final puntoEncuentro = (_match['puntoEncuentro'] as String?) ?? 'Cancha principal';
    final presentarMin = (_match['presentarseAntesMin'] as int?) ?? 20;

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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Detalle del partido', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.sports_soccer),
                const SizedBox(width: 8),
                Expanded(child: Text('PortoAmbato vs $rival')),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.event),
                const SizedBox(width: 8),
                Expanded(child: Text('Fecha: ${dateFmt.format(_matchDateTime)}')),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.schedule),
                const SizedBox(width: 8),
                Expanded(child: Text('Hora de inicio: ${timeFmt.format(_matchDateTime)}')),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.place),
                const SizedBox(width: 8),
                Expanded(child: Text('Sede: $sede')),
              ]),
              const Divider(height: 24),
              Text('Recomendaciones', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const _Bullet('Presentarse con uniforme completo y bien hidratado.'),
              _Bullet('Llegar $presentarMin minutos antes al $puntoEncuentro.'),
              const _Bullet('Evitar comidas pesadas 2 horas antes del encuentro.'),
              const SizedBox(height: 12),
              Text('Documentos/objetos a llevar', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _TagChip('Cédula de identidad'),
                  _TagChip('Botella de agua'),
                  _TagChip('Canilleras'),
                  _TagChip('Toalla pequeña'),
                ],
              ),
              const SizedBox(height: 16),
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
  // --- fin helpers ---

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w >= 900;

    final dateFmt = DateFormat('EEEE d \'de\' MMMM', 'es');
    final timeFmt = DateFormat('HH:mm', 'es');

    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(text: _match['category']),
        if ((_match['tournament'] as String).isNotEmpty) _Chip(text: _match['tournament']),
        _Chip(text: _match['homeAway']),
      ],
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Próximo partido', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('PortoAmbato vs ${_match['opponent']}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        chips,
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.event, size: 20),
            const SizedBox(width: 8),
            Text('${dateFmt.format(_matchDateTime)} · ${timeFmt.format(_matchDateTime)}'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.place, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('${_match['location']}')),
          ],
        ),
        const SizedBox(height: 16),
        if (_remain > Duration.zero)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer),
                const SizedBox(width: 8),
                Text('Comienza en ${_fmtDuration(_remain)}'),
              ],
            ),
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.sports_soccer),
              SizedBox(width: 8),
              Text('¡En juego o finalizado!'),
            ],
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: _mostrarDetallesPartido,
              icon: const Icon(Icons.info),
              label: const Text('Detalles'),
            ),
            OutlinedButton.icon(
              onPressed: _mostrarProximamente, // por ahora
              icon: const Icon(Icons.map),
              label: const Text('Cómo llegar'),
            ),
          ],
        ),
      ],
    );

    final illustration = AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/img/webp/partido.webp',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.black12,
                alignment: Alignment.center,
                child: const Icon(Icons.image, size: 64, color: Colors.black45),
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

    return Center(
      child: Container(
        color: const Color(0xFFF7F9FC),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: HomeScreen.maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: isWide
                  ? Row(
                      children: [
                        Expanded(flex: 5, child: info),
                        const SizedBox(width: 24),
                        Expanded(flex: 5, child: illustration),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        info,
                        const SizedBox(height: 16),
                        illustration,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// Chip visual para las etiquetas superiores (categoría, torneo, local/visitante)
class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.6),
    );
  }
}

// Chip para la hoja de detalles (qué llevar)
class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
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
