import 'package:flutter/material.dart';
import '../widgets/top_navbar.dart';
// import '../utils/contact.dart'; // showPurchaseDialog  // 👈 COMPRAS DESHABILITADAS

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
  String _sort = 'Relevancia';

  // Catálogo estático inicial
  final List<Map<String, dynamic>> _products = [
    {
      'id': '1',
      'title': 'Camiseta Oficial',
      'price': 20.0,
      'category': 'Indumentaria',
      'image': 'assets/img/camiseta.jpg',
    },
    {
      'id': '2',
      'title': 'Pantaloneta Oficial',
      'price': 15.0,
      'category': 'Indumentaria',
      'image': 'assets/img/pantaloneta.jpg',
    },
    {
      'id': '3',
      'title': 'Medias Deportivas',
      'price': 5.0,
      'category': 'Indumentaria',
      'image': 'assets/img/medias.jpg',
    },
  ];

  // Filtro aplicado sobre la lista
  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    List<Map<String, dynamic>> data = _products.where((p) {
      final okCategory = _category == 'Todos' || p['category'] == _category;
      final okSearch =
          q.isEmpty || (p['title'] as String).toLowerCase().contains(q);
      return okCategory && okSearch;
    }).toList();

    switch (_sort) {
      case 'Precio: menor a mayor':
        data.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
        break;
      case 'Precio: mayor a menor':
        data.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
        break;
      default:
        // Relevancia (sin cambios por ahora)
        break;
    }
    return data;
  }

  // Cantidad de filtros activos distintos a los valores por defecto
  int get _activeFilterCount {
    int c = 0;
    if (_category != 'Todos') c++;
    if (_sort != 'Relevancia') c++;
    return c;
  }

  // Diálogo para agregar producto (en memoria) — actualmente no expuesto en UI
  Future<void> _openAddDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String category = 'Indumentaria';
    final imageCtrl = TextEditingController(text: 'assets/img/');

    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Agregar producto'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingrese un nombre'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Precio'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingrese precio';
                    final n = double.tryParse(v);
                    if (n == null || n < 0) return 'Precio inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  items: const [
                    DropdownMenuItem(
                        value: 'Indumentaria', child: Text('Indumentaria')),
                    DropdownMenuItem(
                        value: 'Accesorios', child: Text('Accesorios')),
                  ],
                  onChanged: (v) => category = v ?? 'Indumentaria',
                  decoration: const InputDecoration(labelText: 'Categoría'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: imageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ruta de imagen (asset)',
                    helperText: 'Ej: assets/img/camiseta.jpg',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingrese la ruta del asset'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, {
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'title': titleCtrl.text.trim(),
                  'price': double.parse(priceCtrl.text.trim()),
                  'category': category,
                  'image': imageCtrl.text.trim(),
                });
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (res != null) {
      setState(() => _products.add(res));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto agregado (en memoria).')),
      );
    }
  }

  // --- Bottom sheet de filtros ---
  Future<void> _openFiltersSheet() async {
    String tmpCategory = _category;
    String tmpSort = _sort;

    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título + Reset
                Row(
                  children: [
                    const Icon(Icons.filter_alt),
                    const SizedBox(width: 8),
                    Text('Filtros',
                        style: Theme.of(ctx).textTheme.titleLarge),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _category = 'Todos';
                          _sort = 'Relevancia';
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Restablecer'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Contenido
                DropdownButtonFormField<String>(
                  value: tmpCategory,
                  items: const [
                    DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                    DropdownMenuItem(
                        value: 'Indumentaria', child: Text('Indumentaria')),
                    DropdownMenuItem(
                        value: 'Accesorios', child: Text('Accesorios')),
                  ],
                  onChanged: (v) => tmpCategory = v ?? 'Todos',
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: tmpSort,
                  items: const [
                    DropdownMenuItem(
                        value: 'Relevancia', child: Text('Relevancia')),
                    DropdownMenuItem(
                        value: 'Precio: menor a mayor',
                        child: Text('Precio: menor a mayor')),
                    DropdownMenuItem(
                        value: 'Precio: mayor a menor',
                        child: Text('Precio: mayor a menor')),
                  ],
                  onChanged: (v) => tmpSort = v ?? 'Relevancia',
                  decoration: const InputDecoration(
                    labelText: 'Ordenar por',
                    prefixIcon: Icon(Icons.sort),
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
                          setState(() {
                            _category = tmpCategory;
                            _sort = tmpSort;
                          });
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

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavBar(),
      // floatingActionButton: FloatingActionButton.extended( // 👈 ELIMINADO según pedido
      //   onPressed: _openAddDialog,
      //   icon: const Icon(Icons.add),
      //   label: const Text('Agregar'),
      // ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final cross = w >= 1100
                    ? 4
                    : w >= 900
                        ? 3
                        : w >= 600
                            ? 2
                            : 1;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tienda',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),

                    // Banner informativo
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Próximamente habilitaremos compras online.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // --- Toolbar minimal: Buscar + botón/ícono de Filtros (con badge) ---
                    _SearchAndFilterBar(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      onOpenFilters: _openFiltersSheet,
                      activeFilters: _activeFilterCount,
                    ),
                    const SizedBox(height: 16),

                    // --- Grid de productos (responsivo) ---
                    Expanded(
                      child: GridView.builder(
                        itemCount: _filtered.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cross,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 340,
                        ),
                        itemBuilder: (_, i) {
                          final p = _filtered[i];
                          return _ProductCard(
                            title: p['title'],
                            price: p['price'],
                            image: p['image'],
                            onView: () => _openDetail(p),
                            // onBuy: () => showPurchaseDialog(context, p['title']), // 👈 COMPRAS DESHABILITADAS
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

  void _openDetail(Map<String, dynamic> p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(p['title']),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    p['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.black12,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image,
                          size: 40, color: Colors.black45),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Categoría: ${p['category']}'),
              const SizedBox(height: 4),
              Text(
                'Precio: \$${(p['price'] as num).toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),

              // 👇 Indicador de que las compras no están habilitadas
              const Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text('Próximamente'),
                  avatar: Icon(Icons.lock_clock, size: 18),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar')),
          // FilledButton( // 👈 COMPRAS DESHABILITADAS
          //   onPressed: () => showPurchaseDialog(context, p['title']),
          //   child: const Text('Comprar por WhatsApp'),
          // ),
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
      isIconOnly: isSmall, // 👈 icono en móvil, botón completo en pantallas grandes
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
      // Ícono con badge para móviles
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
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Botón completo en pantallas grandes
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.filter_alt),
        const SizedBox(width: 6),
        const Text('Filtros'),
        if (activeCount > 0) ...[
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 10,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              '$activeCount',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );

    return OutlinedButton(onPressed: onPressed, child: child);
  }
}

class _ProductCard extends StatelessWidget {
  final String title;
  final num price;
  final String image;
  final VoidCallback onView;
  // final VoidCallback onBuy; // 👈 COMPRAS DESHABILITADAS

  const _ProductCard({
    required this.title,
    required this.price,
    required this.image,
    required this.onView,
    // required this.onBuy, // 👈 COMPRAS DESHABILITADAS
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black12,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image,
                      size: 40, color: Colors.black45),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('\$${price.toStringAsFixed(2)}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onView,
                        icon: const Icon(Icons.visibility),
                        label: const Text('Ver'),
                      ),
                    ),
                    // const SizedBox(width: 8),
                    // Expanded( // 👈 COMPRAS DESHABILITADAS
                    //   child: FilledButton(
                    //     onPressed: onBuy,
                    //     child: const Text('Comprar'),
                    //   ),
                    // ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Próximamente',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
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
