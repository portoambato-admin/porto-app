import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../widgets/top_navbar.dart';

class BenefitsScreen extends StatelessWidget {
  const BenefitsScreen({super.key});

  static const double maxContentWidth = 1200;

  // Data estática: cada auspiciante con logo, nombre, descripción y videoId
  static final List<Map<String, String>> sponsors = [
    {
      'name': 'Auspiciador 1',
      'logo': 'assets/img/auspiciantes/a1.png',
      'videoId': 'dn3d8awSA0c', // <-- cambia por el de este sponsor
      'desc': 'Beneficios: descuentos en uniformes, becas parciales y premios por desempeño.',
    },
    {
      'name': 'Auspiciador 2',
      'logo': 'assets/img/auspiciantes/a2.png',
      'videoId': 'dQw4w9WgXcQ',
      'desc': 'Beneficios: hidratación oficial en competencias y kits deportivos trimestrales.',
    },
    {
      'name': 'Auspiciador 3',
      'logo': 'assets/img/auspiciantes/a3.png',
      'videoId': '5NV6Rdv1a3I',
      'desc': 'Beneficios: cobertura fotográfica de eventos y difusión en redes.',
    },
    {
      'name': 'Auspiciador 4',
      'logo': 'assets/img/auspiciantes/a4.png',
      'videoId': 'ktvTqknDobU',
      'desc': 'Beneficios: charlas de nutrición deportiva y evaluación de composición corporal.',
    },
    {
      'name': 'Auspiciador 5',
      'logo': 'assets/img/auspiciantes/a5.png',
      'videoId': 'CevxZvSJLk8',
      'desc': 'Beneficios: becas de excelencia y apoyo a giras internacionales.',
    },
  ];

  void _openSponsor(BuildContext context, Map<String, String> sponsor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SponsorDetailSheet(sponsor: sponsor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cross = w >= 1100 ? 5 : w >= 900 ? 4 : w >= 640 ? 3 : 2;

    return Scaffold(
      appBar: const TopNavBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Beneficios y Auspiciantes',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                // Grid compacto (logos más pequeños)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sponsors.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cross,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 120, // tarjetas bajitas
                  ),
                  itemBuilder: (_, i) {
                    final sp = sponsors[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _openSponsor(context, sp),
                      child: Tooltip(
                        message: sp['name'] ?? '',
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(
                            sp['logo']!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 32),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SponsorDetailSheet extends StatefulWidget {
  final Map<String, String> sponsor;
  const _SponsorDetailSheet({required this.sponsor});

  @override
  State<_SponsorDetailSheet> createState() => _SponsorDetailSheetState();
}

class _SponsorDetailSheetState extends State<_SponsorDetailSheet> {
  late final YoutubePlayerController _yt;

  @override
  void initState() {
    super.initState();
    _yt = YoutubePlayerController.fromVideoId(
      videoId: widget.sponsor['videoId'] ?? '',
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
      ),
    );
  }

  @override
  void dispose() {
    _yt.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width > 900 ? 800.0 : MediaQuery.of(context).size.width - 24;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con logo y nombre
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      widget.sponsor['logo'] ?? '',
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 36),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.sponsor['name'] ?? '',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Descripción
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.sponsor['desc'] ?? '',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 12),

              // Video más pequeño (16:9 controlado)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: YoutubePlayer(controller: _yt),
                ),
              ),

              const SizedBox(height: 12),
              // Acciones (si luego quieres enlazar a su web/redes)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check),
                      label: const Text('Entendido'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
