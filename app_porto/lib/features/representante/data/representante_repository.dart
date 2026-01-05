import 'package:app_porto/core/services/session_token_provider.dart';
import '../../../core/constants/endpoints.dart';
import '../../../core/network/http_client.dart';
import '../../../core/network/api_error.dart';

class RepresentanteRepository {
  final HttpClient _http;
  RepresentanteRepository(this._http);

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<void> _requireAuth() async {
    final token = await SessionTokenProvider.instance.readToken();
    if (token == null || token.isEmpty) {
      throw Exception('Debes iniciar sesión para ver tus mensualidades.');
    }
  }

  Never _rethrowPretty(Object e) {
    if (e is ApiError) {
      if (e.status == 401) {
        throw Exception('Usuario no autenticado. Inicia sesión nuevamente.');
      }
      if (e.status == 403) {
        throw Exception('No tienes permisos para ver esta información.');
      }
      final msg = e.body?['message'] ?? e.message;
      throw Exception('$msg');
    }
    throw Exception(e.toString());
  }

  Future<List<Map<String, dynamic>>> misEstudiantes() async {
    try {
      await _requireAuth();
      final res = await _http.get(Endpoints.repEstudiantes, headers: _headers);
      if (res is List) {
        return List<Map<String, dynamic>>.from(res);
      }
      return const <Map<String, dynamic>>[];
    } catch (e) {
      _rethrowPretty(e);
    }
  }

  Future<List<Map<String, dynamic>>> mensualidadesPorEstudiante(int idEstudiante) async {
    try {
      await _requireAuth();
      final res = await _http.get(
        Endpoints.repMensualidadesPorEstudiante(idEstudiante),
        headers: _headers,
      );
      if (res is List) {
        return List<Map<String, dynamic>>.from(res);
      }
      return const <Map<String, dynamic>>[];
    } catch (e) {
      _rethrowPretty(e);
    }
  }

  Future<Map<String, dynamic>?> detalleMensualidad(int idMensualidad) async {
    try {
      await _requireAuth();
      final res = await _http.get(
        Endpoints.repMensualidadDetalle(idMensualidad),
        headers: _headers,
      );
      if (res is Map) return Map<String, dynamic>.from(res);
      return null;
    } catch (e) {
      _rethrowPretty(e);
    }
  }

  Future<List<Map<String, dynamic>>> pagosPorMensualidad(int idMensualidad) async {
    try {
      await _requireAuth();
      final res = await _http.get(
        Endpoints.repPagosPorMensualidad(idMensualidad),
        headers: _headers,
      );
      if (res is List) {
        return List<Map<String, dynamic>>.from(res);
      }
      return const <Map<String, dynamic>>[];
    } catch (e) {
      _rethrowPretty(e);
    }
  }

  Future<Map<String, dynamic>?> resumenMensualidad(int idMensualidad) async {
    try {
      await _requireAuth();
      final res = await _http.get(
        Endpoints.repResumenPorMensualidad(idMensualidad),
        headers: _headers,
      );
      if (res is Map) return Map<String, dynamic>.from(res);
      return null;
    } catch (e) {
      _rethrowPretty(e);
    }
  }
}
