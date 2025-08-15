import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../screens/home_screen.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  // Función para abrir URLs externas
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir $url');
    }
  }

  // Diálogo genérico reutilizable
  Future<void> _showInfoDialog(
    BuildContext context, {
    required String title,
    required Widget body,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(child: body),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D47A1),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: HomeScreen.maxContentWidth),
          child: Column(
            children: [
              // Redes sociales
              Wrap(
                spacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  // Facebook (sin cambios)
                  _SocialIcon(
                    icon: const Icon(Icons.facebook, color: Colors.white, size: 28),
                    label: 'Facebook',
                    onTap: () => _launchUrl('https://facebook.com/portoambato'),
                  ),

                  // Instagram (SVG)
                  _SocialIcon(
                    icon: SvgPicture.asset(
                      'assets/icons/instagram.svg',
                      width: 26,
                      height: 26,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                    label: 'Instagram',
                    onTap: () => _launchUrl('https://instagram.com/portoambato'),
                  ),

                  // YouTube (SVG)
                  _SocialIcon(
                    icon: SvgPicture.asset(
                      'assets/icons/youtube.svg',
                      width: 32,
                      height: 32,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                    label: 'YouTube',
                    onTap: () => _launchUrl('https://youtube.com/portoambato'),
                  ),

                  // WhatsApp (SVG)
                  _SocialIcon(
                    icon: SvgPicture.asset(
                      'assets/icons/whatsapp.svg',
                      width: 26,
                      height: 26,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                    label: 'WhatsApp',
                    onTap: () => _launchUrl('https://wa.me/593995650089'),
                  ),

                  // TikTok (ojo: Icons.tiktok no existe en Material; si falla, cámbialo por un SVG)
                  _SocialIcon(
                    icon: const Icon(Icons.tiktok, color: Colors.white, size: 28),
                    label: 'TikTok',
                    onTap: () => _launchUrl('https://tiktok.com/@portoambato'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Enlaces legales (abren diálogo)
              Wrap(
                spacing: 24,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _FooterLink(
                    text: 'Términos',
                    onPressed: () => _showInfoDialog(
                      context,
                      title: 'Términos y Condiciones',
                      body: const Text(
                        'Bienvenido a PortoAmbato. El uso de este sitio implica la aceptación de estos términos. '
                        'Los contenidos son informativos y pueden cambiar sin notificación. '
                        'Queda prohibido el uso no autorizado del material publicado. '
                        'Para inscripciones y pagos, aplican términos específicos comunicados al momento de la contratación.',
                      ),
                    ),
                  ),
                  _FooterLink(
                    text: 'Privacidad',
                    onPressed: () => _showInfoDialog(
                      context,
                      title: 'Política de Privacidad',
                      body: const Text(
                        'Respetamos tu privacidad. Recopilamos datos básicos de navegación y, en caso de formularios, '
                        'los datos que nos proporciones (por ejemplo, nombre y contacto) para gestionar tu solicitud. '
                        'No compartimos información personal con terceros salvo obligación legal o proveedores estrictamente necesarios. '
                        'Puedes solicitar acceso o eliminación de tus datos escribiéndonos.',
                      ),
                    ),
                  ),
                  _FooterLink(
                    text: 'Contacto',
                    onPressed: () => _showInfoDialog(
                      context,
                      title: 'Contacto',
                      body: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '¿Tienes dudas o quieres conocer más sobre la academia? '
                            'Escríbenos por WhatsApp o correo, o visítanos en nuestras instalaciones.',
                          ),
                          const SizedBox(height: 12),
                          SelectableText('WhatsApp: +593 99 565 0089'),
                          const SizedBox(height: 4),
                          SelectableText('Correo: portoambatoapp@gmail.com'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => _launchUrl('https://wa.me/593995650089'),
                            child: const Text('Abrir WhatsApp'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Copyright
              Text(
                '© ${DateTime.now().year} PortoAmbato. Todos los derechos reservados.',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const _FooterLink({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: Colors.white),
      child: Text(text),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final Widget icon; // Acepta Icon o cualquier Widget (SVG, imagen, etc.)
  final String label;
  final VoidCallback onTap;

  const _SocialIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: label,
      icon: icon,
    );
  }
}
