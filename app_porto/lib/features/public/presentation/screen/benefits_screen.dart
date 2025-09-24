import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../shared/widgets/top_navbar.dart';

class BenefitsScreen extends StatelessWidget {
  const BenefitsScreen({super.key});

  static const double maxContentWidth = 1200;

  // 👉 Configura estos valores
  static final Uri missionUrl = Uri.parse(
    'https://tu-sitio.com',
  ); // <-- tu URL real
  static const String missionText =
      'Súmate a la misión de PortoAmbato: formar deportistas con valores y alto rendimiento.';

  // WhatsApp directo al número solicitado (Ecuador +593, sin 0 inicial)
  static const String kWhatsappE164 = '593995650089';
  static const String whatsappMessage =
      'Hola, me gustaría conocer los requisitos para ser auspiciante de PortoAmbato.';

  // Imagen de agradecimiento (usa la misma para fondo y centro)
  static const String kThanksImage = 'assets/img/sponsors/agradecimiento.webp';

  // Data
  static final List<Map<String, String>> sponsors = [
    {
      'name': 'SANFRA',
      'logo': 'assets/img/sponsors/sanfra.webp',
      'videoId': 'ubQ0YvAggJg',
      'desc':
          'Sanfra Móvil: todo en una sola app. Disponible en Google Play y App Store.',
    },
    {
      'name': 'MI NEGOCIO',
      'logo': 'assets/img/sponsors/minegocio.webp',
      'videoId': 'MWDaxG_nFnY',
      'desc':
          '10% de descuento en todos los planes para nuestra comunidad PortoAmbato.',
    },
    {
      'name': 'MUNDITODO',
      'logo': 'assets/img/sponsors/mundi.webp',
      'videoId': 'HGx_lDLm0X8',
      'desc': 'Obtén el 10% descuento en productos seleccionados.',
    },
    {
      'name': 'OPALO',
      'logo': 'assets/img/sponsors/opalo.webp',
      'videoId': '7DW1B0QKObE',
      'desc':
          'Conoce sus proyectos y recibe un descuento por ser parte de la comunidad PortoAmbato.',
    },
    {
      'name': 'TOGO',
      'logo': 'assets/img/sponsors/togo.webp',
      'videoId': 'wY2yE7gQcD8',
      'desc':
          'Obtén descuento en bebidas de hidratación por ser parte de la familia PortoAmbato.',
    },
    {
      'name': 'MODERNA DENTAL CONCEPT ',
      'logo': 'assets/img/sponsors/moderna.webp',
      'videoId': 'xq9iypL-mMs',
      'desc': 'Obtén un descuento especial para nuestros niños de PortoAmbato.',
    },
    {
      'name': 'TARCO',
      'logo': 'assets/img/sponsors/tarco.webp',
      'videoId': 'C7nWZDIf9QI',
      'desc':
          'Obtén descuento en bebidas de hidratación por ser parte de la familia PortoAmbato.',
    },
    {
      'name': 'PASSPORT',
      'logo': 'assets/img/sponsors/pass.webp',
      'videoId': 'cQzg_s7waBs',
      'desc':
          'Obtén descuento en viajes seleccionados junto a la selección del Ecuador por ser parte de la familia PortoAmbato.',
    },
    {
      'name': 'WAIIKIKI',
      'logo': 'assets/img/sponsors/waikiki.webp',
      'videoId': 'SykfmJhNSQs',
      'desc': 'Obtén descuentos por ser parte de la familia PortoAmbato.',
    },
  ];

  void _openSponsor(BuildContext context, Map<String, String> sponsor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SponsorDetailSheet(sponsor: sponsor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cross = w < 640 ? 1 : (w < 1024 ? 2 : 3);

    return Scaffold(
      appBar: const TopNavBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      Text(
                        'Beneficios de nuestros SPONSORS',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: .2,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Aliados que impulsan nuestro crecimiento deportivo y formativo.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),

              // GRID: más alto para permitir más texto visible
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cross,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 28,
                    // Antes: 3/4  →  ahora: 2/3 (más alto)
                    childAspectRatio: 2 / 3,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final sp = sponsors[i];
                      return _SponsorCard(
                        sponsor: sp,
                        onTap: () => _openSponsor(context, sp),
                      );
                    },
                    childCount: sponsors.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: _GraciasSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SponsorCard extends StatefulWidget {
  final Map<String, String> sponsor;
  final VoidCallback onTap;
  const _SponsorCard({required this.sponsor, required this.onTap});

  @override
  State<_SponsorCard> createState() => _SponsorCardState();
}

class _SponsorCardState extends State<_SponsorCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.sponsor['name'] ?? '';
    final logo = widget.sponsor['logo'] ?? '';
    final desc = widget.sponsor['desc'] ?? '';

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      transform: _hover ? (Matrix4.identity()..scale(1.012)) : Matrix4.identity(),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_hover ? 0.08 : 0.045),
            blurRadius: _hover ? 14 : 9,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen vertical
          Image.asset(
            logo,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image, size: 42),
            ),
          ),

          // Panel inferior (más alto, sin "…")
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 32, 10, 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54, Colors.black87],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 🔹 Más líneas visibles y fade (no ellipsis)
                  Text(
                    desc,
                    maxLines: kIsWeb ? 4 : 5, // muestra más en móvil
                    overflow: TextOverflow.fade,
                    softWrap: true,
                    style: const TextStyle(color: Colors.white70, height: 1.15),
                  ),

                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: widget.onTap,
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Ver beneficios y video'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(.14),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(onTap: widget.onTap, child: card),
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
    final name = widget.sponsor['name'] ?? '';
    final desc = widget.sponsor['desc'] ?? '';
    final maxWidth = MediaQuery.of(context).size.width > 1000
        ? 900.0
        : MediaQuery.of(context).size.width - 24;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      tooltip: 'Cerrar',
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 🔹 Descripción completa (sin truncar)
                Text(
                  desc,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
                ),

                const SizedBox(height: 14),

                // Video
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: YoutubePlayer(controller: _yt),
                  ),
                ),

                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check_circle_outline),
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
      ),
    );
  }
}

class _GraciasSection extends StatelessWidget {
  const _GraciasSection();

  static const double _heightMobile = 220;
  static const double _heightWide = 260;

  Future<void> _openWhatsApp() async {
    final fixed = Uri.parse(
      'https://wa.me/${BenefitsScreen.kWhatsappE164}?text=${Uri.encodeComponent(BenefitsScreen.whatsappMessage)}',
    );
    if (!await launchUrl(fixed, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir WhatsApp');
    }
  }

  Future<void> _shareMission() async {
    final list = [
      BenefitsScreen.missionText,
      if (BenefitsScreen.missionUrl.toString().isNotEmpty)
        BenefitsScreen.missionUrl.toString(),
    ];
    await Share.share(list.join('\n'));
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final bannerHeight = isWide ? _heightWide : _heightMobile;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Texto
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                Text(
                  '¡Gracias por unirse a la familia PortoAmbato! 💙⚽',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Su apoyo nos permite formar deportistas con valores, abrir oportunidades, '
                  'potenciar el talento local y proyectarnos al mundo. ¡Juntos vamos más lejos! ',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.black87,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _ValuePill(icon: Icons.school, text: 'Formación con valores'),
                    _ValuePill(icon: Icons.sports_soccer, text: 'Alto rendimiento'),
                    _ValuePill(icon: Icons.public, text: 'Proyección internacional'),
                    _ValuePill(icon: Icons.groups, text: 'Comunidad y familia'),
                    _ValuePill(icon: Icons.workspace_premium, text: 'Excelencia y disciplina'),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _openWhatsApp,
                      icon: const Icon(Icons.volunteer_activism_outlined),
                      label: const Text('Quiero ser auspiciante'),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: _shareMission,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Comparte nuestra misión'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Imagen
          SizedBox(
            height: bannerHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Image.asset(
                    BenefitsScreen.kThanksImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black26, Colors.black38],
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Image.asset(
                      BenefitsScreen.kThanksImage,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.white,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported, size: 48),
                      ),
                    ),
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

class _ValuePill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ValuePill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(text),
      side: const BorderSide(color: Colors.black12),
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
