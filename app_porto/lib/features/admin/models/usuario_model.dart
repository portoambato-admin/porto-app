// lib/features/admin/models/usuario_model.dart
import 'package:flutter/foundation.dart';

// =========================================================
// ENUM ROLES (Tipado Fuerte + Extensiones)
// =========================================================
enum UserRole {
  admin(1, 'Admin', 'Administrador del sistema'),
  profesor(2, 'Profesor', 'Instructor de la academia'),
  padre(3, 'Representante', 'Padre/Tutor de estudiante'),
  usuario(4, 'Usuario', 'Usuario general');

  final int id;
  final String label;
  final String description;
  
  const UserRole(this.id, this.label, this.description);

  /// Factory seguro: si el ID no coincide, devuelve 'usuario' por defecto
  static UserRole fromId(dynamic id) {
    final intId = (id as num?)?.toInt();
    return UserRole.values.firstWhere(
      (e) => e.id == intId,
      orElse: () => UserRole.usuario,
    );
  }

  /// Obtener rol por nombre (case-insensitive)
  static UserRole fromName(String? name) {
    if (name == null) return UserRole.usuario;
    return UserRole.values.firstWhere(
      (e) => e.name.toLowerCase() == name.toLowerCase(),
      orElse: () => UserRole.usuario,
    );
  }

  /// Verificar si tiene permisos de administrador
  bool get isAdmin => this == UserRole.admin;

  /// Verificar si puede gestionar estudiantes
  bool get canManageStudents => this == UserRole.admin || this == UserRole.profesor;

  /// Color asociado (para badges)
  String get colorHex {
    switch (this) {
      case UserRole.admin:
        return '#9C27B0'; // Purple
      case UserRole.profesor:
        return '#FF9800'; // Orange
      case UserRole.padre:
        return '#2196F3'; // Blue
      default:
        return '#9E9E9E'; // Grey
    }
  }
}

// =========================================================
// MODELO USUARIO (Inmutable + Lógica de Negocio)
// =========================================================
@immutable
class Usuario {
  final int id;
  final String nombre;
  final String correo;
  final UserRole rol;
  final String? avatarUrl;
  final String? cedula;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;
  final bool activo;
  final bool verificado;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.avatarUrl,
    this.cedula,
    this.creadoEn,
    this.actualizadoEn,
    this.activo = true,
    this.verificado = false,
  });

  // ============================================================
  // FACTORY DESDE JSON (Manejo robusto)
  // ============================================================
  factory Usuario.fromJson(Map<String, dynamic> json) {
    try {
      return Usuario(
        id: _parseId(json['id_usuario']),
        nombre: _parseString(json['nombre'], defaultValue: 'Sin nombre') ?? 'Sin nombre',
      correo: _parseString(json['correo'], defaultValue: 'sin@correo.com') ?? 'sin@correo.com',
        rol: UserRole.fromId(json['id_rol']),
        avatarUrl: _parseString(json['avatar_url'] ?? json['avatar']),
        cedula: _parseString(json['cedula'] ?? json['dni'] ?? json['numero_cedula']),
        creadoEn: _parseDateTime(json['creado_en']),
        actualizadoEn: _parseDateTime(json['actualizado_en']),
        activo: json['activo'] == true || json['activo'] == 1,
        verificado: json['verificado'] == true || json['verificado'] == 1,
      );
    } catch (e) {
      
      rethrow;
    }
  }

  // ============================================================
  // TO JSON (Para persistencia y API)
  // ============================================================
  Map<String, dynamic> toJson() {
    return {
      'id_usuario': id,
      'nombre': nombre,
      'correo': correo,
      'id_rol': rol.id,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (cedula != null) 'cedula': cedula,
      if (creadoEn != null) 'creado_en': creadoEn!.toIso8601String(),
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn!.toIso8601String(),
      'activo': activo,
      'verificado': verificado,
    };
  }

  // ============================================================
  // COPYWITH (Inmutabilidad)
  // ============================================================
  Usuario copyWith({
    String? nombre,
    String? correo,
    UserRole? rol,
    String? avatarUrl,
    String? cedula,
    bool? activo,
    bool? verificado,
    DateTime? actualizadoEn,
  }) {
    return Usuario(
      id: id,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      rol: rol ?? this.rol,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      cedula: cedula ?? this.cedula,
      creadoEn: creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      activo: activo ?? this.activo,
      verificado: verificado ?? this.verificado,
    );
  }

  // ============================================================
  // MÉTODOS DE NEGOCIO
  // ============================================================

  /// Obtener iniciales (para avatares)
  String get initials {
    final parts = nombre.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Verificar si el usuario puede ser editado
  bool canBeEditedBy(Usuario currentUser) {
    // Admin puede editar a todos
    if (currentUser.rol.isAdmin) return true;
    
    // Usuarios no pueden editar a otros
    if (!currentUser.rol.isAdmin) return false;
    
    return false;
  }

  /// Verificar si el usuario puede ser eliminado
  bool canBeDeletedBy(Usuario currentUser) {
    // No se puede eliminar a sí mismo
    if (id == currentUser.id) return false;
    
    // Solo admin puede eliminar
    if (!currentUser.rol.isAdmin) return false;
    
    // No se puede eliminar a otros admins (política de seguridad)
    if (rol.isAdmin) return false;
    
    return true;
  }

  /// Formato legible de fecha de creación
  String get fechaCreacionFormatted {
    if (creadoEn == null) return 'Desconocida';
    final now = DateTime.now();
    final diff = now.difference(creadoEn!);
    
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    if (diff.inDays < 30) return 'Hace ${(diff.inDays / 7).floor()} semanas';
    if (diff.inDays < 365) return 'Hace ${(diff.inDays / 30).floor()} meses';
    return 'Hace ${(diff.inDays / 365).floor()} años';
  }

  // ============================================================
  // HELPERS PRIVADOS DE PARSING
  // ============================================================

  static int _parseId(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String? _parseString(dynamic value, {String? defaultValue}) {
    if (value == null) return defaultValue;
    final str = value.toString().trim();
    if (str.isEmpty) return defaultValue;
    return str;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // ============================================================
  // EQUALITY & HASHCODE (Para comparaciones y caching)
  // ============================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Usuario && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Usuario(id: $id, nombre: $nombre, rol: ${rol.label})';
  }
}

// =========================================================
// PAGINACIÓN GENÉRICA (Optimizada)
// =========================================================
@immutable
class PagedResult<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;

  const PagedResult({
    required this.items,
    required this.total,
    this.page = 1,
    this.pageSize = 10,
  });

  /// Total de páginas
  int get totalPages => (total / pageSize).ceil();

  /// Hay página siguiente
  bool get hasNextPage => page < totalPages;

  /// Hay página anterior
  bool get hasPreviousPage => page > 1;

  /// Índice del primer item
  int get fromIndex => items.isEmpty ? 0 : ((page - 1) * pageSize + 1);

  /// Índice del último item
  int get toIndex {
    final calculatedTo = page * pageSize;
    return calculatedTo > total ? total : calculatedTo;
  }

  /// Factory desde JSON genérico
  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PagedResult(
      items: (json['data'] as List? ?? json['items'] as List? ?? [])
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
    );
  }

  /// CopyWith para inmutabilidad
  PagedResult<T> copyWith({
    List<T>? items,
    int? total,
    int? page,
    int? pageSize,
  }) {
    return PagedResult(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  String toString() {
    return 'PagedResult(items: ${items.length}, total: $total, page: $page/$totalPages)';
  }
}