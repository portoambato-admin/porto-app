import 'package:flutter/material.dart';
import '../widgets/top_navbar.dart';

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
      'image': 'assets/img/categorias/sub4.jpg',
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
      'image': 'assets/img/categorias/sub6.jpg',
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
      'image': 'assets/img/categorias/sub8.jpg',
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
      'image': 'assets/img/categorias/sub10.jpg',
      'desc':
          'Trabajo táctico grupal, preparación física específica y evaluación de rendimiento.',
    },
    {
      'name': 'Sub-12',
      'age': '11–12 años',
      'days': 'Lun · Mié · Vie',
      'time': '18:30–20:00',
      'coach': 'Christian Llerena, Victor Flores ',
      'level': 'Formatica',
      'image': 'assets/img/categorias/sub12.jpg',
      'desc':
          'Modelo de juego, análisis de video, roles por posición y proyección competitiva.',
    },
  ];

  // Filtros/estado UI
  final TextEditingController _searchCtrl = TextEditingController();
  String _level = 'Todas'; // Formativa / Intermedia / Avanzada / Todas
  String _day = 'Todos';   // Lunes, Martes... / Todos
  String _sort = 'Por nombre'; // Por nombre / Más temprano

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();

    List<Map<String, dynamic>> data = _categories.where((c) {
      final matchText = q.isEmpty ||
          (c['name'] as String).toLowerCase().contains(q) ||
          (c['desc'] as String).toLowerCase().contains(q);
      final matchLevel = _level == 'Todas' || c['level'] == _level;
      final matchDay = _day == 'Todos' || (c['days'] as String).toLowerCase().contains(_day.toLowerCase());
      return matchText && matchLevel && matchDay;
    }).toList();

    switch (_sort) {
      case 'Más temprano':
        // Ordena por hora de inicio (asumiendo formato HH:mm–HH:mm)
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
                  aspectRatio: 16/9,
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
              Text(c['name'], style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8, runSpacing: 8,
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
                        // Futuro: ir a formulario / WhatsApp
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
                Text('Categorías', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                _Toolbar(
                  searchCtrl: _searchCtrl,
                  level: _level,
                  day: _day,
                  sort: _sort,
                  onLevelChanged: (v) => setState(() => _level = v),
                  onDayChanged: (v) => setState(() => _day = v),
                  onSortChanged: (v) => setState(() => _sort = v),
                  onSearchChanged: (_) => setState(() {}),
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

class _Toolbar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String level;
  final String day;
  final String sort;
  final ValueChanged<String> onLevelChanged;
  final ValueChanged<String> onDayChanged;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<String> onSearchChanged;

  const _Toolbar({
    required this.searchCtrl,
    required this.level,
    required this.day,
    required this.sort,
    required this.onLevelChanged,
    required this.onDayChanged,
    required this.onSortChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 850;

    final row = [
      Expanded(
        flex: 3,
        child: TextField(
          controller: searchCtrl,
          onChanged: onSearchChanged,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Buscar categoría...',
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 2,
        child: DropdownButtonFormField<String>(
          value: level,
          items: const [
            DropdownMenuItem(value: 'Todas', child: Text('Todas')),
            DropdownMenuItem(value: 'Formativa', child: Text('Formativa')),
            DropdownMenuItem(value: 'Intermedia', child: Text('Intermedia')),
            DropdownMenuItem(value: 'Avanzada', child: Text('Avanzada')),
          ],
          onChanged: (v) => onLevelChanged(v ?? 'Todas'),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.filter_alt), labelText: 'Nivel'),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 2,
        child: DropdownButtonFormField<String>(
          value: day,
          items: const [
            DropdownMenuItem(value: 'Todos', child: Text('Todos')),
            DropdownMenuItem(value: 'Lun', child: Text('Lunes')),
            DropdownMenuItem(value: 'Mar', child: Text('Martes')),
            DropdownMenuItem(value: 'Mié', child: Text('Miércoles')),
            DropdownMenuItem(value: 'Jue', child: Text('Jueves')),
            DropdownMenuItem(value: 'Vie', child: Text('Viernes')),
            DropdownMenuItem(value: 'Sáb', child: Text('Sábado')),
          ],
          onChanged: (v) => onDayChanged(v ?? 'Todos'),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.event), labelText: 'Día'),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 2,
        child: DropdownButtonFormField<String>(
          value: sort,
          items: const [
            DropdownMenuItem(value: 'Por nombre', child: Text('Por nombre')),
            DropdownMenuItem(value: 'Más temprano', child: Text('Más temprano')),
          ],
          onChanged: (v) => onSortChanged(v ?? 'Por nombre'),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.sort), labelText: 'Ordenar'),
        ),
      ),
    ];

    return isSmall
        ? Column(
            children: [
              row[0],
              const SizedBox(height: 12),
              row[2],
              const SizedBox(height: 12),
              row[4],
              const SizedBox(height: 12),
              row[6],
            ],
          )
        : Row(children: row);
  }
}

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
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.6),
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
