import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/app_scope.dart';
import '../../../core/constants/route_names.dart';

class RepresentanteMensualidadesScreen extends StatefulWidget {
  const RepresentanteMensualidadesScreen({super.key});

  @override
  State<RepresentanteMensualidadesScreen> createState() =>
      _RepresentanteMensualidadesScreenState();
}

class _RepresentanteMensualidadesScreenState
    extends State<RepresentanteMensualidadesScreen> {
  final _fmtMoney = NumberFormat.currency(locale: 'es_EC', symbol: r'$');

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _estudiantes = const [];
  Map<int, List<Map<String, dynamic>>> _mensualidadesPorEstudiante = {};
  Map<int, bool> _loadingMens = {};
  Map<int, bool> _expandedEstudiantes = {};

  double _asDouble(dynamic v) =>
      (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarEstudiantes());
  }

  Future<void> _cargarEstudiantes() async {
    setState(() {
      _loading = true;
      _error = null;
      _estudiantes = const [];
      _mensualidadesPorEstudiante = {};
    });

    try {
      final repo = AppScope.of(context).representante;
      final estudiantes = await repo.misEstudiantes();
      setState(() {
        _estudiantes = estudiantes;
      });

      // Cargar automáticamente las mensualidades del primer estudiante si existe
      if (_estudiantes.isNotEmpty) {
        final primerEstudiante = _estudiantes.first;
        final idEstudiante = (primerEstudiante['id_estudiante'] as num).toInt();
        _expandedEstudiantes[idEstudiante] = true;
        await _cargarMensualidades(idEstudiante);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cargarMensualidades(int idEstudiante) async {
    setState(() {
      _loadingMens[idEstudiante] = true;
    });

    try {
      final repo = AppScope.of(context).representante;
      final mensualidades =
          await repo.mensualidadesPorEstudiante(idEstudiante);
      if (mounted) {
        setState(() {
          _mensualidadesPorEstudiante[idEstudiante] = mensualidades;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar mensualidades: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingMens[idEstudiante] = false;
        });
      }
    }
  }

  void _toggleEstudiante(int idEstudiante) {
    final isExpanded = _expandedEstudiantes[idEstudiante] ?? false;
    setState(() {
      _expandedEstudiantes[idEstudiante] = !isExpanded;
    });

    // Si se está expandiendo y no tiene mensualidades cargadas, cargarlas
    if (!isExpanded && !_mensualidadesPorEstudiante.containsKey(idEstudiante)) {
      _cargarMensualidades(idEstudiante);
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pagado':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'vencido':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'pagado':
        return Icons.check_circle_outline;
      case 'pendiente':
        return Icons.pending_outlined;
      case 'vencido':
        return Icons.error_outline;
      default:
        return Icons.help_outline;
    }
  }

  String _mesNombre(int? m) {
    const meses = [
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    if (m == null || m < 1 || m > 12) return '-';
    return meses[m];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis mensualidades'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _cargarEstudiantes,
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
                          onPressed: _cargarEstudiantes,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _estudiantes.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.school_outlined,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'No tienes estudiantes asignados',
                              style: TextStyle(fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Contacta con la administración para vincular estudiantes a tu cuenta',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarEstudiantes,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildResumenGeneral(),
                          const SizedBox(height: 16),
                          ..._estudiantes.map((e) => _buildEstudianteCard(e)),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildResumenGeneral() {
    double totalPendiente = 0;
    int countPendiente = 0;
    int countVencido = 0;

    for (final mensualidades in _mensualidadesPorEstudiante.values) {
      for (final m in mensualidades) {
        final pendiente = _asDouble(m['pendiente']);
        final estado = (m['estado'] ?? '').toString().toLowerCase();

        if (pendiente > 0) {
          totalPendiente += pendiente;
          if (estado == 'pendiente') {
            countPendiente++;
          } else if (estado == 'vencido') {
            countVencido++;
          }
        }
      }
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Resumen General',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildResumenItem(
                  'Total pendiente',
                  _fmtMoney.format(totalPendiente),
                  Colors.orange,
                  Icons.payments,
                ),
                _buildResumenItem(
                  'Pendientes',
                  '$countPendiente',
                  Colors.blue,
                  Icons.pending,
                ),
                _buildResumenItem(
                  'Vencidas',
                  '$countVencido',
                  Colors.red,
                  Icons.warning,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenItem(
      String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEstudianteCard(Map<String, dynamic> estudiante) {
    final idEstudiante = (estudiante['id_estudiante'] as num).toInt();
    final nombres = (estudiante['nombres'] ?? '').toString();
    final apellidos = (estudiante['apellidos'] ?? '').toString();
    final tipoRelacion = (estudiante['tipo_relacion'] ?? 'Representante').toString();
    final activo = (estudiante['activo'] ?? true) as bool;

    final isExpanded = _expandedEstudiantes[idEstudiante] ?? false;
    final isLoadingMens = _loadingMens[idEstudiante] ?? false;
    final mensualidades = _mensualidadesPorEstudiante[idEstudiante] ?? [];

    // Calcular totales para este estudiante
    double totalValor = 0;
    double totalPagado = 0;
    double totalPendiente = 0;
    int countPendiente = 0;
    int countVencido = 0;

    for (final m in mensualidades) {
      totalValor += _asDouble(m['valor']);
      totalPagado += _asDouble(m['pagado']);
      totalPendiente += _asDouble(m['pendiente']);

      final estado = (m['estado'] ?? '').toString().toLowerCase();
      if (estado == 'pendiente') countPendiente++;
      if (estado == 'vencido') countVencido++;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: activo ? Colors.blue : Colors.grey,
              child: Text(
                apellidos.isNotEmpty ? apellidos[0].toUpperCase() : 'E',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              '$apellidos $nombres',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tipoRelacion),
                if (mensualidades.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$countPendiente pendiente(s) · $countVencido vencida(s)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: Icon(isExpanded
                  ? Icons.expand_less
                  : Icons.expand_more),
              onPressed: () => _toggleEstudiante(idEstudiante),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            if (isLoadingMens)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (mensualidades.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No hay mensualidades registradas'),
                ),
              )
            else ...[
              // Resumen del estudiante
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStat('Total', _fmtMoney.format(totalValor)),
                    _buildMiniStat('Pagado', _fmtMoney.format(totalPagado)),
                    _buildMiniStat(
                      'Pendiente',
                      _fmtMoney.format(totalPendiente),
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Lista de mensualidades
              ...mensualidades.map((m) =>
                  _buildMensualidadTile(m, idEstudiante)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildMensualidadTile(
      Map<String, dynamic> mensualidad, int idEstudiante) {
    final idMensualidad = (mensualidad['id_mensualidad'] as num).toInt();
    final mes = (mensualidad['mes'] as num?)?.toInt();
    final anio = (mensualidad['anio'] as num?)?.toInt();
    final estado = (mensualidad['estado'] ?? 'pendiente').toString();
    final valor = _asDouble(mensualidad['valor']);
    final pagado = _asDouble(mensualidad['pagado']);
    final pendiente = _asDouble(mensualidad['pendiente']);

    final estadoColor = _getEstadoColor(estado);
    final estadoIcon = _getEstadoIcon(estado);

    return ListTile(
      leading: Icon(estadoIcon, color: estadoColor),
      title: Text('${_mesNombre(mes)} $anio'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Valor: ${_fmtMoney.format(valor)}'),
          if (pagado > 0) Text('Pagado: ${_fmtMoney.format(pagado)}'),
          if (pendiente > 0)
            Text(
              'Pendiente: ${_fmtMoney.format(pendiente)}',
              style: const TextStyle(color: Colors.orange),
            ),
        ],
      ),
      trailing: Chip(
        label: Text(
          estado.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        backgroundColor: estadoColor.withOpacity(0.2),
        labelStyle: TextStyle(color: estadoColor),
        padding: EdgeInsets.zero,
      ),
      onTap: () {
        Navigator.pushNamed(
          context,
          RouteNames.representanteMensualidadDetalle,
          arguments: {'idMensualidad': idMensualidad},
        );
      },
    );
  }
}
