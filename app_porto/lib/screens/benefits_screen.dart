import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../widgets/top_navbar.dart';

class BenefitsScreen extends StatefulWidget {
  const BenefitsScreen({super.key});

  static const double maxContentWidth = 1200;

  @override
  State<BenefitsScreen> createState() => _BenefitsScreenState();
}

class _BenefitsScreenState extends State<BenefitsScreen> {
  // ID del video (de https://www.youtube.com/watch?v=dn3d8awSA0c -> "dn3d8awSA0c")
  static const String _videoId = 'dn3d8awSA0c';

  late final YoutubePlayerController _yt;

  // Logos de auspiciantes (assets estáticos)
  final List<String> _sponsors = const [
    'assets/img/auspiciantes/a1.png',
    'assets/img/auspiciantes/a2.png',
    'assets/img/auspiciantes/a3.png',
    'assets/img/auspiciantes/a4.png',
    'assets/img/auspiciantes/a5.png',
  ];

  @override
  void initState() {
    super.initState();
    _yt = YoutubePlayerController.fromVideoId(
      videoId: _videoId,
      startSeconds: 0,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
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
    final w = MediaQuery.of(context).size.width;
    final logosPerRow = w >= 1000 ? 5 : w >= 700 ? 4 : w >= 480 ? 3 : 2;

    return Scaffold(
      appBar: const TopNavBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: BenefitsScreen.maxContentWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Beneficios y Auspiciantes',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),

                    // Video (16:9) en una sola sección
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: YoutubePlayer(controller: _yt),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Text(
                      'Nuestros Auspiciantes',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),

                    // Grid compacto de logos (en la misma tarjeta)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _sponsors.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: logosPerRow,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemBuilder: (_, i) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black12),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(
                            _sponsors[i],
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
