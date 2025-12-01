// lib/features/admin/data/pagos_repository.dart
import 'dart:math';
import 'package:app_porto/core/services/session_token_provider.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/endpoints.dart';
import '../../../core/network/http_client.dart';
import '../../../core/network/api_error.dart';

class PagosRepository {
  final HttpClient _http;

  PagosRepository(this._http);

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // ---------- HELPERS ----------

  /// Verifica que exista token antes de llamar al backend.
  /// Evita hacer requests que siempre devolverían 401.
  Future<void> _requireAuth() async {
    final token = await SessionTokenProvider.instance.readToken();
    if (token == null || token.isEmpty) {
      throw Exception('Debes iniciar sesión para gestionar pagos.');
    }
  }

  /// Traduce ApiError(401/403) en mensajes claros para el usuario.
  Never _rethrowPretty(Object e) {
    if (e is ApiError) {
      if (e.status == 401) {
        throw Exception('Usuario no autenticado. Inicia sesión nuevamente.');
      }
      if (e.status == 403) {
        throw Exception('Permisos insuficientes para operar pagos.');
      }
      // Otros códigos devuelven el mensaje del backend si viene
      final msg = e.body?['message'] ?? e.message;
      throw Exception('$msg');
    }
    // Excepción desconocida
    throw Exception(e.toString());
  }

  /// Genera clave idempotente única
  String _generateIdempotencyKey() {
    final rnd = Random();
    final hex = List.generate(12, (_) => rnd.nextInt(16).toRadixString(16)).join();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return 'idem-$timestamp-$hex';
  }

  /// Asegura formato YYYY-MM-DD
  String _formatDate(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Parsea monto a double con 2 decimales
  double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      String s = value.trim().replaceAll(' ', '').replaceAll('\$', '');
      if (s.contains(',') && s.contains('.')) {
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else if (s.contains(',')) {
        s = s.replaceAll(',', '.');
      }
      return double.tryParse(s) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> _mapPago(Map<String, dynamic> json) {
    return {
      'id': json['id_pago'] ?? json['id'],
      'idMensualidad': json['id_mensualidad'] ?? json['mensualidad_id'],
      'monto': _parseAmount(json['monto_pagado'] ?? json['monto']),
      'fecha': json['fecha_pago'] ?? json['fecha'],
      'metodo': json['metodo_pago'] ?? json['metodo'],
      'referencia': json['referencia'],
      'notas': json['notas'] ?? json['observaciones'],
      'activo': (json['activo'] ?? true) == true,
      'motivoAnulacion': json['motivo_anulacion'] ?? json['motivoAnulacion'],
      'creadoPor': json['creado_por'],
      'creadoPorNombre': json['creado_por_nombre'],
      'anuladoPor': json['anulado_por'],
      'anuladoPorNombre': json['anulado_por_nombre'],
      'anuladoEn': json['anulado_en'],
      'idempotencyKey': json['idempotency_key'],
    };
  }

  // ---------- LECTURAS ----------

  /// Lista pagos de una mensualidad
  Future<List<Map<String, dynamic>>> porMensualidad(int idMensualidad) async {
    try {
      await _requireAuth();

      final res = await _http.get(
        '${Endpoints.pagos}/mensualidad/$idMensualidad',
        headers: _headers,
      );

      if (res is List) {
        return List<Map<String, dynamic>>.from(res).map(_mapPago).toList();
      }
      return const <Map<String, dynamic>>[];
    } catch (e, st) {
      debugPrint('PagosRepository.porMensualidad error: $e\n$st');
      _rethrowPretty(e);
    }
  }

  /// Resumen de pagos de una mensualidad
  /// {valor, pagado, pendiente, numPagosActivos, numPagosAnulados, estado}
  Future<Map<String, dynamic>?> resumen(int idMensualidad) async {
    try {
      await _requireAuth();

      final res = await _http.get(
        '${Endpoints.pagos}/mensualidad/$idMensualidad/resumen',
        headers: _headers,
      );

      if (res is Map) {
        final map = Map<String, dynamic>.from(res);
        return {
          'idMensualidad': map['id_mensualidad'] ?? idMensualidad,
          'valor': _parseAmount(map['valor']),
          'pagado': _parseAmount(map['pagado']),
          'pendiente': _parseAmount(map['pendiente']),
          'estado': map['estado'],
          'numPagosActivos': map['num_pagos_activos'] ?? 0,
          'numPagosAnulados': map['num_pagos_anulados'] ?? 0,
        };
      }
      return null;
    } catch (e, st) {
      debugPrint('PagosRepository.resumen error: $e\n$st');
      _rethrowPretty(e);
    }
  }

  // ---------- MUTACIONES ----------

  /// Crea un pago con validación + idempotencia
  Future<Map<String, dynamic>> crear({
    required int idMensualidad,
    required double monto,
    required DateTime fecha,
    required String metodoPago, // efectivo | transferencia | tarjeta
    String? referencia,
    String? notas,
  }) async {
    try {
      await _requireAuth();

      if (monto <= 0) {
        throw Exception('El monto debe ser mayor a 0.');
      }
      if (!['efectivo', 'transferencia', 'tarjeta'].contains(metodoPago)) {
        throw Exception('Método inválido: use efectivo, transferencia o tarjeta.');
      }

      final body = {
        'id_mensualidad': idMensualidad,
        'monto_pagado'  : double.parse(monto.toStringAsFixed(2)),
        'fecha_pago'    : _formatDate(fecha),
        'metodo_pago'   : metodoPago,
        if (referencia != null && referencia.isNotEmpty) 'referencia': referencia,
        if (notas != null && notas.isNotEmpty) 'notas': notas,
      };

      final idempotencyKey = _generateIdempotencyKey();

      final res = await _http.post(
        Endpoints.pagos,
        headers: {
          ..._headers,
          'Idempotency-Key': idempotencyKey,
        },
        body: body,
      );

      if (res is Map && res['ok'] == true && res['data'] != null) {
        return _mapPago(Map<String, dynamic>.from(res['data']));
      }

      if (res is Map && res['ok'] == false) {
        final error = (res['error'] ?? res['message'] ?? 'Error desconocido').toString();
        final restante = res['restante'];
        if (restante != null) {
          final r = _parseAmount(restante).toStringAsFixed(2);
          throw Exception('$error. Restante: \$$r');
        }
        throw Exception(error);
      }

      throw Exception('Respuesta inesperada del servidor.');
    } catch (e, st) {
      debugPrint('PagosRepository.crear error: $e\n$st');
      _rethrowPretty(e);
    }
  }

  /// Actualiza un pago
  Future<Map<String, dynamic>> actualizar({
    required int idPago,
    double? monto,
    DateTime? fecha,
    String? metodoPago,
    String? referencia,
    String? notas,
  }) async {
    try {
      await _requireAuth();

      if (monto != null && monto <= 0) {
        throw Exception('El monto debe ser mayor a 0.');
      }
      if (metodoPago != null &&
          !['efectivo', 'transferencia', 'tarjeta'].contains(metodoPago)) {
        throw Exception('Método inválido: use efectivo, transferencia o tarjeta.');
      }

      final body = <String, dynamic>{};
      if (monto != null) body['monto_pagado'] = double.parse(monto.toStringAsFixed(2));
      if (fecha != null) body['fecha_pago'] = _formatDate(fecha);
      if (metodoPago != null) body['metodo_pago'] = metodoPago;
      if (referencia != null) body['referencia'] = referencia;
      if (notas != null) body['notas'] = notas;

      if (body.isEmpty) throw Exception('No hay cambios para actualizar.');

      final res = await _http.put(
        '${Endpoints.pagos}/$idPago',
        headers: _headers,
        body: body,
      );

      if (res is Map && res['ok'] == true && res['data'] != null) {
        return _mapPago(Map<String, dynamic>.from(res['data']));
      }

      if (res is Map && res['ok'] == false) {
        final error = (res['error'] ?? res['message'] ?? 'Error desconocido').toString();
        final restante = res['restante'];
        if (restante != null) {
          final r = _parseAmount(restante).toStringAsFixed(2);
          throw Exception('$error. Restante: \$$r');
        }
        throw Exception(error);
      }

      throw Exception('Respuesta inesperada del servidor.');
    } catch (e, st) {
      debugPrint('PagosRepository.actualizar error: $e\n$st');
      _rethrowPretty(e);
    }
  }

  /// Anula (soft delete)
  Future<bool> anular({
    required int idPago,
    required String motivo,
  }) async {
    try {
      await _requireAuth();

      final m = motivo.trim();
      if (m.isEmpty) throw Exception('Debe proporcionar un motivo.');

      final url = '${Endpoints.pagos}/$idPago?motivo=${Uri.encodeComponent(m)}';
      await _http.delete(url, headers: _headers);

      return true; // si no lanzó excepción, OK
    } catch (e, st) {
      debugPrint('PagosRepository.anular error: $e\n$st');
      _rethrowPretty(e);
    }
  }
}
