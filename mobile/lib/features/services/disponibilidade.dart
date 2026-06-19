import '../../core/network/api_client.dart';

class Slot {
  final String hora;
  final bool disponivel;
  const Slot(this.hora, this.disponivel);
  factory Slot.fromJson(Map<String, dynamic> j) =>
      Slot(j['hora'] as String? ?? '', j['disponivel'] == true);
}

class Disponibilidade {
  final String data;
  final bool aberto;
  final String? motivo;
  final List<Slot> slots;
  const Disponibilidade({required this.data, required this.aberto, this.motivo, required this.slots});

  List<Slot> get livres => slots.where((s) => s.disponivel).toList();

  factory Disponibilidade.fromJson(Map<String, dynamic> j) => Disponibilidade(
        data: j['data'] as String? ?? '',
        aberto: j['aberto'] == true,
        motivo: j['motivo'] as String?,
        slots: ((j['slots'] as List?) ?? [])
            .map((s) => Slot.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

class DisponibilidadeRepository {
  final ApiClient _api;
  DisponibilidadeRepository(this._api);

  Future<Disponibilidade> buscar({
    required String data,
    required String profissional,
    String? servico,
    String? unidadeId,
  }) async {
    try {
      final res = await _api.dio.get('/disponibilidade', queryParameters: {
        'data': data,
        'profissional': profissional,
        if (servico != null && servico.isNotEmpty) 'servico': servico,
        if (unidadeId != null && unidadeId.isNotEmpty) 'unidade_id': unidadeId,
      });
      return Disponibilidade.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.toApiException(e);
    }
  }
}
