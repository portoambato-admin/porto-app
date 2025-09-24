import 'package:flutter/material.dart';
import '../../../../shared/widgets/top_navbar.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  static const double maxContentWidth = 1200;

  // Datos estáticos (fáciles de reemplazar por API luego)
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Sub-4',
      'age': '3–4 años',
      'days': 'Mié · Vie',
      'time': '11:00–12:00',
      'coach': 'Michelle Cherez, Victor Flores, Klever de la Cruz, Alvaro Ortiz',
      'level': 'Estimulación Temprana',
      'image': 'assets/img/categorias/sub4.webp',
      'desc':
          'Iniciación lúdica al fútbol: coordinación, psicomotricidad y trabajo en equipo con enfoque recreativo.',
    },
    {
      'name': 'Sub-6',
      'age': '5–6 años',
      'days': 'Mar · Jue · Vir',
      'time': '16:00–18:00',
      'coach': 'Victor Flores, Klever de la Cruz',
      'level': 'Intermedia',
      'image': 'assets/img/categorias/sub6.webp',
      'desc':
          'Fundamentos técnicos básicos: pase, recepción y conducción, dinámicas divertidas con progresión.',
    },
    {
      'name': 'Sub-8',
      'age': '7–8 años',
      'days': 'Mar · Jue · Vie',
      'time': '16:00–18:00',
      'coach': 'Victor Flores, Christian Llerena',
      'level': 'Intermedia',
      'image': 'assets/img/categorias/sub8.webp',
      'desc':
          'Perfeccionamiento técnico, nociones tácticas y disciplina competitiva acorde a la edad.',
    },
    {
      'name': 'Sub-10',
      'age': '10–12 años',
      'days': 'Mar · Mie · Vie ',
      'time': '16:00–18:00',
      'coach': 'Klever de la Cruz, Christian Llerena',
      'level': 'Intermedia',
      'image': 'assets/img/categorias/sub10.webp',
      'desc':
          'Trabajo táctico grupal, preparación física específica y evaluación de rendimiento.',
    },
    {
      'name': 'Sub-12',
      'age': '11–12 años',
      'days': 'Lun · Mié · Vie',
      'time': '18:30–20:00',
      'coach': 'Christian Llerena, Victor Flores ',
      'level': 'Formativa',
      'image': 'assets/img/categorias/sub12.webp',
      'desc':
          'Modelo de juego, análisis de video, roles por posición y proyección competitiva.',
    },
  ];

  // Filtros/estado UI
  final TextEditingController _searchCtrl = TextEditingController();
  String _level = 'Todas'; // Formativa / Intermedia / Avanzada / Todas
  String _day = 'Todos';   // Lun, Mar, Mié, Jue, Vie, Sáb / Todos
  String _sort = 'Por nombre'; // Por nombre / Más temprano

  // Contador de filtros activos (distintos a los por defecto)
  int get _activeFilterCount {
    int c = 0;
    if (_level != 'Todas') c++;
    if (_day != 'Todos') c++;
    if (_sort != 'Por nombre') c++;
    return c;
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();

    List<Map<String, dynamic>> data = _categories.where((c) {
      final matchText = q.isEmpty ||
          (c['name'] as String).toLowerCase().contains(q) ||
          (c['desc'] as String).toLowerCase().contains(q);
      final matchLevel = _level == 'Todas' || (c['level'] as String) == _level;
      final matchDay =
          _day == 'Todos' || (c['days'] as String).toLowerCase().contains(_day.toLowerCase());
      return matchText && matchLevel && matchDay;
    }).toList();

    switch (_sort) {
      case 'Más temprano':
        int startMinutes(String time) {
          final p = time.split('–').first.trim(); // "16:00"
          final hhmm = p.split(':');
          return int.parse(hhmm[0]) * 60 + int.parse(hhmm[1]);
        }
        data.sort((a, b) => startMinutes(a['time']).compareTo(startMinutes(b['time'])));
        break;
      default:
        data.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    }
    return data;
  }

  // Sheet de filtros (Nivel / Día / Ordenar)
  Future<void> _openFiltersSheet() async {
    String tmpLevel = _level;
    String tmpDay = _day;
    String tmpSort = _sort;

    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.filter_alt),
                    const SizedBox(width: 8),
                    Text('Filtros', style: Theme.of(ctx).textTheme.titleLarge),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _level = 'Todas';
                          _day = 'Todos';
                          _sort = 'Por nombre';
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Restablecer'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: tmpLevel,
                  items: const [
                    DropdownMenuItem(value: 'Todas', child: Text('Todas')),
                    DropdownMenuItem(value: 'Formativa', child: Text('Formativa')),
                    DropdownMenuItem(value: 'Intermedia', child: Text('Intermedia')),
                    DropdownMenuItem(value: 'Avanzada', child: Text('Avanzada')),
                    DropdownMenuItem(value: 'Estimulación Temprana', child: Text('Estimulación Temprana')),
                  ],
                  onChanged: (v) => tmpLevel = v ?? 'Todas',
                  decoration: const InputDecoration(
                    labelText: 'Nivel',
                    prefixIcon: Icon(Icons.school),
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: tmpDay,
                  items: const [
                    DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                    DropdownMenuItem(value: 'Lun', child: Text('Lunes')),
                    DropdownMenuItem(value: 'Mar', child: Text('Martes')),
                    DropdownMenuItem(value: 'Mié', child: Text('Miércoles')),
                    DropdownMenuItem(value: 'Jue', child: Text('Jueves')),
                    DropdownMenuItem(value: 'Vie', child: Text('Viernes')),
                    DropdownMenuItem(value: 'Sáb', child: Text('Sábado')),
                  ],
                  onChanged: (v) => tmpDay = v ?? 'Todos',
                  decoration: const InputDecoration(
                    labelText: 'Día',
                    prefixIcon: Icon(Icons.event),
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: tmpSort,
                  items: const [
                    DropdownMenuItem(value: 'Por nombre', child: Text('Por nombre')),
                    DropdownMenuItem(value: 'Más temprano', child: Text('Más temprano')),
                  ],
                  onChanged: (v) => tmpSort = v ?? 'Por nombre',
                  decoration: const InputDecoration(
                    labelText: 'Ordenar',
                    prefixIcon: Icon(Icons.sort),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          setState(() {
                            _level = tmpLevel;
                            _day = tmpDay;
                            _sort = tmpSort;
                          });
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openDetail(Map<String, dynamic> c) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset(
                    c['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.black12,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image, size: 56, color: Colors.black45),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                c['name'],
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(text: c['age']),
                  _Chip(text: c['level']),
                  _Chip(text: c['days']),
                  _Chip(text: c['time']),
                  _Chip(text: c['coach']),
                ],
              ),
              const SizedBox(height: 12),
              Text(c['desc'], style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Inscripción para ${c['name']} (próximamente)')),
                        );
                      },
                      icon: const Icon(Icons.how_to_reg),
                      label: const Text('Inscribirme'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Cerrar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cross = w >= 1100 ? 3 : w >= 800 ? 2 : 1;

    return Scaffold(
      appBar: const TopNavBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categorías',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),

                // Toolbar minimal: buscar + botón/ícono de filtros (con badge)
                _SearchAndFilterBar(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  onOpenFilters: _openFiltersSheet,
                  activeFilters: _activeFilterCount,
                ),

                const SizedBox(height: 16),
                Expanded(
                  child: _filtered.isEmpty
                      ? const _EmptyState()
                      : GridView.builder(
                          itemCount: _filtered.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cross,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 320,
                          ),
                          itemBuilder: (_, i) {
                            final c = _filtered[i];
                            return _CategoryCard(
                              name: c['name'],
                              age: c['age'],
                              level: c['level'],
                              days: c['days'],
                              time: c['time'],
                              coach: c['coach'],
                              image: c['image'],
                              onView: () => _openDetail(c),
                              onEnroll: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Inscripción para ${c['name']} (próximamente)')),
                                );
                              },
                            );
                          },
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

// ===== Toolbar minimal (buscar + filtros con badge) =====

class _SearchAndFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onOpenFilters;
  final int activeFilters;

  const _SearchAndFilterBar({
    required this.controller,
    required this.onChanged,
    required this.onOpenFilters,
    required this.activeFilters,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;

    final searchField = Expanded(
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Buscar categoría…',
        ),
      ),
    );

    final filterButton = _FilterButton(
      onPressed: onOpenFilters,
      activeCount: activeFilters,
      isIconOnly: isSmall, // icono en móvil; botón con texto en pantallas grandes
    );

    return Row(
      children: [
        searchField,
        const SizedBox(width: 8),
        filterButton,
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  final VoidCallback onPressed;
  final int activeCount;
  final bool isIconOnly;

  const _FilterButton({
    required this.onPressed,
    required this.activeCount,
    this.isIconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isIconOnly) {
      // Ícono con badge para móviles
      return Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: onPressed,
            icon: const Icon(Icons.filter_alt),
            tooltip: 'Filtros',
          ),
          if (activeCount > 0)
            Positioned(
              right: 2,
              top: 2,
              child: CircleAvatar(
                radius: 8,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  '$activeCount',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Botón completo en pantallas grandes
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.filter_alt),
        const SizedBox(width: 6),
        const Text('Filtros'),
        if (activeCount > 0) ...[
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 10,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              '$activeCount',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );

    return OutlinedButton(onPressed: onPressed, child: child);
  }
}

// ===== Tarjetas y utilitarios =====

class _CategoryCard extends StatelessWidget {
  final String name;
  final String age;
  final String level;
  final String days;
  final String time;
  final String coach;
  final String image;
  final VoidCallback onView;
  final VoidCallback onEnroll;

  const _CategoryCard({
    required this.name,
    required this.age,
    required this.level,
    required this.days,
    required this.time,
    required this.coach,
    required this.image,
    required this.onView,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black12,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image, size: 40, color: Colors.black45),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _Chip(text: age),
                    _Chip(text: level),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.event, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text(days)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text(time)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text(coach)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onView,
                        icon: const Icon(Icons.visibility),
                        label: const Text('Ver'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onEnroll,
                        icon: const Icon(Icons.how_to_reg),
                        label: const Text('Inscribirme'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text),
      backgroundColor:
          Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.6),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: Colors.black38),
          const SizedBox(height: 12),
          Text('No encontramos categorías con esos filtros.',
              style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
