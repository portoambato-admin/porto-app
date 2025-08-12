import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../utils/contact.dart';

class StoreSection extends StatelessWidget {
  const StoreSection({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'image': 'assets/img/camiseta.jpg',
        'title': 'Camiseta Oficial',
        'price': '\$20',
      },
      {
        'image': 'assets/img/pantaloneta.jpg',
        'title': 'Pantaloneta Oficial',
        'price': '\$15',
      },
      {
        'image': 'assets/img/medias.jpg',
        'title': 'Medias Deportivas',
        'price': '\$5',
      },
    ];

    final w = MediaQuery.of(context).size.width;
    final cross = w >= 900
        ? 3
        : w >= 600
        ? 2
        : 1;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: HomeScreen.maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
          child: Column(
            children: [
              Text(
                'Adquirir nueva indumentaria',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cross,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 280,
                ),
                itemBuilder: (_, i) {
                  final item = items[i];
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.asset(
                              item['image']!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.black12,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.image,
                                  size: 40,
                                  color: Colors.black45,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['price']!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FilledButton(
                                onPressed: () =>
                                    showPurchaseDialog(context, item['title']!),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 40),
                                ),
                                child: const Text('Comprar'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
