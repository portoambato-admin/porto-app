import 'package:flutter/material.dart';
import '../widgets/top_navbar.dart';
import '../utils/contact.dart'; // <- importante para WhatsApp

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  static const double maxContentWidth = 1200;

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
        // Relevancia (por ahora sin cambios)
        break;
    }
    return data;
  }

  Future<void> _openAddDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String category = 'Indumentaria';
    final imageCtrl = TextEditingController(text: 'assets/img/'); // ruta estática

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
                    DropdownMenuItem(value: 'Indumentaria', child: Text('Indumentaria')),
                    DropdownMenuItem(value: 'Accesorios', child: Text('Accesorios')),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
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

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cross = w >= 1100 ? 4 : w >= 900 ? 3 : w >= 600 ? 2 : 1;

    return Scaffold(
      appBar: const TopNavBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tienda', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                // Banner informativo
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Estamos trabajando para habilitar compras online. Por ahora, realiza tu pedido por WhatsApp.',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                _Toolbar(
                  searchCtrl: _searchCtrl,
                  category: _category,
                  sort: _sort,
                  onCategoryChanged: (v) => setState(() => _category = v),
                  onSortChanged: (v) => setState(() => _sort = v),
                  onSearchChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
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
                        onBuy: () => showPurchaseDialog(context, p['title']), // <- Comprar por WhatsApp
                      );
                    },
                  ),
                ),
              ],
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
                aspectRatio: 16/9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    p['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.black12,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image, size: 40, color: Colors.black45),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Categoría: ${p['category']}'),
              const SizedBox(height: 4),
              Text('Precio: \$${(p['price'] as num).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
          FilledButton(
            onPressed: () => showPurchaseDialog(context, p['title']), // <- Comprar por WhatsApp
            child: const Text('Comprar por WhatsApp'),
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String category;
  final String sort;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<String> onSearchChanged;

  const _Toolbar({
    required this.searchCtrl,
    required this.category,
    required this.sort,
    required this.onCategoryChanged,
    required this.onSortChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 700;
    final row = [
      // Buscar
      Expanded(
        flex: 3,
        child: TextField(
          controller: searchCtrl,
          onChanged: onSearchChanged,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Buscar producto...',
          ),
        ),
      ),
      const SizedBox(width: 12),
      // Categoría
      Expanded(
        flex: 2,
        child: DropdownButtonFormField<String>(
          value: category,
          items: const [
            DropdownMenuItem(value: 'Todos', child: Text('Todos')),
            DropdownMenuItem(value: 'Indumentaria', child: Text('Indumentaria')),
            DropdownMenuItem(value: 'Accesorios', child: Text('Accesorios')),
          ],
          onChanged: (v) => onCategoryChanged(v ?? 'Todos'),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.filter_list), labelText: 'Categoría'),
        ),
      ),
      const SizedBox(width: 12),
      // Orden
      Expanded(
        flex: 2,
        child: DropdownButtonFormField<String>(
          value: sort,
          items: const [
            DropdownMenuItem(value: 'Relevancia', child: Text('Relevancia')),
            DropdownMenuItem(value: 'Precio: menor a mayor', child: Text('Precio: menor a mayor')),
            DropdownMenuItem(value: 'Precio: mayor a menor', child: Text('Precio: mayor a menor')),
          ],
          onChanged: (v) => onSortChanged(v ?? 'Relevancia'),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.sort), labelText: 'Ordenar por'),
        ),
      ),
    ];

    return isSmall
        ? Column(
            children: [
              row[0],
              const SizedBox(height: 12),
              row[2],
              const SizedBox(height: 12),
              row[4],
            ],
          )
        : Row(children: row);
  }
}

class _ProductCard extends StatelessWidget {
  final String title;
  final num price;
  final String image;
  final VoidCallback onView;
  final VoidCallback onBuy; // <- nuevo

  const _ProductCard({
    required this.title,
    required this.price,
    required this.image,
    required this.onView,
    required this.onBuy,
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black12,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image, size: 40, color: Colors.black45),
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
                    style: TextStyle(color: Theme.of(context).colorScheme.primary)),
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onBuy, // <- Comprar por WhatsApp
                        //icon: const Icon(Icons.shop_two),
                        label: const Text('Comprar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
