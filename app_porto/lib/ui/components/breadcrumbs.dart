// lib/ui/components/breadcrumbs.dart
import 'package:flutter/material.dart';

class Crumb {
  final String label;
  final VoidCallback? onTap;
  const Crumb(this.label, {this.onTap});
}

class Breadcrumbs extends StatelessWidget {
  final List<Crumb> items;
  final EdgeInsets padding;
  const Breadcrumbs({super.key, required this.items, this.padding = const EdgeInsets.symmetric(horizontal: 12)});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge;
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: padding,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [
          const Icon(Icons.admin_panel_settings_outlined, size: 18),
          ...List.generate(items.length * 2 - 1, (i) {
            if (i.isOdd) {
              return Text('›', style: textStyle?.copyWith(color: color));
            }
            final idx = i ~/ 2;
            final c = items[idx];
            final w = Text(c.label, style: textStyle);
            return c.onTap != null ? InkWell(onTap: c.onTap, child: w) : w;
          }),
        ],
      ),
    );
  }
}
