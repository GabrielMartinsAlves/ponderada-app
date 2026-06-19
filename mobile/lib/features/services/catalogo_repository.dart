import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_providers.dart';

class Servico {
  final String servico;
  final int duracaoMinutos;
  final num valor;
  const Servico({required this.servico, required this.duracaoMinutos, required this.valor});
  factory Servico.fromJson(Map<String, dynamic> j) => Servico(
        servico: (j['servico'] ?? '').toString(),
        duracaoMinutos: (j['duracao_minutos'] as num?)?.toInt() ?? 0,
        valor: (j['valor'] as num?) ?? 0,
      );
}

class CatalogoRepository {
  final ApiClient _api;
  CatalogoRepository(this._api);

  Future<List<Servico>> servicos() async {
    try {
      final res = await _api.dio.get('/servicos');
      final list = (res.data['servicos'] as List?) ?? [];
      return list.map((e) => Servico.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiClient.toApiException(e);
    }
  }

  Future<List<String>> profissionais({String? unidadeId, String? servico}) async {
    try {
      final res = await _api.dio.get('/profissionais', queryParameters: {
        if (unidadeId != null && unidadeId.isNotEmpty) 'unidade_id': unidadeId,
        if (servico != null && servico.isNotEmpty) 'servico': servico,
      });
      final list = (res.data['profissionais'] as List?) ?? [];
      return list.map((e) => (e as Map)['profissional'].toString()).toList();
    } catch (e) {
      throw ApiClient.toApiException(e);
    }
  }
}

final catalogoRepoProvider =
    Provider<CatalogoRepository>((ref) => CatalogoRepository(ref.read(apiClientProvider)));

final servicosProvider =
    FutureProvider<List<Servico>>((ref) => ref.read(catalogoRepoProvider).servicos());

final profissionaisProvider =
    FutureProvider.family<List<String>, (String? unidadeId, String? servico)>(
  (ref, k) => ref.read(catalogoRepoProvider).profissionais(unidadeId: k.$1, servico: k.$2),
);
