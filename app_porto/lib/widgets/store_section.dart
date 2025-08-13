import 'package:flutter/material.dart';
import '../screens/home_screen.dart';

class StoreSection extends StatelessWidget {
  const StoreSection({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

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
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 60,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Próximamente',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Muy pronto estará disponible la nueva indumentaria oficial.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
