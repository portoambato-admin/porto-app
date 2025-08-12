import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/home_screen.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  // Función para abrir URLs
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir $url');
    }
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
                  _SocialIcon(
                    icon: Icons.facebook,
                    label: 'Facebook',
                    onTap: () => _launchUrl('https://facebook.com/portoambato'),
                  ),
                  _SocialIcon(
                    icon: Icons.camera_front_rounded,
                    label: 'Instagram',
                    onTap: () => _launchUrl('https://instagram.com/portoambato'),
                  ),
                  _SocialIcon(
                    icon: Icons.one_x_mobiledata,
                    label: 'Twitter/X',
                    onTap: () => _launchUrl('https://twitter.com/portoambato'),
                  ),
                  _SocialIcon(
                    icon: Icons.youtube_searched_for,
                    label: 'YouTube',
                    onTap: () => _launchUrl('https://youtube.com/portoambato'),
                  ),
                  _SocialIcon(
                    icon: Icons.phonelink_setup,
                    label: 'WhatsApp',
                    onTap: () => _launchUrl('https://wa.me/593999999999'),
                  ),
                  _SocialIcon(
                    icon: Icons.work_outline,
                    label: 'LinkedIn',
                    onTap: () => _launchUrl('https://linkedin.com/company/portoambato'),
                  ),
                  _SocialIcon(
                    icon: Icons.tiktok,
                    label: 'TikTok',
                    onTap: () => _launchUrl('https://tiktok.com/@portoambato'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Enlaces legales
              Wrap(
                spacing: 24,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: const [
                  _FooterLink('Términos'),
                  _FooterLink('Privacidad'),
                  _FooterLink('Contacto'),
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
  const _FooterLink(this.text);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(foregroundColor: Colors.white),
      child: Text(text),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
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
      icon: Icon(icon, color: Colors.white, size: 28),
    );
  }
}
