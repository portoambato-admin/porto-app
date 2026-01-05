import 'dart:async';

import 'package:flutter/material.dart';
import '../../../app/app_scope.dart';

class AdminEstudianteRepresentantesScreen extends StatefulWidget {
  final int idEstudiante;
  final String nombreEstudiante;

  const AdminEstudianteRepresentantesScreen({
    super.key,
    required this.idEstudiante,
    required this.nombreEstudiante,
  });

  @override
  State<AdminEstudianteRepresentantesScreen> createState() =>
      _AdminEstudianteRepresentantesScreenState();
}

class _AdminEstudianteRepresentantesScreenState
    extends State<AdminEstudianteRepresentantesScreen> {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _vinculos = [];
  List<Map<String, dynamic>> _tiposRelacion = [];
  bool _incluirInactivos = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarDatos());
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = AppScope.of(context).representantesEstudiante;

      final vinculos = await repo.listarVinculos(
        widget.idEstudiante,
        incluirInactivos: _incluirInactivos,
      );

      final tipos = await repo.tiposRelacion();

      setState(() {
        _vinculos = vinculos;
        _tiposRelacion = tipos;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _mostrarDialogoVincular() async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DialogoVincularRepresentante(
        idEstudiante: widget.idEstudiante,
        nombreEstudiante: widget.nombreEstudiante,
        tiposRelacion: _tiposRelacion,
      ),
    );

    if (resultado == true) {
      _cargarDatos();
    }
  }

  Future<void> _cambiarEstadoVinculo(
    Map<String, dynamic> vinculo,
    bool activar,
  ) async {
    final idUsuario = (vinculo['id_usuario'] as num).toInt();
    final nombre = (vinculo['nombre'] ?? '').toString();

    final confirma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activar ? 'Activar vínculo' : 'Desactivar vínculo'),
        content: Text(
          activar
              ? '¿Deseas reactivar el vínculo con $nombre?'
              : '¿Deseas desactivar el vínculo con $nombre?\n\nPodrás reactivarlo más tarde.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: activar ? Colors.green : Colors.orange,
            ),
            child: Text(activar ? 'Activar' : 'Desactivar'),
          ),
        ],
      ),
    );

    if (confirma != true) return;

    try {
      final repo = AppScope.of(context).representantesEstudiante;

      if (activar) {
        await repo.activar(
          idUsuarioRepresentante: idUsuario,
          idEstudiante: widget.idEstudiante,
        );
      } else {
        await repo.desactivar(
          idUsuarioRepresentante: idUsuario,
          idEstudiante: widget.idEstudiante,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              activar
                  ? 'Vínculo activado correctamente'
                  : 'Vínculo desactivado correctamente',
            ),
            backgroundColor: activar ? Colors.green : Colors.orange,
          ),
        );
        _cargarDatos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Representantes'),
            Text(
              widget.nombreEstudiante,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          Tooltip(
            message: 'Actualizar',
            child: IconButton(
              icon: const Icon(Icons.refresh, semanticLabel: 'Actualizar'),
              onPressed: _loading ? null : _cargarDatos,
            ),
          ),
          PopupMenuButton(
            tooltip: 'Opciones',
            icon: const Icon(Icons.more_vert, semanticLabel: 'Opciones'),
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: 'inactivos',
                checked: _incluirInactivos,
                child: const Text('Mostrar inactivos'),
              ),
            ],
            onSelected: (value) {
              if (value == 'inactivos') {
                setState(() => _incluirInactivos = !_incluirInactivos);
                _cargarDatos();
              }
            },
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
                        const Icon(Icons.error_outline, size: 64, color: Colors.red, semanticLabel: 'Error'),
                        const SizedBox(height: 16),
                        SelectableText(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _cargarDatos,
                          icon: const Icon(Icons.refresh, semanticLabel: 'Reintentar'),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarDatos,
                  child: _vinculos.isEmpty ? _buildEmptyState() : _buildListaVinculos(),
                ),
      floatingActionButton: Tooltip(
        message: 'Vincular representante',
        child: FloatingActionButton.extended(
          onPressed: _mostrarDialogoVincular,
          icon: const Icon(Icons.person_add, semanticLabel: 'Vincular'),
          label: const Text('Vincular'),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const Icon(Icons.people_outline, size: 80, color: Colors.grey, semanticLabel: 'Sin representantes'),
        const SizedBox(height: 24),
        const Text(
          'No hay representantes vinculados',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _incluirInactivos
              ? 'No hay representantes activos ni inactivos'
              : 'Presiona el botón "Vincular" para agregar un representante',
          style: TextStyle(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildListaVinculos() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vinculos.length,
      itemBuilder: (context, i) {
        final v = _vinculos[i];
        final nombre = (v['nombre'] ?? '').toString();
        final correo = (v['correo'] ?? '').toString();
        final cedula = (v['cedula'] ?? '').toString();
        final tipoRelacion = (v['tipo_relacion'] ?? 'Sin especificar').toString();
        final activo = (v['activo'] ?? true) as bool;
        final origen = (v['origen'] ?? 'admin').toString();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: activo ? 2 : 1,
          color: activo ? null : Colors.grey[100],
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: activo ? Colors.blue : Colors.grey,
              child: Text(
                nombre.isNotEmpty ? nombre[0].toUpperCase() : 'R',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: activo ? null : TextDecoration.lineThrough,
                    ),
                  ),
                ),
                if (!activo)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'INACTIVO',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                if (correo.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 14, semanticLabel: 'Correo'),
                      const SizedBox(width: 6),
                      Expanded(child: Text(correo, style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                if (cedula.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 14, semanticLabel: 'Cédula'),
                      const SizedBox(width: 6),
                      Text('Cédula: $cedula', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.family_restroom, size: 14, semanticLabel: 'Relación'),
                    const SizedBox(width: 6),
                    Text(tipoRelacion, style: const TextStyle(fontSize: 13)),
                  ],
                ),
                if (origen != 'admin') ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, semanticLabel: 'Origen'),
                      const SizedBox(width: 6),
                      Text(
                        'Vinculado por: $origen',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: PopupMenuButton(
              tooltip: 'Acciones',
              icon: const Icon(Icons.more_vert, semanticLabel: 'Acciones'),
              itemBuilder: (context) => [
                if (activo)
                  const PopupMenuItem(
                    value: 'desactivar',
                    child: Row(
                      children: [
                        Icon(Icons.cancel_outlined, color: Colors.orange, semanticLabel: 'Desactivar'),
                        SizedBox(width: 8),
                        Text('Desactivar'),
                      ],
                    ),
                  )
                else
                  const PopupMenuItem(
                    value: 'activar',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green, semanticLabel: 'Activar'),
                        SizedBox(width: 8),
                        Text('Activar'),
                      ],
                    ),
                  ),
              ],
              onSelected: (value) {
                if (value == 'desactivar') {
                  _cambiarEstadoVinculo(v, false);
                } else if (value == 'activar') {
                  _cambiarEstadoVinculo(v, true);
                }
              },
            ),
          ),
        );
      },
    );
  }
}

// ===== DIÁLOGO MEJORADO PARA VINCULAR =====
class _DialogoVincularRepresentante extends StatefulWidget {
  final int idEstudiante;
  final String nombreEstudiante;
  final List<Map<String, dynamic>> tiposRelacion;

  const _DialogoVincularRepresentante({
    required this.idEstudiante,
    required this.nombreEstudiante,
    required this.tiposRelacion,
  });

  @override
  State<_DialogoVincularRepresentante> createState() =>
      _DialogoVincularRepresentanteState();
}

class _DialogoVincularRepresentanteState extends State<_DialogoVincularRepresentante> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  bool _searching = false;
  bool _saving = false;
  List<Map<String, dynamic>> _resultados = [];
  Map<String, dynamic>? _seleccionado;
  int? _tipoRelacionSeleccionado;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    setState(() {}); // para refrescar suffixIcon (limpiar)
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _buscar();
    });
  }

  Future<void> _buscar() async {
    final query = _searchController.text.trim();
    if (query.length < 2) {
      setState(() {
        _resultados = [];
        _seleccionado = null;
      });
      return;
    }

    setState(() {
      _searching = true;
      _seleccionado = null;
    });

    try {
      final repo = AppScope.of(context).representantesEstudiante;
      final resultados = await repo.buscarRepresentantes(query);
      setState(() {
        _resultados = resultados;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al buscar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _guardar() async {
    if (_seleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un representante'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_tipoRelacionSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona el tipo de relación'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = AppScope.of(context).representantesEstudiante;
      await repo.vincular(
        idEstudiante: widget.idEstudiante,
        idUsuarioRepresentante: (_seleccionado!['id_usuario'] as num).toInt(),
        idRelacion: _tipoRelacionSeleccionado!,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Representante vinculado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _seleccionado != null && _tipoRelacionSeleccionado != null;

    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_add, size: 28, semanticLabel: 'Vincular representante'),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Vincular representante',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Tooltip(
                        message: 'Cerrar',
                        child: IconButton(
                          icon: const Icon(Icons.close, semanticLabel: 'Cerrar'),
                          onPressed: () => Navigator.pop(context, false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estudiante: ${widget.nombreEstudiante}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Buscador
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Buscar representante',
                        hintText: 'Nombre, correo o cédula',
                        prefixIcon: const Icon(Icons.search, semanticLabel: 'Buscar'),
                        suffixIcon: _searching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : _searchController.text.isNotEmpty
                                ? Tooltip(
                                    message: 'Limpiar búsqueda',
                                    child: IconButton(
                                      icon: const Icon(Icons.clear, semanticLabel: 'Limpiar búsqueda'),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _resultados = [];
                                          _seleccionado = null;
                                        });
                                      },
                                    ),
                                  )
                                : null,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => _onSearchChanged(),
                    ),

                    const SizedBox(height: 16),

                    // Resultados
                    if (_searchController.text.length >= 2) ...[
                      const Text(
                        'Resultados',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _resultados.isEmpty && !_searching
                            ? const Center(
                                child: Text('No se encontraron representantes'),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _resultados.length,
                                itemBuilder: (context, i) {
                                  final r = _resultados[i];
                                  final isSelected = _seleccionado != null &&
                                      _seleccionado!['id_usuario'] == r['id_usuario'];

                                  return Card(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                                        : null,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        child: Text(
                                          (r['nombre'] ?? 'R').toString()[0].toUpperCase(),
                                        ),
                                      ),
                                      title: Text((r['nombre'] ?? '').toString()),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if ((r['correo'] ?? '').toString().isNotEmpty)
                                            Text((r['correo'] ?? '').toString()),
                                          if ((r['cedula'] ?? '').toString().isNotEmpty)
                                            Text('CI: ${r['cedula']}'),
                                        ],
                                      ),
                                      trailing: isSelected
                                          ? const Icon(Icons.check_circle, color: Colors.green, semanticLabel: 'Seleccionado')
                                          : null,
                                      selected: isSelected,
                                      onTap: () {
                                        setState(() {
                                          _seleccionado = isSelected ? null : r;
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ] else
                      const Expanded(
                        child: Center(
                          child: Text('Escribe para buscar representantes'),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Tipo de relación
                    if (_seleccionado != null) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _tipoRelacionSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de relación *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.family_restroom, semanticLabel: 'Tipo de relación'),
                        ),
                        items: widget.tiposRelacion.map((t) {
                          return DropdownMenuItem(
                            value: (t['id_relacion'] as num).toInt(),
                            child: Text((t['nombre'] ?? '').toString()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _tipoRelacionSeleccionado = value);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message: 'Cancelar',
                    child: TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Tooltip(
                    message: 'Guardar vínculo',
                    child: FilledButton.icon(
                      onPressed: _saving || !canSave ? null : _guardar,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check, semanticLabel: 'Guardar'),
                      label: Text(_saving ? 'Guardando...' : 'Guardar vínculo'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
