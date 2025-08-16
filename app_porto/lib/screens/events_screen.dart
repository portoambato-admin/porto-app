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
      'cover': 'assets/img/webp/main.webp',
      'description':
          'Experiencia internacional de alto nivel con clubes invitados de la región. '
          'Desarrollo competitivo y vitrina para talento joven.',
      'images': [
        'assets/img/eventos/panama2025/2025_1_thumb.webp',
        'assets/img/eventos/panama2025/2025_2_thumb.webp',
        'assets/img/eventos/panama2025/2025_3_thumb.webp',
        'assets/img/eventos/panama2025/2025_4_thumb.webp',
        'assets/img/eventos/panama2025/2025_5_thumb.webp',
        'assets/img/eventos/panama2025/2025_6_thumb.webp',
        'assets/img/eventos/panama2025/2025_7_thumb.webp',
      ],
    },
    {
      'title': 'Caribe Champions',
      'subtitle': 'Campeonato Internacional',
      'location': 'Barranquilla',
      'year': 2024,
      'cover': 'assets/img/eventosWebp/2024_1.webp',
      'description':
          'Torneo de referencia en el Caribe colombiano. Intensidad, disciplina y juego colectivo '
          'enfrentando a escuelas top del litoral.',
      'images': [
        'assets/img/eventos/barranquilla2024/2024_1_thumb.webp',
        'assets/img/eventos/barranquilla2024/2024_2_thumb.webp',
        'assets/img/eventos/barranquilla2024/2024_3_thumb.webp',
      ],
    },
    {
      'title': 'Sporturs Soccer Cup',
      'subtitle': 'Campeonato Internacional',
      'location': 'Medellín',
      'year': 2023,
      'cover': 'assets/img/eventosWebp/2023_3.webp',
      'description':
          'Competencia con metodología formativa y enfoque en el fair play. '
          'Gran oportunidad para medición de rendimiento y convivencia.',
      'images': [
        'assets/img/eventos/medellin2023/2023_1_thumb.webp',
        'assets/img/eventos/medellin2023/2023_2_thumb.webp',
        'assets/img/eventos/medellin2023/2023_3_thumb.webp',
      ],
    },
  ];

  // ---------- Galería / Lightbox ----------

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
                    'Añade imágenes en img/eventos/ y regístralas en "images".',
                  ),
                )
              : SingleChildScrollView(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (int i = 0; i < images.length; i++)
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context); // cierra miniaturas
                            _openLightbox(images, i); // abre visor en esa foto
                          },
                          child: Hero(
                            tag: images[i],
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _assetImage(
                                images[i],
                                width: 160,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _openLightbox(List<String> images, int initialIndex) {
    final controller = PageController(initialPage: initialIndex);
    int current = initialIndex;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Cierra tocando fondo
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(ctx),
                ),

                // Paginador con swipe
                PageView.builder(
                  controller: controller,
                  onPageChanged: (i) => setState(() => current = i),
                  itemCount: images.length,
                  itemBuilder: (ctx, i) {
                    final path = images[i];
                    return Center(
                      child: Hero(
                        tag: path,
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 5,
                          child: _assetImage(path, fit: BoxFit.contain),
                        ),
                      ),
                    );
                  },
                ),

                // Botón cerrar
                Positioned(
                  top: 20,
                  right: 20,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black45,
                    ),
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                    tooltip: 'Cerrar',
                  ),
                ),

                // Flecha anterior
                if (images.length > 1)
                  Positioned(
                    left: 12,
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black45,
                      ),
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () {
                        final prev = (current - 1).clamp(0, images.length - 1);
                        controller.animateToPage(
                          prev,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        );
                      },
                    ),
                  ),

                // Flecha siguiente
                if (images.length > 1)
                  Positioned(
                    right: 12,
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black45,
                      ),
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () {
                        final next = (current + 1).clamp(0, images.length - 1);
                        controller.animateToPage(
                          next,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        );
                      },
                    ),
                  ),

                // Indicador 1/N
                if (images.length > 1)
                  Positioned(
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${current + 1} / ${images.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper para usar el mismo errorBuilder en todas las imágenes
  Widget _assetImage(
    String path, {
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) {
        debugPrint('NO se encontró asset: $path');
        return Container(
          width: width,
          height: height,
          color: Colors.black12,
          alignment: Alignment.center,
          child: const Icon(
            Icons.broken_image,
            color: Colors.black45,
            size: 48,
          ),
        );
      },
    );
  }

  // ---------- UI ----------


  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      appBar: const TopNavBar(),
      
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
      constraints: const BoxConstraints(
        maxWidth: _EventsScreenState.maxContentWidth,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!invert) Expanded(flex: 5, child: _Cover(cover: cover)),
                  SizedBox(width: isWide ? 24 : 0),
                  Expanded(
                    flex: 5,
                    child: _Details(
                      title: title,
                      subtitle: subtitle,
                      location: location,
                      year: year,
                      description: description,
                      onOpenGallery: onOpenGallery,
                    ),
                  ),
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
                  _Details(
                    title: title,
                    subtitle: subtitle,
                    location: location,
                    year: year,
                    description: description,
                    onOpenGallery: onOpenGallery,
                  ),
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
      aspectRatio: 16 / 9,
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
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.25),
                      Colors.transparent,
                    ],
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
            Text(
              title,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
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
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withOpacity(0.35),
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
