import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/widgets/top_navbar.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  static const double maxContentWidth = 1200;

  // --- Estado de búsqueda y filtros ---
  final TextEditingController _searchCtrl = TextEditingController();
  String _category = 'Todos';

  // Catálogo estático
  final List<Map<String, dynamic>> _products = [
    {
      'id': '1',
      'title': 'Uniforme Principal 5to Aniversario Porto 2025',
      'category': 'Indumentaria',
      'image': 'assets/img/tienda/uniforme1.webp',
    },
    {
      'id': '2',
      'title': 'Uniforme Principal Waikiki 5to Aniversario Porto 2025',
      'category': 'Indumentaria',
      'image': 'assets/img/tienda/uniforme2.webp',
    },
    {
      'id': '3',
      'title': 'Camiseta polo de presentación 5to Aniversario Porto 2025',
      'category': 'Indumentaria',
      'image': 'assets/img/tienda/polo.webp',
    },
    {
      'id': '4',
      'title': 'Buzo de entrenamiento 5to Aniversario Porto 2025',
      'category': 'Indumentaria',
      'image': 'assets/img/tienda/buzo.webp',
    },
    {
      'id': '5',
      'title': 'Chompa de presentación 5to Aniversario Porto 2025',
      'category': 'Indumentaria',
      'image': 'assets/img/tienda/chompa.webp',
    },
    {
      'id': '6',
      'title': 'Bolso Zapatera 5to Aniversario Porto 2025',
      'category': 'Accesorio',
      'image': 'assets/img/tienda/bolozap.webp',
    },
    {
      'id': '7',
      'title': 'Bolso de viaje Kipsta',
      'category': 'Accesorio',
      'image': 'assets/img/tienda/bolsoviaje.webp',
    },
    {
      'id': '8',
      'title': 'Medias antideslizantes Il Migliore Adultos',
      'category': 'Indumentaria',
      'image': 'assets/img/tienda/medias.webp',
    },
    {
      'id': '9',
      'title': 'Pechera Il Migliore - Corrector de Postura',
      'category': 'Accesorio',
      'image': 'assets/img/tienda/pechera.webp',
    },
    {
      'id': '10',
      'title': 'Canilleras Porto 2025',
      'category': 'Accesorio',
      'image': 'assets/img/tienda/canilleras.webp',
    },
    {
      'id': '11',
      'title': 'Stickers Premium 5to Aniversario Porto 2025',
      'category': 'Accesorio',
      'image': 'assets/img/tienda/stickets.webp',
    },
  ];

  // Filtro aplicado
  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _products.where((p) {
      final okCategory = _category == 'Todos' || p['category'] == _category;
      final okSearch = q.isEmpty || (p['title'] as String).toLowerCase().contains(q);
      return okCategory && okSearch;
    }).toList();
  }

  int get _activeFilterCount {
    int c = 0;
    if (_category != 'Todos') c++;
    return c;
  }

  Future<void> _openFiltersSheet() async {
    String tmpCategory = _category;

    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.filter_alt),
                    const SizedBox(width: 8),
                    Text('Filtros', style: Theme.of(ctx).textTheme.titleLarge),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() => _category = 'Todos');
                        Navigator.pop(ctx);
                      },
                      child: const Text('Restablecer'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: tmpCategory,
                  items: const [
                    DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                    DropdownMenuItem(value: 'Indumentaria', child: Text('Indumentaria')),
                    DropdownMenuItem(value: 'Accesorio', child: Text('Accesorios')), // 👈 coincide con los datos
                  ],
                  onChanged: (v) => tmpCategory = v ?? 'Todos',
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          setState(() => _category = tmpCategory);
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // WhatsApp (botón Comprar)
  Future<void> _launchWhatsApp(String productTitle) async {
    final msg = 'Hola, me interesa el producto: $productTitle, ayúdame con información por favor';
    final Uri url = Uri.parse('https://wa.me/593995650089?text=${Uri.encodeComponent(msg)}');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;

                // columnas por tamaño
                final cross = w >= 1100 ? 4 : w >= 900 ? 3 : w >= 600 ? 2 : 1;

                // Altura del ítem del grid (reducida y responsiva)
                double itemExtent;
                if (cross >= 4) {
                  itemExtent = 330; // Desktop ancho
                } else if (cross == 3) {
                  itemExtent = 340;
                } else if (cross == 2) {
                  itemExtent = 360;
                } else {
                  itemExtent = 410; // móvil 1 columna
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIENDA PORTO',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),

                    _SearchAndFilterBar(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      onOpenFilters: _openFiltersSheet,
                      activeFilters: _activeFilterCount,
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: GridView.builder(
                        itemCount: _filtered.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cross,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 12, // un poco menos
                          mainAxisExtent: itemExtent, // ⬅ más bajo
                        ),
                        itemBuilder: (_, i) {
                          final p = _filtered[i];
                          return _ProductCard(
                            title: p['title'],
                            image: p['image'],
                            onView: () => _openDetail(p),
                            onBuy: () => _launchWhatsApp(p['title']),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Detalle con botón Comprar
  void _openDetail(Map<String, dynamic> p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(p['title']),
        content: SizedBox(
          width: 520,
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.asset(
              p['image'],
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            onPressed: () => _launchWhatsApp(p['title']),
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Comprar'),
          ),
        ],
      ),
    );
  }
}

// ===== Widgets auxiliares =====

class _SearchAndFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onOpenFilters;
  final int activeFilters;

  const _SearchAndFilterBar({
    required this.controller,
    required this.onChanged,
    required this.onOpenFilters,
    required this.activeFilters,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;

    final searchField = Expanded(
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Buscar producto…',
        ),
      ),
    );

    final filterButton = _FilterButton(
      onPressed: onOpenFilters,
      activeCount: activeFilters,
      isIconOnly: isSmall,
    );

    return Row(
      children: [
        searchField,
        const SizedBox(width: 8),
        filterButton,
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  final VoidCallback onPressed;
  final int activeCount;
  final bool isIconOnly;

  const _FilterButton({
    required this.onPressed,
    required this.activeCount,
    this.isIconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isIconOnly) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: onPressed,
            icon: const Icon(Icons.filter_alt),
            tooltip: 'Filtros',
          ),
          if (activeCount > 0)
            Positioned(
              right: 2,
              top: 2,
              child: CircleAvatar(
                radius: 8,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  '$activeCount',
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      );
    }

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.filter_alt),
        const SizedBox(width: 6),
        const Text('Filtros'),
        if (activeFiltersBadge(activeCount)) ...[
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 10,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              '$activeCount',
              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );

    return OutlinedButton(onPressed: onPressed, child: child);
  }

  bool activeFiltersBadge(int n) => n > 0;
}

class _ProductCard extends StatelessWidget {
  final String title;
  final String image;
  final VoidCallback onView;
  final VoidCallback onBuy;

  const _ProductCard({
    required this.title,
    required this.image,
    required this.onView,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
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
                padding: const EdgeInsets.all(6), // un poco menor
                child: Image.asset(
                  image,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40, color: Colors.black45),
                ),
              ),
            ),
          ),

          // Contenido que ocupa el resto del alto disponible
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Empuja los botones hacia abajo (pero con itemExtent reducido el hueco es mínimo)
                  const Spacer(),

                  // Ver
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onView,
                      icon: const Icon(Icons.visibility),
                      label: const Text('Ver'),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Comprar
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onBuy,
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Comprar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
