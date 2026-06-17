/// Tipos de erro normalizados da camada de rede.
enum ApiErrorKind { network, unauthorized, badRequest, server, unknown }

/// Erro central da camada de rede — todas as chamadas convertem para isto.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiErrorKind kind;

  ApiException(this.message, {this.statusCode, this.kind = ApiErrorKind.unknown});

  bool get isNetwork => kind == ApiErrorKind.network;
  bool get isUnauthorized => kind == ApiErrorKind.unauthorized;

  @override
  String toString() => 'ApiException($statusCode, $kind): $message';
}
