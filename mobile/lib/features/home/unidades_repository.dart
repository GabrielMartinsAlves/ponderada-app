import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_providers.dart';

class Unidade {
  final String id;
  final String nome;
  final String? endereco;
  final double? lat;
  final double? lng;
  const Unidade({required this.id, required this.nome, this.endereco, this.lat, this.lng});

  factory Unidade.fromJson(Map<String, dynamic> j) => Unidade(
        id: (j['id'] ?? '').toString(),
        nome: (j['nome'] ?? '').toString(),
        endereco: j['endereco']?.toString(),
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
      );

  // nome sem o prefixo "Espaço Lumma — "
  String get nomeCurto => nome.contains('—') ? nome.split('—').last.trim() : nome;
}

class UnidadesRepository {
  final ApiClient _api;
  UnidadesRepository(this._api);

  Future<List<Unidade>> listar() async {
    try {
      final res = await _api.dio.get('/unidades');
      final list = (res.data['unidades'] as List?) ?? [];
      return list.map((e) => Unidade.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiClient.toApiException(e);
    }
  }
}

final unidadesRepoProvider =
    Provider<UnidadesRepository>((ref) => UnidadesRepository(ref.read(apiClientProvider)));

final unidadesProvider =
    FutureProvider<List<Unidade>>((ref) => ref.read(unidadesRepoProvider).listar());
