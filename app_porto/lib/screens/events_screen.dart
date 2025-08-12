import 'package:flutter/material.dart';
import '../widgets/top_navbar.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  static const double maxContentWidth = 1200;

  // Datos estáticos (ready para API luego)
  final List<Map<String, dynamic>> _events = [
    {
      'title': 'Brisas Cup 360',
      'subtitle': 'Campeonato Internacional',
      'location': 'Panamá',
      'year': 2025,
      'cover': 'assets/img/eventos/brisas_cover.jpg',
      'description':
          'Experiencia internacional de alto nivel con clubes invitados de la región. '
          'Desarrollo competitivo y vitrina para talento joven.',
      'images': <String>[],
    },
    {
      'title': 'Caribe Champions',
      'subtitle': 'Campeonato Internacional',
      'location': 'Barranquilla',
      'year': 2024,
      'cover': 'assets/img/eventos/caribe_cover.jpg',
      'description':
          'Torneo de referencia en el Caribe colombiano. Intensidad, disciplina y juego colectivo '
          'enfrentando a escuelas top del litoral.',
      'images': <String>[],
    },
    {
      'title': 'Sporturs Soccer Cup',
      'subtitle': 'Campeonato Internacional',
      'location': 'Medellín',
      'year': 2023,
      'cover': 'assets/img/eventos/sporturs_cover.jpg',
      'description':
          'Competencia con metodología formativa y enfoque en el fair play. '
          'Gran oportunidad para medición de rendimiento y convivencia.',
      'images': <String>[],
    },
  ];

  void _openGallery(Map<String, dynamic> e) {
    final images = List<String>.from(e['images'] ?? []);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Galería — ${e['title']}'),
        content: SizedBox(
          width: 560,
          child: images.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Galería próxima a publicarse.\n'
                    'Añade imágenes en assets/img/eventos/ y regístralas en "images".',
                  ),
                )
              : SingleChildScrollView(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: images.map((p) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          p,
                          width: 160, height: 120, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 160, height: 120,
                            color: Colors.black12,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  void _showStaticImagesInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Agregar imágenes (estático)'),
        content: const SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1) Coloca tus archivos en: assets/img/eventos/\n'
                '2) Decláralos en pubspec.yaml (assets/img/ ya cubre subcarpetas)\n'
                '3) Agrega rutas en "images" o cambia "cover" por tu portada.\n\n'
                'Ej: "images": ["assets/img/eventos/brisas1.jpg", "assets/img/eventos/brisas2.jpg"]',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      appBar: const TopNavBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showStaticImagesInfo,
        icon: const Icon(Icons.add_photo_alternate),
        label: const Text('Agregar imágenes'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _events.length + 1, // +1 para el banner "próximamente"
        itemBuilder: (_, i) {
          if (i == _events.length) {
            return _ComingSoonBanner();
          }
          final e = _events[i];
          return _EventSection(
            title: e['title'],
            subtitle: e['subtitle'],
            location: e['location'],
            year: e['year'],
            cover: e['cover'],
            description: e['description'],
            onOpenGallery: () => _openGallery(e),
            isWide: isWide,
            invert: i.isOdd, // alterna layout en wide
          );
        },
      ),
    );
  }
}

class _EventSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final String location;
  final int year;
  final String cover;
  final String description;
  final VoidCallback onOpenGallery;
  final bool isWide;
  final bool invert;

  const _EventSection({
    required this.title,
    required this.subtitle,
    required this.location,
    required this.year,
    required this.cover,
    required this.description,
    required this.onOpenGallery,
    required this.isWide,
    this.invert = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _EventsScreenState.maxContentWidth),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!invert) Expanded(flex: 5, child: _Cover(cover: cover)),
                  SizedBox(width: isWide ? 24 : 0),
                  Expanded(flex: 5, child: _Details(title: title, subtitle: subtitle, location: location, year: year, description: description, onOpenGallery: onOpenGallery)),
                  if (invert) ...[
                    const SizedBox(width: 24),
                    Expanded(flex: 5, child: _Cover(cover: cover)),
                  ],
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Cover(cover: cover),
                  const SizedBox(height: 16),
                  _Details(title: title, subtitle: subtitle, location: location, year: year, description: description, onOpenGallery: onOpenGallery),
                ],
              ),
      ),
    );

    return Container(
      color: Colors.grey.shade50,
      child: Center(child: content),
    );
  }
}

class _Cover extends StatelessWidget {
  final String cover;
  const _Cover({required this.cover});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16/9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              cover,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.black12,
                alignment: Alignment.center,
                child: const Icon(Icons.image, size: 64, color: Colors.black45),
              ),
            ),
            // Degradado para legibilidad si pones textos encima en el futuro
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.25), Colors.transparent],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  final String title;
  final String subtitle;
  final String location;
  final int year;
  final String description;
  final VoidCallback onOpenGallery;

  const _Details({
    required this.title,
    required this.subtitle,
    required this.location,
    required this.year,
    required this.description,
    required this.onOpenGallery,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 0.8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place, size: 18),
                const SizedBox(width: 6),
                Text('$location $year', style: textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(description, style: textTheme.bodyLarge),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onOpenGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Ver galería'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '¡Próximamente más eventos!',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
