// Excepción para expulsar al usuario (Token vencido)
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  @override
  String toString() => message;
}

// Tu clase original de error, mejorada
class ApiError implements Exception {
  final String message;
  final int? status;
  final Map<String, dynamic>? body;

  ApiError(this.message, {this.status, this.body});

  @override
  String toString() => message;
}