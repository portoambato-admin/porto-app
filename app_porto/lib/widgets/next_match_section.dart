// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class NextMatchSection extends StatelessWidget {
//   final String localTeam;
//   final String awayTeam;
//   final DateTime matchDate;
//   final String location;
//   final String category;

//   const NextMatchSection({
//     super.key,
//     required this.localTeam,
//     required this.awayTeam,
//     required this.matchDate,
//     required this.location,
//     required this.category,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final fechaFormateada = DateFormat('dd/MM/yyyy HH:mm', 'es').format(matchDate);
//     final isSmall = MediaQuery.of(context).size.width < 600;

//     return Center( // <-- centra el componente en la página
//       child: ConstrainedBox(
//         constraints: const BoxConstraints(maxWidth: 900), // ancho máximo centrado
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           margin: const EdgeInsets.only(bottom: 16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 6,
//                 offset: const Offset(0, 3),
//               ),
//             ],
//           ),
//           child: isSmall
//               ? Column( // móviles: dos líneas
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center, // <-- centro
//                       children: [
//                         Icon(Icons.sports_soccer,
//                             color: Theme.of(context).colorScheme.primary, size: 28),
//                         const SizedBox(width: 8),
//                         Flexible(
//                           child: Text(
//                             'Próximo partido: $localTeam vs $awayTeam',
//                             textAlign: TextAlign.center, // <-- centro
//                             style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 6),
//                     Text(
//                       '$fechaFormateada · $location · $category',
//                       textAlign: TextAlign.center, // <-- centro
//                       style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
//                     ),
//                   ],
//                 )
//               : Row( // desktop/tablet: una línea
//                   mainAxisAlignment: MainAxisAlignment.center, // <-- centro
//                   children: [
//                     Icon(Icons.sports_soccer,
//                         color: Theme.of(context).colorScheme.primary, size: 28),
//                     const SizedBox(width: 12),
//                     Flexible(
//                       child: Text(
//                         'Próximo partido: $localTeam vs $awayTeam · $fechaFormateada · $location · $category',
//                         textAlign: TextAlign.center, // <-- centro
//                         style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                 ),
//         ),
//       ),
//     );
//   }
// }

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
  // ==== CAMBIA ESTOS DATOS (por ahora estático) ====
  final Map<String, dynamic> _match = {
    'opponent': 'Academia Los Andes',
    'category': 'Sub-12',
    'tournament': 'Liga Provincial',
    'homeAway': 'Local', // 'Visitante'
    'location': 'Estadio Municipal de Atocha, Ambato',
    'datetime': DateTime.now().add(const Duration(days: 2, hours: 5, minutes: 30)),
  };
  // =================================================

  late Timer _timer;
  Duration _remain = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calcRemain();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    _calcRemain();
  }

  void _calcRemain() {
    final dt = _match['datetime'] as DateTime;
    final now = DateTime.now();
    setState(() {
      _remain = dt.isAfter(now) ? dt.difference(now) : Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _fmtDuration(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    final secs = d.inSeconds % 60;
    if (days > 0) {
      return '${days}d ${hours}h ${mins}m ${secs}s';
    }
    return '${hours}h ${mins}m ${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w >= 900;

    final dt = _match['datetime'] as DateTime;
    final dateFmt = DateFormat('EEEE d \'de\' MMMM', 'es'); // ej: viernes 8 de agosto
    final timeFmt = DateFormat('HH:mm', 'es');

    // Estilos/chips
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
            Text('${dateFmt.format(dt)} · ${timeFmt.format(dt)}'),
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
              onPressed: () {
                // Futuro: navegar a detalle o compartir
              },
              icon: const Icon(Icons.info),
              label: const Text('Detalles'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                // Futuro: abrir mapa (url_launcher con Google Maps)
              },
              icon: const Icon(Icons.map),
              label: const Text('Cómo llegar'),
            ),
          ],
        ),
      ],
    );

    final illustration = AspectRatio(
      aspectRatio: 16/9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen opcional de portada del partido (puede ser genérica)
            Image.asset(
              'img/partido.jpg',
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
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
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
