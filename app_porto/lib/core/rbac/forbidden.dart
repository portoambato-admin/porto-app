// lib/core/rbac/forbidden.dart
import 'package:flutter/material.dart';

class ForbiddenScreen extends StatelessWidget {
  final String? message;
  const ForbiddenScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 56),
          const SizedBox(height: 12),
          Text('Acceso denegado', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            message ?? 'No tienes permisos para ver esta sección.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
