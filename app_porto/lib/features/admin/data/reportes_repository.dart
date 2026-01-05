// lib/features/admin/data/reportes_repository.dart
import 'package:app_porto/core/services/session_token_provider.dart';
import '../../../core/constants/endpoints.dart';
import '../../../core/network/http_client.dart';
import '../../../core/network/api_error.dart';

class ReportesRepository {
  final HttpClient _http;
  ReportesRepository(this._http);

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  String _fmtDate(DateTime d) {
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _requireAuth() async {
    final token = await SessionTokenProvider.instance.readToken();
    if (token == null || token.isEmpty) {
      throw Exception('Debes iniciar sesión para ver reportes.');
    }
  }

  Never _rethrowPretty(Object e) {
    if (e is ApiError) {
      if (e.status == 401) throw Exception('No autenticado. Inicia sesión nuevamente.');
      if (e.status == 403) throw Exception('No tienes permisos para ver estos reportes.');
      throw Exception(e.message);
    }
    throw Exception('Error al consultar el reporte.');
  }

  Map<String, String> _qDateRange({DateTime? desde, DateTime? hasta}) {
    final q = <String, String>{};
    if (desde != null) q['desde'] = _fmtDate(desde);
    if (hasta != null) q['hasta'] = _fmtDate(hasta);
    return q;
  }

  Future<Map<String, dynamic>> estadoCobros({
    DateTime? desde,
    DateTime? hasta,
    DateTime? corte,
    int diaVencimiento = 5,
  }) async {
    try {
      await _requireAuth();
      final q = _qDateRange(desde: desde, hasta: hasta);
      q['dia_vencimiento'] = '$diaVencimiento';
      if (corte != null) q['corte'] = _fmtDate(corte);

      final res = await _http.get(
        Endpoints.reporteEstadoCobros,
        query: q,
        headers: _headers,
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      _rethrowPretty(e);
    }
  }

  Future<Map<String, dynamic>> cuentasPorCobrar({
    DateTime? corte,
    int diaVencimiento = 5,
  }) async {
    try {
      await _requireAuth();
      final q = <String, String>{
        'dia_vencimiento': '$diaVencimiento',
      };
      if (corte != null) q['corte'] = _fmtDate(corte);

      final res = await _http.get(
        Endpoints.reporteCuentasPorCobrar,
        query: q,
        headers: _headers,
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      _rethrowPretty(e);
    }
  }

  Future<Map<String, dynamic>> historialPagosCliente({
    required int idEstudiante,
    DateTime? desde,
    DateTime? hasta,
    DateTime? corte,
    int diaVencimiento = 5,
  }) async {
    try {
      await _requireAuth();
      final q = _qDateRange(desde: desde, hasta: hasta);
      q['dia_vencimiento'] = '$diaVencimiento';
      if (corte != null) q['corte'] = _fmtDate(corte);

      final res = await _http.get(
        Endpoints.reporteHistorialPagosCliente(idEstudiante),
        query: q,
        headers: _headers,
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      _rethrowPretty(e);
    }
  }

  Future<Map<String, dynamic>> cobrosPorPeriodo({
    required DateTime desde,
    required DateTime hasta,
    required String granularidad, // dia|semana|mes|anio
  }) async {
    try {
      await _requireAuth();
      final q = <String, String>{
        'desde': _fmtDate(desde),
        'hasta': _fmtDate(hasta),
        'granularidad': granularidad,
      };

      final res = await _http.get(
        Endpoints.reporteCobrosPorPeriodo,
        query: q,
        headers: _headers,
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      _rethrowPretty(e);
    }
  }

  Future<Map<String, dynamic>> morosidad({
    DateTime? corte,
    int diaVencimiento = 5,
  }) async {
    try {
      await _requireAuth();
      final q = <String, String>{
        'dia_vencimiento': '$diaVencimiento',
      };
      if (corte != null) q['corte'] = _fmtDate(corte);

      final res = await _http.get(
        Endpoints.reporteMorosidad,
        query: q,
        headers: _headers,
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      _rethrowPretty(e);
    }
  }

  Future<Map<String, dynamic>> metodosPago({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    try {
      await _requireAuth();
      final q = _qDateRange(desde: desde, hasta: hasta);

      final res = await _http.get(
        Endpoints.reporteMetodosPago,
        query: q,
        headers: _headers,
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      _rethrowPretty(e);
    }
  }

  Future<Map<String, dynamic>> alertasRecordatorios({
    DateTime? desde,
    DateTime? hasta,
    int ventanaDias = 14,
  }) async {
    try {
      await _requireAuth();
      final q = _qDateRange(desde: desde, hasta: hasta);
      q['ventana_dias'] = '$ventanaDias';

      final res = await _http.get(
        Endpoints.reporteAlertasRecordatorios,
        query: q,
        headers: _headers,
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      _rethrowPretty(e);
    }
  }

  Future<Map<String, dynamic>> consolidadoGerencia({
    DateTime? desde,
    DateTime? hasta,
    DateTime? corte,
    int diaVencimiento = 5,
  }) async {
    try {
      await _requireAuth();
      final q = _qDateRange(desde: desde, hasta: hasta);
      q['dia_vencimiento'] = '$diaVencimiento';
      if (corte != null) q['corte'] = _fmtDate(corte);

      final res = await _http.get(
        Endpoints.reporteConsolidadoGerencia,
        query: q,
        headers: _headers,
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      _rethrowPretty(e);
    }
  }

  // ===== Reportes academia (extra)
  Future<Map<String, dynamic>> usuariosResumen() async {
    try {
      await _requireAuth();
      final res = await _http.get(
        Endpoints.reporteUsuariosResumen,
        headers: _headers,
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      _rethrowPretty(e);
    }
  }

  Future<Map<String, dynamic>> auditoriaActividad({
    required DateTime desde,
    required DateTime hasta,
    int top = 10,
  }) async {
    try {
      await _requireAuth();
      final q = <String, String>{
        'desde': _fmtDate(desde),
        'hasta': _fmtDate(hasta),
        'top': '$top',
      };
      final res = await _http.get(
        Endpoints.reporteUsuariosAuditoriaActividad,
        query: q,
        headers: _headers,
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      _rethrowPretty(e);
    }
  }

  Future<Map<String, dynamic>> estudiantesResumen() async {
    try {
      await _requireAuth();
      final res = await _http.get(
        Endpoints.reporteEstudiantesResumen,
        headers: _headers,
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      _rethrowPretty(e);
    }
  }

  Future<Map<String, dynamic>> asistenciaResumen({
    required DateTime desde,
    required DateTime hasta,
    int? idSubcategoria,
  }) async {
    try {
      await _requireAuth();
      final q = <String, String>{
        'desde': _fmtDate(desde),
        'hasta': _fmtDate(hasta),
      };
      if (idSubcategoria != null) q['id_subcategoria'] = '$idSubcategoria';

      final res = await _http.get(
        Endpoints.reporteAsistenciaResumen,
        query: q,
        headers: _headers,
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      _rethrowPretty(e);
    }
  }

  Future<Map<String, dynamic>> evaluacionesResumen({
    required DateTime desde,
    required DateTime hasta,
    int top = 10,
  }) async {
    try {
      await _requireAuth();
      final q = <String, String>{
        'desde': _fmtDate(desde),
        'hasta': _fmtDate(hasta),
        'top': '$top',
      };
      final res = await _http.get(
        Endpoints.reporteEvaluacionesResumen,
        query: q,
        headers: _headers,
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      _rethrowPretty(e);
    }
  }
}
