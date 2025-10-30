import 'package:flutter/material.dart';

class HubOption {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  HubOption({required this.icon, required this.label, required this.onTap});
}

class PanelHubCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final List<HubOption> options;
  final bool initiallyExpanded;

  const PanelHubCard({
    super.key,
    required this.icon,
    required this.title,
    required this.options,
    this.initiallyExpanded = false,
  });

  @override
  State<PanelHubCard> createState() => _PanelHubCardState();
}

class _PanelHubCardState extends State<PanelHubCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(widget.icon, color: cs.onSecondaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.chevron_right),
                ],
              ),

              // Opciones
              AnimatedCrossFade(
                firstChild: const SizedBox(height: 0),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 2),
                  child: Column(
                    children: [
                      const Divider(height: 18),
                      ...widget.options.map(
                        (opt) => ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 6),
                          leading: Icon(opt.icon),
                          title: Text(opt.label),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: opt.onTap,
                        ),
                      ),
                    ],
                  ),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
