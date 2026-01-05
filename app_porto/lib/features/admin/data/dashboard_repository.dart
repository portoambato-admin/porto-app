// lib/features/admin/data/dashboard_repository.dart
import 'package:app_porto/core/services/session_token_provider.dart';

import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/http_client.dart';

class DashboardRepository {
  final HttpClient _http;

  DashboardRepository(this._http);

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<void> _requireAuth() async {
    final token = await SessionTokenProvider.instance.readToken();
    if (token == null || token.isEmpty) {
      throw Exception('Debes iniciar sesión para ver el dashboard.');
    }
  }

  Never _rethrowPretty(Object e) {
    if (e is ApiError) {
      if (e.status == 401) {
        throw Exception('Usuario no autenticado. Inicia sesión nuevamente.');
      }
      if (e.status == 403) {
        throw Exception('Permisos insuficientes para ver el dashboard.');
      }
      final msg = e.body?['message'] ?? e.message;
      throw Exception('$msg');
    }
    throw Exception(e.toString());
  }

  String _fmtDate(DateTime d) {
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<Map<String, dynamic>> admin({
    required DateTime from,
    required DateTime to,
    DateTime? asOf,
  }) async {
    try {
      await _requireAuth();
      final res = await _http.get(
        Endpoints.dashboardAdmin,
        headers: _headers,
        query: {
          'from': _fmtDate(from),
          'to': _fmtDate(to),
          'asOf': _fmtDate(asOf ?? DateTime.now()),
        },
      );
      if (res is Map) return Map<String, dynamic>.from(res);
      throw Exception('Respuesta inválida del dashboard (admin).');
    } catch (e) {
      _rethrowPretty(e);
    }
  }

  Future<Map<String, dynamic>> profesor({
    required DateTime from,
    required DateTime to,
    DateTime? asOf,
  }) async {
    try {
      await _requireAuth();
      final res = await _http.get(
        Endpoints.dashboardProfesor,
        headers: _headers,
        query: {
          'from': _fmtDate(from),
          'to': _fmtDate(to),
          'asOf': _fmtDate(asOf ?? DateTime.now()),
        },
      );
      if (res is Map) return Map<String, dynamic>.from(res);
      throw Exception('Respuesta inválida del dashboard (profesor).');
    } catch (e) {
      _rethrowPretty(e);
    }
  }

  Future<Map<String, dynamic>> representante({
    required DateTime from,
    required DateTime to,
    DateTime? asOf,
  }) async {
    try {
      await _requireAuth();
      final res = await _http.get(
        Endpoints.dashboardRepresentante,
        headers: _headers,
        query: {
          'from': _fmtDate(from),
          'to': _fmtDate(to),
          'asOf': _fmtDate(asOf ?? DateTime.now()),
        },
      );
      if (res is Map) return Map<String, dynamic>.from(res);
      throw Exception('Respuesta inválida del dashboard (representante).');
    } catch (e) {
      _rethrowPretty(e);
    }
  }
}
