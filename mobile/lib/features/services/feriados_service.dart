import 'package:dio/dio.dart';
import '../../core/config/env.dart';

/// Feriados nacionais para marcar dias indisponíveis no calendário.
///
/// Fonte: backend `GET /api/booking/feriados` — que consome a API externa
/// (BrasilAPI) com cache + fail-safe no servidor. Aqui há cache em memória por
/// ano e fail-open (se falhar, não bloqueia no app; o backend ainda revalida o
/// feriado na disponibilidade ao tentar agendar).
class FeriadosService {
  final Map<int, Set<String>> _cache = {};
  final Dio _dio = Dio(BaseOptions(
    baseUrl: '${Env.apiBaseUrl}/api/booking',
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  Future<Set<String>> doAno(int ano) async {
    final cached = _cache[ano];
    if (cached != null) return cached;
    try {
      final res = await _dio.get('/feriados', queryParameters: {'ano': ano});
      final set = ((res.data['feriados'] as List).map((d) => d as String)).toSet();
      _cache[ano] = set; // 'YYYY-MM-DD'
      return set;
    } catch (_) {
      return <String>{}; // fail-open
    }
  }
}
