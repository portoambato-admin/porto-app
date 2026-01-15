import 'package:flutter/material.dart';
import 'package:app_porto/core/config/app_env.dart';
import 'package:app_porto/core/state/auth_state.dart';
import 'package:app_porto/core/state/app_settings_state.dart';
import 'package:app_porto/core/constants/route_names.dart';
import 'package:app_porto/ui/components/breakpoints.dart';

class AdminConfigScreen extends StatelessWidget {
  const AdminConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    return Theme(
      // Forzamos tema claro para esta pantalla
      data: ThemeData.light().copyWith(
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF1976D2),
          secondary: const Color(0xFF0288D1),
          surface: Colors.white,
          background: const Color(0xFFF5F7FA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1976D2),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF1976D2),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
      child: AnimatedBuilder(
        animation: settings,
        builder: (context, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            appBar: AppBar(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.settings, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Configuración'),
                ],
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (!settings.loaded)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                  ),

                _SectionCard(
                  icon: Icons.palette_outlined,
                  title: 'Apariencia',
                  subtitle: 'Personaliza el aspecto visual',
                  children: [
                    _ThemeModeTile(
                      value: settings.themeMode,
                      onChanged: settings.setThemeMode,
                    ),
                    _TextScaleTile(
                      value: settings.textScale,
                      onChanged: settings.setTextScale,
                    ),
                    _SwitchTileModern(
                      value: settings.compactDensity,
                      onChanged: settings.setCompactDensity,
                      icon: Icons.compress,
                      title: 'Modo compacto',
                      subtitle: 'Reduce espacios y densidad visual',
                    ),
                    _SwitchTileModern(
                      value: settings.reduceAnimations,
                      onChanged: settings.setReduceAnimations,
                      icon: Icons.animation,
                      title: 'Reducir animaciones',
                      subtitle: 'Transiciones más simples para mejor rendimiento',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _SectionCard(
                  icon: Icons.notifications_outlined,
                  title: 'Notificaciones',
                  subtitle: 'Gestiona tus alertas',
                  children: [
                    _SwitchTileModern(
                      value: settings.inAppNotifications,
                      onChanged: settings.setInAppNotifications,
                      icon: Icons.notifications_active,
                      title: 'Notificaciones in-app',
                      subtitle: 'Habilita el módulo de alertas dentro de la app',
                    ),
                    _SwitchTileModern(
                      value: settings.notificationBadge,
                      onChanged: settings.setNotificationBadge,
                      icon: Icons.circle_notifications,
                      title: 'Badge en campana',
                      subtitle: 'Muestra contador de no leídos',
                    ),
                    _ActionTile(
                      icon: Icons.inbox,
                      title: 'Bandeja de notificaciones',
                      subtitle: 'Gestionar alertas del sistema',
                      onTap: () => Navigator.pushNamed(
                          context, RouteNames.notificaciones),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _SectionCard(
                  icon: Icons.file_download_outlined,
                  title: 'Reportes y descargas',
                  subtitle: 'Configuración de exportación',
                  children: [
                    _SwitchTileModern(
                      value: settings.exportPdfEnabled,
                      onChanged: settings.setExportPdfEnabled,
                      icon: Icons.picture_as_pdf,
                      title: 'Exportación PDF',
                      subtitle: 'Permitir descargas en formato PDF',
                    ),
                    _SwitchTileModern(
                      value: settings.exportExcelEnabled,
                      onChanged: settings.setExportExcelEnabled,
                      icon: Icons.table_chart,
                      title: 'Exportación Excel',
                      subtitle: 'Permitir descargas en formato Excel',
                    ),
                    _PreferredExportTile(
                      enabledPdf: settings.exportPdfEnabled,
                      enabledExcel: settings.exportExcelEnabled,
                      value: settings.preferredExport,
                      onChanged: settings.setPreferredExport,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _SectionCard(
                  icon: Icons.security_outlined,
                  title: 'Seguridad',
                  subtitle: 'Protección y privacidad',
                  children: [
                    _SwitchTileModern(
                      value: settings.confirmDestructiveActions,
                      onChanged: settings.setConfirmDestructiveActions,
                      icon: Icons.warning_amber,
                      title: 'Confirmar acciones críticas',
                      subtitle:
                          'Solicita confirmación al eliminar o desactivar elementos',
                    ),
                    _SecurityActions(),
                  ],
                ),

                const SizedBox(height: 16),

                _SectionCard(
                  icon: Icons.info_outline,
                  title: 'Información del sistema',
                  subtitle: 'Detalles de tu sesión',
                  children: [
                    _SessionInfo(),
                  ],
                ),

                const SizedBox(height: 24),

                _ResetButton(settings: settings),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Card moderna con cabecera destacada
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final List<Widget> dividedChildren = [];
    for (var i = 0; i < children.length; i++) {
      dividedChildren.add(children[i]);
      if (i < children.length - 1) {
        dividedChildren.add(
          Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
        );
      }
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera con gradiente sutil
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1976D2).withOpacity(0.05),
                  const Color(0xFF1976D2).withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...dividedChildren,
        ],
      ),
    );
  }
}

/// Switch moderno con iconos
class _SwitchTileModern extends StatelessWidget {
  const _SwitchTileModern({
    required this.value,
    required this.onChanged,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: value
              ? const Color(0xFF1976D2).withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 22,
          color: value ? const Color(0xFF1976D2) : Colors.grey.shade600,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF1976D2),
      ),
    );
  }
}

/// Action tile moderna
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 22, color: Colors.grey.shade700),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}

class _ResetButton extends StatelessWidget {
  final dynamic settings;

  const _ResetButton({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: OutlinedButton.icon(
          icon: const Icon(Icons.restart_alt, size: 20),
          label: const Text('Restablecer valores por defecto'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange.shade700,
            side: BorderSide(color: Colors.orange.shade200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            final ok = await _confirm(
              context,
              title: 'Restablecer configuración',
              message:
                  'Se restaurarán los valores por defecto de la configuración local.\n\n¿Deseas continuar?',
              confirmText: 'Restablecer',
              isDestructive: true,
            );
            if (ok == true) {
              await settings.resetToDefaults();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Configuración restablecida.'),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.brightness_6,
                  size: 22,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tema',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Apariencia de la aplicación',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('Auto'),
                icon: Icon(Icons.brightness_auto, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Claro'),
                icon: Icon(Icons.light_mode, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Oscuro'),
                icon: Icon(Icons.dark_mode, size: 18),
              ),
            ],
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.first),
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const Color(0xFF1976D2);
                }
                return Colors.grey.shade100;
              }),
              foregroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                return Colors.grey.shade700;
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextScaleTile extends StatelessWidget {
  const _TextScaleTile({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.format_size,
                  size: 22,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tamaño de texto',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Escalado: $pct%',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF1976D2),
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: const Color(0xFF1976D2),
              overlayColor: const Color(0xFF1976D2).withOpacity(0.1),
              valueIndicatorColor: const Color(0xFF1976D2),
            ),
            child: Slider(
              value: value,
              min: 0.85,
              max: 1.25,
              divisions: 4,
              label: '$pct%',
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferredExportTile extends StatelessWidget {
  const _PreferredExportTile({
    required this.enabledPdf,
    required this.enabledExcel,
    required this.value,
    required this.onChanged,
  });

  final bool enabledPdf;
  final bool enabledExcel;
  final ReportExportFormat value;
  final ValueChanged<ReportExportFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!enabledPdf && !enabledExcel) return const SizedBox.shrink();

    final segments = <ButtonSegment<ReportExportFormat>>[];
    if (enabledPdf) {
      segments.add(const ButtonSegment(
        value: ReportExportFormat.pdf,
        label: Text('PDF'),
        icon: Icon(Icons.picture_as_pdf, size: 18),
      ));
    }
    if (enabledExcel) {
      segments.add(const ButtonSegment(
        value: ReportExportFormat.excel,
        label: Text('Excel'),
        icon: Icon(Icons.table_chart, size: 18),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.file_present,
                  size: 22,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Formato por defecto',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<ReportExportFormat>(
            segments: segments,
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.first),
            showSelectedIcon: false,
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const Color(0xFF1976D2);
                }
                return Colors.grey.shade100;
              }),
              foregroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                return Colors.grey.shade700;
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            final ok = await _confirm(
              context,
              title: 'Cerrar sesión',
              message:
                  'Se cerrará tu sesión en este dispositivo.\n\n¿Continuar?',
              confirmText: 'Cerrar sesión',
            );
            if (ok == true) {
              try {
                await auth.signOut();
              } catch (_) {}
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true)
                    .pushNamedAndRemoveUntil(RouteNames.root, (_) => false);
              }
            }
          },
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Cerrar sesión'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade50,
            foregroundColor: Colors.red.shade700,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.red.shade200),
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.user;
    final nombre = (user?['nombre'] ?? '').toString().trim();
    final correo = (user?['correo'] ?? '').toString().trim();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF0288D1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre.isEmpty ? 'No autenticado' : nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (correo.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    correo,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool?> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmText,
  bool isDestructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isDestructive
                  ? Colors.red.shade600
                  : const Color(0xFF1976D2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
}