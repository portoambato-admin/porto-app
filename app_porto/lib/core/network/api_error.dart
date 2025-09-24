class ApiError implements Exception {
  final int? status;
  final String message;
  final Map<String, dynamic>? body;

  ApiError(this.message, {this.status, this.body});

  @override
  String toString() => 'ApiError($status): $message';
}
