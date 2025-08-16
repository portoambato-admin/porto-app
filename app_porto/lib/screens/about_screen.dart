import 'package:flutter/material.dart';
import '../widgets/top_navbar.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const double maxContentWidth = 1200;

  // ===== Datos estáticos (cámbialos por los reales) =====
  static const Map<String, String> ceo = {
    'name': 'Mg. Christian Llerena',
    'role': 'Director Deportivo',
    'photo': 'assets/img/profes/gerente.jpg',
    'bio':
        'Apasionado por el fútbol formativo y el desarrollo integral. '
        '5+ años liderando proyectos deportivos con enfoque metodológico y humano.',
  };

  static final List<Map<String, String>> coaches = [
    {
      'name': 'Victor Flores',
      'role': 'Profesor · Sub-4 / Sub-6 / Sub-8 / Sub-12',
      'photo': 'assets/img/profes/p1.webp',
      'bio': '• Licenciado en Pedagogía de la Actividad Física y Deporte.\n'
          '• Certificación CONMEBOL Enfoque Lúdico Fútbol Infantil.',
    },
    {
      'name': 'Michelle Cherez',
      'role': 'Profesor · Sub-4',
      'photo': 'assets/img/profes/p2.webp',
      'bio': '• Licenciado en Pedagogía de la Actividad Física y Deporte.\n'
          '• Certificación CONMEBOL Enfoque Lúdico Fútbol Infantil.',
    },
    {
      'name': 'Klever de la Cruz',
      'role': 'Profesor · Sub-4 / Sub-6 / Sub-10',
      'photo': 'assets/img/profes/p3.webp',
      'bio': '• Licenciado en Pedagogía de la Actividad Física y Deporte.\n'
          '• Certificación CONMEBOL Enfoque Lúdico Fútbol Infantil.',
    },
    {
      'name': 'Alvaro Ortiz',
      'role': 'Profesor · Sub-4 ',
      'photo': 'assets/img/profes/p4.webp',
      'bio': '• Licenciado en Pedagogía de la Actividad Física y Deporte.\n'
          '• Certificación CONMEBOL Enfoque Lúdico Fútbol Infantil.',
    },
  ];

  static final List<String> facilities = [
    'assets/img/conocenos/instalaciones/ins_1.webp',
    'assets/img/conocenos/instalaciones/ins_2.jpg',
    'assets/img/conocenos/instalaciones/ins_3.webp',
    'assets/img/conocenos/instalaciones/ins_4.webp',
  ];
  // =======================================================

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w >= 1000;
    final cross = w >= 1100 ? 4 : w >= 850 ? 3 : w >= 600 ? 2 : 1;

    return Scaffold(
      appBar: const TopNavBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ====== 1) Gerente General (Hero lateral) ======
                Text(
                  'Conócenos',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                _CeoHero(data: ceo, isWide: isWide),
                const SizedBox(height: 28),

                // ====== 2) Profesores ======
                Text(
                  'Profesores',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: coaches.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cross,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 320,
                  ),
                  itemBuilder: (_, i) => _CoachCard(coach: coaches[i]),
                ),
                const SizedBox(height: 28),

                // ====== 3) Instalaciones (galería simple) ======
                Text(
                  'Instalaciones',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                _FacilitiesGallery(images: facilities),
                const SizedBox(height: 12),
                const Text(
                  'Contamos con canchas de césped natural, gimnasio y espacios seguros para el desarrollo deportivo.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CeoHero extends StatelessWidget {
  final Map<String, String> data;
  final bool isWide;
  const _CeoHero({required this.data, required this.isWide});

  void _openDetail(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(data['name'] ?? ''),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            // Evita overflow: limita la altura del contenido del diálogo
            maxWidth: 520,
            maxHeight: h * 0.75,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.asset(
                      data['photo'] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.black12,
                        alignment: Alignment.center,
                        child: const Icon(Icons.person, size: 40, color: Colors.black45),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    data['role'] ?? '',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    data['bio'] ?? '',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 12),
                // ===== Zona para agregar más información del gerente =====
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Información adicional:\n\n'
                    '• Mg. Marketing estratégico.\n'
                    '• Ing. Negocios y Marketing Deportivo.\n'
                    '• Mg. Docencia universitaria.\n'
                    '• Director Técnico de Fútbol - Instructor de Fútbol Infantil (ATFA, Argentina).\n'
                    '• Oficial de patrocinio, Liga Pro (Ecuador).\n'
                    '• Diplomado en gestión deportiva (CONMEBOL Evolución).\n'
                    '• Certificación CONMEBOL Enfoque Lúdico Fútbol Infantil.',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = data['photo'] ?? '';
    final name = data['name'] ?? '';
    final role = data['role'] ?? '';
    final bio = data['bio'] ?? '';

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Image.asset(
          photo,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.black12,
            alignment: Alignment.center,
            child: const Icon(Icons.person, size: 64, color: Colors.black45),
          ),
        ),
      ),
    );

    final info = Card(
      elevation: 0.8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(role, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(bio, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => _openDetail(context),
                icon: const Icon(Icons.visibility),
                label: const Text('Ver más'),
              ),
            ),
          ],
        ),
      ),
    );

    return isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: image),
              const SizedBox(width: 24),
              Expanded(flex: 5, child: info),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              image,
              const SizedBox(height: 12),
              info,
            ],
          );
  }
}

class _CoachCard extends StatelessWidget {
  final Map<String, String> coach;
  const _CoachCard({required this.coach});

  void _openDetail(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(coach['name'] ?? ''),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: h * 0.75, // límite de altura para evitar overflow
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.asset(
                      coach['photo'] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.black12,
                        alignment: Alignment.center,
                        child: const Icon(Icons.person, size: 40, color: Colors.black45),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(coach['role'] ?? '', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(coach['bio'] ?? ''),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final img = coach['photo'] ?? '';
    return Card(
      elevation: 0.8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(
                img,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black12,
                  alignment: Alignment.center,
                  child: const Icon(Icons.person, size: 40, color: Colors.black45),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(coach['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Text(coach['role'] ?? ''),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openDetail(context),
                        icon: const Icon(Icons.visibility),
                        label: const Text('Ver más'),
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

class _FacilitiesGallery extends StatelessWidget {
  final List<String> images;
  const _FacilitiesGallery({required this.images});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cross = w >= 1100 ? 3 : w >= 800 ? 2 : 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 16 / 9,
      ),
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          images[i],
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.black12,
            alignment: Alignment.center,
            child: const Icon(Icons.image, size: 40, color: Colors.black45),
          ),
        ),
      ),
    );
  }
}
