// lib/features/admin/sections/students_by_subcategoria_screen.dart
import 'package:flutter/material.dart';
import 'package:app_porto/app/app_scope.dart';

class StudentsBySubcategoriaScreen extends StatefulWidget {
  const StudentsBySubcategoriaScreen({super.key});
  @override
  State<StudentsBySubcategoriaScreen> createState() => _StudentsBySubcategoriaScreenState();
}

class _StudentsBySubcategoriaScreenState extends State<StudentsBySubcategoriaScreen> {
  late final _subs = AppScope.of(context).subcategorias;
  late final _est  = AppScope.of(context).estudiantes;
  List<Map<String, dynamic>> _subList = [];
  Map<int, List<Map<String, dynamic>>> _cache = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSubs();
  }

  Future<void> _loadSubs() async {
    setState(() => _loading = true);
    try {
      final all = await _subs.todas(); // o activas()
      if (!mounted) return;
      setState(() => _subList = all.where((e) => (e['activo'] == true)).toList());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchEstudiantes(int idSub) async {
    if (_cache.containsKey(idSub)) return _cache[idSub]!;
    final list = await _est.porSubcategoria(idSub); // agrega este método si no lo tienes
    _cache[idSub] = list;
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(title: const Text('Estudiantes por subcategoría')),
      body: ListView.builder(
        itemCount: _subList.length,
        itemBuilder: (_, i) {
          final s = _subList[i];
          final id = s['id'] as int? ?? s['id_subcategoria'] as int;
          final nombre = s['nombre'] ?? s['nombre_subcategoria'] ?? '—';
          return ExpansionTile(
            title: Text(nombre),
            children: [
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchEstudiantes(id),
                builder: (_, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: LinearProgressIndicator(),
                    );
                  }
                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Sin estudiantes.'),
                    );
                  }
                  return ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, j) {
                      final e = items[j];
                      return ListTile(
                        title: Text('${e['nombres']} ${e['apellidos']}'),
                        subtitle: Text('ID: ${e['id']}'),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
