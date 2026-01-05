import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/route_names.dart';
import '../../../app/app_scope.dart';

class RepresentanteShellScreen extends StatefulWidget {
  const RepresentanteShellScreen({super.key});

  @override
  State<RepresentanteShellScreen> createState() =>
      _RepresentanteShellScreenState();
}

class _RepresentanteShellScreenState extends State<RepresentanteShellScreen> {
  final _fmtMoney = NumberFormat.currency(locale: 'es_EC', symbol: r'$');

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _estudiantes = const [];
  int _totalMensualidadesPendientes = 0;
  int _totalMensualidadesVencidas = 0;
  double _totalPendiente = 0;

  double _asDouble(dynamic v) =>
      (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarDashboard());
  }

  Future<void> _cargarDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = AppScope.of(context).representante;
      final estudiantes = await repo.misEstudiantes();

      int pendientes = 0;
      int vencidas = 0;
      double totalPend = 0;

      // Cargar mensualidades de cada estudiante para el resumen
      for (final e in estudiantes) {
        try {
          final idEst = (e['id_estudiante'] as num).toInt();
          final mens = await repo.mensualidadesPorEstudiante(idEst);

          for (final m in mens) {
            final estado = (m['estado'] ?? '').toString().toLowerCase();
            final pend = _asDouble(m['pendiente']);

            if (pend > 0) {
              totalPend += pend;
              if (estado == 'pendiente') {
                pendientes++;
              } else if (estado == 'vencido') {
                vencidas++;
              }
            }
          }
        } catch (_) {
          // Si falla cargar mensualidades de un estudiante, continuar
        }
      }

      setState(() {
        _estudiantes = estudiantes;
        _totalMensualidadesPendientes = pendientes;
        _totalMensualidadesVencidas = vencidas;
        _totalPendiente = totalPend;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Representante'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _cargarDashboard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _cargarDashboard,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarDashboard,
                  child: _buildDashboard(context),
                ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Bienvenida
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.school,
                          size: 32, color: Colors.blue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Bienvenido!',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gestiona las mensualidades de tus estudiantes',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Resumen general
        Text(
          'Resumen General',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Estudiantes',
                '${_estudiantes.length}',
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Pendientes',
                '$_totalMensualidadesPendientes',
                Icons.pending,
                Colors.orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Vencidas',
                '$_totalMensualidadesVencidas',
                Icons.warning,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total por pagar',
                _fmtMoney.format(_totalPendiente),
                Icons.attach_money,
                Colors.green,
                isLarge: true,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Accesos rápidos
        Text(
          'Accesos Rápidos',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        _buildActionCard(
          context,
          'Ver mis mensualidades',
          'Revisa el estado de todas las mensualidades',
          Icons.receipt_long,
          Colors.blue,
          () => Navigator.pushNamed(
            context,
            RouteNames.representanteMensualidades,
          ),
        ),

        const SizedBox(height: 12),

        _buildActionCard(
          context,
          'Mis estudiantes',
          'Ver información de ${_estudiantes.length} estudiante(s)',
          Icons.school_outlined,
          Colors.purple,
          _estudiantes.isEmpty
              ? null
              : () => _mostrarEstudiantes(context),
        ),

        const SizedBox(height: 24),

        // Alertas
        if (_totalMensualidadesVencidas > 0) ...[
          Card(
            color: Colors.red[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red[700], size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mensualidades vencidas',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tienes $_totalMensualidadesVencidas mensualidad(es) vencida(s). Revisa el detalle.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isLarge = false,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: isLarge ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: isLarge ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
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
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarEstudiantes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mis Estudiantes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _estudiantes.length,
                itemBuilder: (context, i) {
                  final e = _estudiantes[i];
                  final nombres = (e['nombres'] ?? '').toString();
                  final apellidos = (e['apellidos'] ?? '').toString();
                  final tipoRel =
                      (e['tipo_relacion'] ?? 'Representante').toString();
                  final activo = (e['activo'] ?? true) as bool;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            activo ? Colors.blue : Colors.grey,
                        child: Text(
                          apellidos.isNotEmpty
                              ? apellidos[0].toUpperCase()
                              : 'E',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        '$apellidos $nombres',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(tipoRel),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          RouteNames.representanteMensualidades,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
