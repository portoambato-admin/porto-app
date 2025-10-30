// lib/ui/components/slide_over_form.dart
import 'package:flutter/material.dart';

double _panelWidth(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  // desktop: entre 420–520 px
  final target = w * 0.4;
  return target.clamp(420.0, 520.0);
}

/// Abre un formulario: slide-over en desktop, fullscreen modal en móvil.
Future<T?> showAdminForm<T>(
  BuildContext context, {
  required String title,
  required Widget child,
  List<Widget>? actions, // botones en el AppBar del form (Guardar/Cancelar, etc.)
}) {
  final w = MediaQuery.of(context).size.width;
  final isDesktop = w >= 1024;

  if (!isDesktop) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FormScaffold(title: title, child: child, actions: actions),
    );
  }

  // Slide-over (derecha)
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) {
      final width = _panelWidth(context);
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: width,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: kElevationToShadow[8],
            ),
            child: _FormScaffold(title: title, child: child, actions: actions),
          ),
        ),
      );
    },
    transitionBuilder: (_, anim, __, child) {
      return SlideTransition(
        position:
            Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        ),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(anim),
          child: child,
        ),
      );
    },
  );
}

class _FormScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const _FormScaffold({
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
      backgroundColor: cs.surface,
    );
  }
}
