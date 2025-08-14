// lib/widgets/hero_section.dart
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isSmall = w < 900;

    final textBlock = Column(
      crossAxisAlignment: isSmall
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          'Formamos talento. Inspiramos disciplina.',
          textAlign: isSmall ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Academia Oficial de Fútbol Porto Ambato. Entrenamientos por categorías, '
          'evaluaciones de rendimiento y gestión integral para familias y estudiantes.',
          textAlign: isSmall ? TextAlign.center : TextAlign.start,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.black87),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: isSmall ? WrapAlignment.center : WrapAlignment.start,
          children: [
            FilledButton.icon(
              onPressed: () async {
                const phone = '+593995650089'; // Cambia por el número real
                const message =
                    'Hola, quiero más información sobre la preinscripción';
                final url = Uri.parse(
                  'https://wa.me/${phone.replaceAll('+', '')}?text=${Uri.encodeComponent(message)}',
                );

                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  throw 'No se pudo abrir WhatsApp';
                }
              },
              icon: const Icon(Icons.how_to_reg),
              label: const Text('Preinscribirme'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/categorias');
              },
              icon: const Icon(Icons.visibility),
              label: const Text('Ver categorías'),
            ),
          ],
        ),
      ],
    );

    final imageBlock = AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/img/webp/main.webp',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.black12,
                alignment: Alignment.center,
                child: const Icon(Icons.image, size: 64, color: Colors.black45),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.15), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      color: const Color(0xFFF7F9FC),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: HomeScreen.maxContentWidth,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 16 : 24,
              vertical: isSmall ? 32 : 64,
            ),
            child: isSmall
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      textBlock,
                      const SizedBox(height: 24),
                      // En móvil NO uses Expanded con flex 0
                      imageBlock,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // En desktop sí expandimos
                      Expanded(flex: 5, child: textBlock),
                      const SizedBox(width: 24),
                      Expanded(flex: 5, child: imageBlock),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
