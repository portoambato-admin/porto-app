import 'package:flutter/material.dart';
import '../../features/public/presentation/screen/home_screen.dart';
import '../../features/public/presentation/screen/store_screen.dart';

class StoreSection extends StatelessWidget {
  const StoreSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Productos destacados (los 5 que enviaste)
    const featured = <Map<String, String>>[
      {
        'id': '1',
        'title': 'Uniforme Principal 5to Aniversario Porto 2025',
        'image': 'assets/img/tienda/uniforme1.webp',
      },
      {
        'id': '2',
        'title': 'Uniforme Principal Waikiki 5to Aniversario Porto 2025',
        'image': 'assets/img/tienda/uniforme2.webp',
      },
      {
        'id': '3',
        'title': 'Camiseta polo de presentación 5to Aniversario Porto 2025',
        'image': 'assets/img/tienda/polo.webp',
      },
      {
        'id': '4',
        'title': 'Buzo de entrenamiento 5to Aniversario Porto 2025',
        'image': 'assets/img/tienda/buzo.webp',
      },
      {
        'id': '5',
        'title': 'Chompa de presentación 5to Aniversario Porto 2025',
        'image': 'assets/img/tienda/chompa.webp',
      },
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: HomeScreen.maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Adquirir nueva indumentaria',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),

              // Carrusel 3/2/1 con flechas
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _FeaturedCarousel(products: featured),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- Carrusel (3/2/1 visibles con flechas) ----------
class _FeaturedCarousel extends StatefulWidget {
  final List<Map<String, String>> products;
  const _FeaturedCarousel({required this.products});

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  late PageController _pc;
  bool _controllerReady = false;
  int _firstVisibleIndex = 0;
  int _visible = 3;

  @override
  void dispose() {
    if (_controllerReady) _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, cons) {
      // 3 en desktop, 2 en tablet, 1 en móvil
      final int visibleNow =
          cons.maxWidth >= 900 ? 3 : cons.maxWidth >= 600 ? 2 : 1;

      // Altura card (más compacta; deja espacio para el botón)
      final double cardHeight =
          visibleNow == 3 ? 330 : visibleNow == 2 ? 345 : 370;

      // fracción para que entren visiblesNow tarjetas + pequeño gap
      final double vf = (1 / visibleNow) - 0.02;

      // Inicializa o recrea el controller si cambió el número visible
      if (!_controllerReady) {
        _pc = PageController(viewportFraction: vf);
        _controllerReady = true;
        _visible = visibleNow;
      } else if (visibleNow != _visible) {
        final currentPage = _pc.hasClients ? _pc.page?.round() ?? 0 : 0;
        _pc.dispose();
        _pc = PageController(viewportFraction: vf, initialPage: currentPage);
        _visible = visibleNow;
      }

      final int maxPage = (widget.products.length - _visible).clamp(0, 9999);

      Future<void> goRel(int delta) async {
        if (!_pc.hasClients) return;
        final target =
            (_firstVisibleIndex + delta).clamp(0, maxPage); // avanza por “pantalla”
        await _pc.animateToPage(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }

      return SizedBox(
        height: cardHeight,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pc,
              padEnds: false,
              allowImplicitScrolling: true,
              onPageChanged: (i) => setState(() => _firstVisibleIndex = i),
              itemCount: widget.products.length,
              itemBuilder: (_, i) {
                final p = widget.products[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _MiniCard(
                    title: p['title']!,
                    image: p['image']!,
                    onShop: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const StoreScreen()),
                      );
                    },
                  ),
                );
              },
            ),

            // Flecha izquierda
            if (widget.products.length > _visible)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: _NavButton(
                  direction: AxisDirection.left,
                  enabled: _firstVisibleIndex > 0,
                  onTap: () => goRel(-_visible),
                ),
              ),

            // Flecha derecha
            if (widget.products.length > _visible)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: _NavButton(
                  direction: AxisDirection.right,
                  enabled: _firstVisibleIndex < maxPage,
                  onTap: () => goRel(_visible),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _NavButton extends StatelessWidget {
  final AxisDirection direction;
  final bool enabled;
  final VoidCallback onTap;

  const _NavButton({
    required this.direction,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon =
        direction == AxisDirection.left ? Icons.chevron_left : Icons.chevron_right;

    return Center(
      child: Material(
        elevation: enabled ? 2 : 0,
        shape: const CircleBorder(),
        color: enabled
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).disabledColor.withOpacity(.15),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 28,
              color: enabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).disabledColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String title;
  final String image;
  final VoidCallback onShop;

  const _MiniCard({
    required this.title,
    required this.image,
    required this.onShop,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Container(
              color: Colors.grey[100],
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  image,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image, size: 40, color: Colors.black45),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  // Botón Tienda (pegado al título)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onShop,
                      icon: const Icon(Icons.storefront),
                      label: const Text('Tienda'),
                    ),
                  ),

                  // El espacio libre queda ABAJO (no entre texto y botón)
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
