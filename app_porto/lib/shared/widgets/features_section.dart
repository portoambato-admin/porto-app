import 'package:flutter/material.dart';
import '../../features/public/presentation/screen/home_screen.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  static const _routeConocenos = '/conocenos'; // <-- cámbiala si tu ruta es distinta

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cross = w >= 1100 ? 4 : w >= 800 ? 3 : w >= 600 ? 2 : 1;

    final items = const [
      (Icons.schedule, 'Horarios por categorías', 'Entrenamientos adaptados por edad y nivel.'),
      (Icons.stacked_line_chart, 'Evaluación de rendimiento', 'Seguimiento de progreso y métricas.'),
      (Icons.payments, 'Pagos y mensualidades', 'Gestión clara y recordatorios.'),
      (Icons.groups_2, 'Profesores certificados', 'Equipo con experiencia y metodología.'),
    ];

    void _onTapItem(int index) {
      // índice 3 = "Profesores certificados"
      if (index == 3) {
        Navigator.of(context).pushNamed(_routeConocenos);
      }
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: HomeScreen.maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
          child: Column(
            children: [
              Text(
                '¿Por qué elegir PortoAmbato?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cross,
                  mainAxisExtent: 160,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final (icon, title, desc) = items[i];
                  final isProfes = i == 3;

                  return Card(
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _onTapItem(i),
                      borderRadius: BorderRadius.circular(12),
                      mouseCursor: SystemMouseCursors.click,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(icon, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      if (isProfes)
                                        const Tooltip(
                                          message: 'Ir a Conócenos',
                                          child: Icon(Icons.open_in_new, size: 18),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(desc),
                                ],
                              ),
                            ),
                          ],
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
    );
  }
}
