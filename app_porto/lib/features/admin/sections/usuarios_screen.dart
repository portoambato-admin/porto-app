import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_scope.dart';
import '../data/usuarios_repository.dart';
import '../models/usuario_model.dart';

// --- Clase auxiliar para el estado de paginación por tab ---
class _TabState {
  List<Usuario> items = [];
  int total = 0;
  int page = 1;
  int pageSize = 10;
  String sort = 'creado_en';
  bool asc = false;
}

// Enum para cambiar vista manualmente
enum _ViewMode { table, cards }

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen>
    with SingleTickerProviderStateMixin {
  late UsuariosRepository _repo;
  late final TabController _tab;

  // Estado UI Global
  bool _loading = false;
  String? _error;
  Timer? _debounce;
  final TextEditingController _searchCtrl = TextEditingController();

  // Preferencia de vista (Tabla o Tarjetas)
  _ViewMode _viewMode = _ViewMode.cards;

  final List<_TabState> _tabsData = [
    _TabState(), // Activos
    _TabState(), // Inactivos
    _TabState(), // Todos
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (!_tab.indexIsChanging) {
          if (_tabsData[_tab.index].items.isEmpty) {
            _loadData();
          } else {
            setState(() {});
          }
        }
      });

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo = AppScope.of(context).usuarios;
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ========================= TOOLTIP HELPER =========================
  Widget _tt(String message, Widget child) {
    return Tooltip(
      message: message,
      waitDuration: const Duration(milliseconds: 350),
      showDuration: const Duration(seconds: 3),
      preferBelow: false,
      child: child,
    );
  }

  // --- Lógica de Carga ---
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final index = _tab.index;
      final state = _tabsData[index];

      final q =
          _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim();
      PagedResult<Usuario> res;

      if (index == 0) {
        res = await _repo.pagedActivos(
          page: state.page,
          pageSize: state.pageSize,
          q: q,
          sort: state.sort,
          order: state.asc ? 'asc' : 'desc',
        );
      } else if (index == 1) {
        res = await _repo.pagedInactivos(
          page: state.page,
          pageSize: state.pageSize,
          q: q,
          sort: state.sort,
          order: state.asc ? 'asc' : 'desc',
        );
      } else {
        res = await _repo.pagedTodos(
          page: state.page,
          pageSize: state.pageSize,
          q: q,
          sort: state.sort,
          order: state.asc ? 'asc' : 'desc',
        );
      }

      setState(() {
        state.items = res.items;
        state.total = res.total;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _tabsData[_tab.index].page = 1;
      _loadData();
    });
  }

  // --- Optimistic UI Toggle ---
  Future<void> _toggleUserStatus(Usuario u) async {
    final isInactiveTab = _tab.index == 1; // ¿Estoy en inactivos?
    final isActivateAction = isInactiveTab; // Si sí, la acción es activar.

    // 1. Guardar estado anterior por si hay error (Rollback)
    final originalList = List<Usuario>.from(_tabsData[_tab.index].items);

    // 2. Optimistic UI: Lo sacamos visualmente de la lista actual
    setState(() {
      _tabsData[_tab.index].items.removeWhere((element) => element.id == u.id);
      _tabsData[_tab.index].total -= 1;
    });

    // Feedback visual inmediato
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isActivateAction ? 'Usuario activado' : 'Usuario desactivado'),
      duration: const Duration(milliseconds: 1500),
      behavior: SnackBarBehavior.floating,
      width: 280,
    ));

    try {
      // 3. Llamada a la API
      if (isActivateAction) {
        await _repo.activate(u.id);

        // Al activar, el usuario se va a la tab 0 (Activos).
        // Borramos la lista de la tab 0 y 2 para forzar recarga al entrar.
        _tabsData[0].items.clear(); // 0 = Activos
        _tabsData[2].items.clear(); // 2 = Todos
      } else {
        await _repo.remove(u.id);

        // Al desactivar, el usuario se va a la tab 1 (Inactivos).
        // Borramos la lista de la tab 1 y 2 para forzar recarga.
        _tabsData[1].items.clear(); // 1 = Inactivos
        _tabsData[2].items.clear(); // 2 = Todos
      }

      // No recargamos la pestaña actual (_loadData) porque ya quitamos el item visualmente arriba.
    } catch (e) {
      // 4. Rollback: Si falla, devolvemos el usuario a la lista
      if (!mounted) return;
      setState(() {
        _tabsData[_tab.index].items = originalList;
        _tabsData[_tab.index].total += 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // ========================= ESTILOS Y DIÁLOGOS MODERNOS =========================

  InputDecoration _modernInputDeco(String label, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.8)),
      prefixIcon: Icon(icon, color: cs.primary.withOpacity(0.7), size: 22),
      filled: true,
      fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.transparent)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.error.withOpacity(0.5))),
    );
  }

  Future<void> _openCreateUserDialog() async {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final correoCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    int idRol = UserRole.usuario.id;
    bool obscurePass = true;
    bool isSaving = false;
    final cs = Theme.of(context).colorScheme;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(builder: (innerCtx, setInnerState) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: cs.surface,
          elevation: 8,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [cs.primary.withOpacity(0.8), cs.primaryContainer],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          tooltip: 'Cerrar',
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(innerCtx),
                        ),
                      ),
                      Positioned(
                        bottom: -40,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 38,
                            backgroundColor: cs.primaryContainer,
                            child: Icon(Icons.person_add_rounded, size: 36, color: cs.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Crear Nuevo Usuario',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: nombreCtrl,
                            decoration: _modernInputDeco(
                                'Nombre completo', Icons.person_outline),
                            validator: (v) => (v?.trim().length ?? 0) < 3
                                ? 'Mínimo 3 caracteres'
                                : null,
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: correoCtrl,
                            decoration: _modernInputDeco(
                                'Correo electrónico', Icons.alternate_email),
                            validator: (v) => !v!.contains('@') ? 'Correo inválido' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: passCtrl,
                            obscureText: obscurePass,
                            decoration:
                                _modernInputDeco('Contraseña', Icons.lock_outline).copyWith(
                              suffixIcon: IconButton(
                                tooltip: obscurePass
                                    ? 'Mostrar contraseña'
                                    : 'Ocultar contraseña',
                                icon: Icon(
                                  obscurePass ? Icons.visibility_off : Icons.visibility,
                                  color: cs.primary,
                                ),
                                onPressed: () => setInnerState(() {
                                  obscurePass = !obscurePass;
                                }),
                              ),
                            ),
                            validator: (v) =>
                                (v?.length ?? 0) < 6 ? 'Mínimo 6 caracteres' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            value: idRol,
                            decoration: _modernInputDeco('Rol', Icons.badge_outlined),
                            items: UserRole.values
                                .map((r) => DropdownMenuItem(
                                      value: r.id,
                                      child: Text(r.label),
                                    ))
                                .toList(),
                            onChanged: (v) => setInnerState(() => idRol = v!),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) return;
                                      setInnerState(() => isSaving = true);
                                      try {
                                        await _repo.create(
                                          nombre: nombreCtrl.text.trim(),
                                          correo: correoCtrl.text.trim(),
                                          password: passCtrl.text,
                                          idRol: idRol,
                                        );
                                        if (mounted) {
                                          Navigator.pop(innerCtx);
                                          _loadData();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Usuario creado'),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        setInnerState(() => isSaving = false);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(e.toString()),
                                            backgroundColor: cs.error,
                                          ),
                                        );
                                      }
                                    },
                              child: isSaving
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: cs.onPrimary,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Registrar Usuario',
                                      style: TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _openEditUserDialog(Usuario u) async {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(text: u.nombre);
    final correoCtrl = TextEditingController(text: u.correo);
    int idRol = u.rol.id;
    bool isSaving = false;
    final cs = Theme.of(context).colorScheme;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(builder: (innerCtx, setInnerState) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: cs.surface,
          elevation: 8,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Spacer(),
                        IconButton(
                          tooltip: 'Cerrar',
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(innerCtx),
                        ),
                      ],
                    ),
                  ),
                  Hero(
                    tag: 'user_avatar_${u.id}',
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.primary.withOpacity(0.5), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: cs.primaryContainer,
                        backgroundImage: u.avatarUrl != null ? NetworkImage(u.avatarUrl!) : null,
                        child: u.avatarUrl == null
                            ? Icon(Icons.person, size: 40, color: cs.primary)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Editar Perfil',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface)),
                  Text('Actualiza la información del usuario',
                      style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: nombreCtrl,
                            decoration:
                                _modernInputDeco('Nombre completo', Icons.person_outline),
                            validator: (v) => (v?.trim().length ?? 0) < 3
                                ? 'Mínimo 3 caracteres'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: correoCtrl,
                            decoration: _modernInputDeco(
                                'Correo electrónico', Icons.alternate_email),
                            validator: (v) => !v!.contains('@') ? 'Correo inválido' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            value: idRol,
                            decoration:
                                _modernInputDeco('Rol asignado', Icons.badge_outlined),
                            items: UserRole.values
                                .map((r) => DropdownMenuItem(
                                      value: r.id,
                                      child: Text(r.label),
                                    ))
                                .toList(),
                            onChanged: (v) => setInnerState(() => idRol = v!),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius:
                          const BorderRadius.vertical(bottom: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(innerCtx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              side: BorderSide(color: cs.outlineVariant),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setInnerState(() => isSaving = true);
                                    try {
                                      await _repo.update(
                                        idUsuario: u.id,
                                        nombre: nombreCtrl.text.trim(),
                                        correo: correoCtrl.text.trim(),
                                        idRol: idRol,
                                      );
                                      if (mounted) {
                                        Navigator.pop(innerCtx);
                                        _loadData();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Guardado'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setInnerState(() => isSaving = false);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(e.toString()),
                                          backgroundColor: cs.error,
                                        ),
                                      );
                                    }
                                  },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: isSaving
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: cs.onPrimary,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Guardar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ========================= UI PRINCIPAL =========================

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentState = _tabsData[_tab.index];
    final isMobile = MediaQuery.of(context).size.width < 700;

    final content = currentState.items.isEmpty && !_loading
        ? _buildEmptyState()
        : (_viewMode == _ViewMode.cards || isMobile
            ? _buildCardsView(currentState.items)
            : _buildTableView(currentState.items));

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Gestión de Usuarios',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        bottom: TabBar(
          controller: _tab,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              text: 'Activos',
              icon: _tt('Usuarios activos',
                  const Icon(Icons.check_circle_outline, size: 20)),
            ),
            Tab(
              text: 'Inactivos',
              icon: _tt('Usuarios desactivados',
                  const Icon(Icons.block_outlined, size: 20)),
            ),
            Tab(
              text: 'Todos',
              icon: _tt(
                  'Todos los usuarios', const Icon(Icons.list_alt_rounded, size: 20)),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Crear nuevo usuario',
        onPressed: _openCreateUserDialog,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Nuevo'),
        elevation: 4,
      ),
      body: Column(
        children: [
          _buildModernHeader(context),
          if (_error != null)
            Container(
              color: cs.errorContainer,
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              child: Text(
                _error!,
                style: TextStyle(color: cs.onErrorContainer),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: content),
                if (_loading)
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.inverseSurface.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onInverseSurface,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('Cargando...',
                                style: TextStyle(color: cs.onInverseSurface, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildPaginator(currentState),
        ],
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.3))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar usuario...',
                prefixIcon: Icon(Icons.search, color: cs.primary),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: cs.primary, width: 1)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        tooltip: 'Limpiar búsqueda',
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Vista en tarjetas',
                  icon: Icon(
                    Icons.grid_view_rounded,
                    color: _viewMode == _ViewMode.cards ? cs.primary : cs.onSurfaceVariant,
                  ),
                  onPressed: () => setState(() => _viewMode = _ViewMode.cards),
                ),
                Container(width: 1, height: 20, color: cs.outlineVariant),
                IconButton(
                  tooltip: 'Vista en tabla',
                  icon: Icon(
                    Icons.table_rows_rounded,
                    color: _viewMode == _ViewMode.table ? cs.primary : cs.onSurfaceVariant,
                  ),
                  onPressed: () => setState(() => _viewMode = _ViewMode.table),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginator(_TabState state) {
    final total = state.total;
    final from = (total == 0) ? 0 : ((state.page - 1) * state.pageSize + 1);
    final to = ((state.page * state.pageSize) > total) ? total : (state.page * state.pageSize);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$from-$to de $total usuarios',
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Página anterior',
                icon: const Icon(Icons.chevron_left),
                onPressed: state.page > 1
                    ? () {
                        setState(() => state.page--);
                        _loadData();
                      }
                    : null,
              ),
              IconButton(
                tooltip: 'Página siguiente',
                icon: const Icon(Icons.chevron_right),
                onPressed: to < total
                    ? () {
                        setState(() => state.page++);
                        _loadData();
                      }
                    : null,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_outlined,
              size: 80, color: Theme.of(context).disabledColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No se encontraron usuarios',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // --- TABLA (CON CÉDULA RESTAURADA) ---
  Widget _buildTableView(List<Usuario> users) {
    final cs = Theme.of(context).colorScheme;
    final state = _tabsData[_tab.index];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor:
                MaterialStateProperty.all(cs.surfaceContainerHighest.withOpacity(0.5)),
            dataRowMaxHeight: 52,
            columns: [
              _col('Cédula', 'cedula', state),
              _col('Nombre', 'nombre', state),
              _col('Correo', 'correo', state),
              const DataColumn(label: Text('Rol')),
              _col('Registro', 'creado_en', state),
              const DataColumn(label: Text('Acciones')),
            ],
            rows: users.asMap().entries.map((entry) {
              final i = entry.key;
              final u = entry.value;
              final isEven = i % 2 == 0;
              return DataRow(
                color: MaterialStateProperty.all(
                    isEven ? Colors.transparent : cs.surfaceContainerHighest.withOpacity(0.2)),
                cells: [
                  DataCell(Text(u.cedula ?? '—',
                      style: const TextStyle(
                          fontFamily: 'monospace', fontWeight: FontWeight.w600))),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: u.avatarUrl != null ? NetworkImage(u.avatarUrl!) : null,
                        child: u.avatarUrl == null ? const Icon(Icons.person, size: 16) : null,
                      ),
                      const SizedBox(width: 12),
                      Text(u.nombre, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  )),
                  DataCell(Text(u.correo)),
                  DataCell(_RolePill(rol: u.rol)),
                  DataCell(Text(u.creadoEn.toString().split(' ')[0],
                      style: const TextStyle(fontFamily: 'monospace'))),
                  DataCell(Row(
                    children: [
                      IconButton(
                        tooltip: 'Editar usuario',
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _openEditUserDialog(u),
                      ),
                      IconButton(
                        tooltip: _tab.index == 1 ? 'Activar usuario' : 'Desactivar usuario',
                        icon: Icon(
                            _tab.index == 1
                                ? Icons.check_circle_outline
                                : Icons.block_outlined,
                            size: 20),
                        color: _tab.index == 1 ? Colors.green : Colors.red,
                        onPressed: () => _toggleUserStatus(u),
                      ),
                    ],
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  DataColumn _col(String label, String key, _TabState state) {
    return DataColumn(
      label: _tt(
        'Ordenar por $label',
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      onSort: (_, __) {
        setState(() {
          if (state.sort == key) {
            state.asc = !state.asc;
          } else {
            state.sort = key;
            state.asc = true;
          }
          state.page = 1;
        });
        _loadData();
      },
    );
  }

  // --- TARJETAS (CON CÉDULA RESTAURADA) ---
  Widget _buildCardsView(List<Usuario> users) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: users.length,
      itemBuilder: (context, i) {
        final u = users[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: _tt(
            'Clic para editar',
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openEditUserDialog(u),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Hero(
                      tag: 'user_avatar_${u.id}',
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: u.avatarUrl != null ? NetworkImage(u.avatarUrl!) : null,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: u.avatarUrl == null
                            ? Icon(Icons.person,
                                color: Theme.of(context).colorScheme.onPrimaryContainer)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  u.nombre,
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _RolePill(rol: u.rol, compact: true),
                            ],
                          ),
                          if (u.cedula != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 2),
                              child: Row(
                                children: [
                                  Icon(Icons.badge_outlined,
                                      size: 14, color: Theme.of(context).hintColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    u.cedula!,
                                    style: TextStyle(
                                      color: Theme.of(context).hintColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(u.correo,
                              style: TextStyle(
                                  color: Theme.of(context).hintColor, fontSize: 13)),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          tooltip: 'Editar usuario',
                          icon: const Icon(Icons.edit_outlined),
                          iconSize: 20,
                          color: Theme.of(context).colorScheme.secondary,
                          onPressed: () => _openEditUserDialog(u),
                        ),
                        IconButton(
                          tooltip: _tab.index == 1 ? 'Activar usuario' : 'Desactivar usuario',
                          icon: Icon(
                              _tab.index == 1
                                  ? Icons.check_circle
                                  : Icons.remove_circle_outline),
                          iconSize: 20,
                          color: _tab.index == 1
                              ? Colors.green
                              : Colors.red.withOpacity(0.7),
                          onPressed: () => _toggleUserStatus(u),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- Componente: Pill de Rol ---
class _RolePill extends StatelessWidget {
  final UserRole rol;
  final bool compact;
  const _RolePill({required this.rol, this.compact = false});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (rol) {
      case UserRole.admin:
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade700;
        break;
      case UserRole.profesor:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        break;
      case UserRole.padre:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
    }

    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: compact ? 6 : 10, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      child: Text(
        rol.label.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}