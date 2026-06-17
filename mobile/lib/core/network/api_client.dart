import 'package:dio/dio.dart';
import '../config/env.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Cliente HTTP central (dio) com os 3 interceptors do plano:
///  1) injeta `Authorization: Bearer <access_token>`
///  2) em 401, tenta refresh 1x; se falhar, limpa a sessão (router volta ao login)
///  3) mapeia qualquer erro para [ApiException] (tratamento central)
class ApiClient {
  final Dio dio;
  final TokenStorage tokens;
  bool _refreshing = false;

  ApiClient({required this.tokens, Dio? dioOverride})
      : dio = dioOverride ??
            Dio(BaseOptions(
              baseUrl: '${Env.apiBaseUrl}/api/booking',
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 12),
              headers: {'Content-Type': 'application/json'},
            )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokens.accessToken;
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401 && !_refreshing) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            try {
              return handler.resolve(await _retry(e.requestOptions));
            } catch (_) {
              /* cai no reject abaixo */
            }
          } else {
            await tokens.clear();
          }
        }
        handler.reject(e);
      },
    ));
  }

  Future<bool> _tryRefresh() async {
    final rt = await tokens.refreshToken;
    if (rt == null) return false;
    _refreshing = true;
    try {
      final res = await Dio(BaseOptions(baseUrl: '${Env.apiBaseUrl}/api/booking'))
          .post('/auth/refresh', data: {'refresh_token': rt});
      await tokens.save(
        accessToken: res.data['access_token'] as String,
        refreshToken: res.data['refresh_token'] as String,
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      _refreshing = false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions ro) async {
    final token = await tokens.accessToken;
    return dio.request(
      ro.path,
      data: ro.data,
      queryParameters: ro.queryParameters,
      options: Options(method: ro.method, headers: {...ro.headers, 'Authorization': 'Bearer $token'}),
    );
  }

  /// Converte erro (dio/desconhecido) em [ApiException] — ponto único de tratamento.
  static ApiException toApiException(Object error) {
    if (error is DioException) {
      final code = error.response?.statusCode;
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return ApiException('Sem conexão com o servidor', kind: ApiErrorKind.network);
      }
      final serverMsg = (error.response?.data is Map) ? error.response?.data['error']?.toString() : null;
      if (code == 401) return ApiException(serverMsg ?? 'Sessão expirada', statusCode: 401, kind: ApiErrorKind.unauthorized);
      if (code != null && code >= 500) return ApiException(serverMsg ?? 'Erro no servidor', statusCode: code, kind: ApiErrorKind.server);
      return ApiException(serverMsg ?? 'Não foi possível completar a requisição', statusCode: code, kind: ApiErrorKind.badRequest);
    }
    return ApiException('Erro inesperado', kind: ApiErrorKind.unknown);
  }
}
