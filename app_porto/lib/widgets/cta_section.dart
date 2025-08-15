import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/home_screen.dart';

class CTASection extends StatelessWidget {
  const CTASection({super.key});

  Future<void> _abrirReserva(BuildContext context) async {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reserva tu cupo'),
        content: const Text(
          'Completa tu reserva para asegurar tu lugar en la academia. '
          'Podrás enviarnos tus datos y nos pondremos en contacto contigo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
          FilledButton(
            onPressed: () async {
              // URL de ejemplo (puedes cambiarla por tu enlace real)
              final url = Uri.parse('https://wa.me/593995650089?text=Hola,%20quiero%20reservar%20mi%20cupo');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Reservar ahora'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: HomeScreen.maxContentWidth),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '¿Listo para unirte?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Reserva tu cupo hoy y recibe la guía de bienvenida.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _abrirReserva(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Reservar mi cupo'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
