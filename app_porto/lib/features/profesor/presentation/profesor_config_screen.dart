import 'package:flutter/material.dart';
import 'package:app_porto/core/state/app_settings_state.dart';

class ProfesorConfigScreen extends StatelessWidget {
  const ProfesorConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Configuración')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.palette_outlined),
                      title: Text('Apariencia'),
                      subtitle: Text('Preferencias locales del dispositivo'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Tema'),
                      trailing: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(value: ThemeMode.system, label: Text('Sistema')),
                          ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
                          ButtonSegment(value: ThemeMode.dark, label: Text('Oscuro')),
                        ],
                        selected: {settings.themeMode},
                        onSelectionChanged: (s) => settings.setThemeMode(s.first),
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_outlined),
                      value: settings.inAppNotifications,
                      onChanged: settings.setInAppNotifications,
                      title: const Text('Notificaciones in-app'),
                      subtitle: const Text('Habilitar notificaciones dentro de la app.'),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.mark_email_unread_outlined),
                      value: settings.notificationBadge,
                      onChanged: settings.setNotificationBadge,
                      title: const Text('Badge en campana'),
                      subtitle: const Text('Muestra contador de no leídos.'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
