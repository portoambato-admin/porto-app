// lib/core/rbac/rbac_repository.dart
import '../network/http_client.dart';
import 'rbac_endpoints.dart';

class RbacRepository {
  final HttpClient http;
  RbacRepository(this.http);

  Future<Map<String, dynamic>> mePermisos() async {
    // Tu HttpClient requiere headers: pasamos {} (él añadirá Authorization internamente)
    final data = await http.get(RbacEndpoints.mePermisos, headers: const {});
    if (data is Map<String, dynamic>) return data;
    return Map<String, dynamic>.from(data as Map);
  }
}
