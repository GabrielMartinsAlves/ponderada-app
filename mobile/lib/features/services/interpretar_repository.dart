import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_providers.dart';

/// Resultado da interpretacao por linguagem natural. Todos os campos ja vem
/// validados pelo backend contra o catalogo real (o modelo nunca e fonte de
/// verdade). `unidadeId` e o id da unidade, nunca o nome livre que o texto trouxe.
class Interpretacao {
  final String? servico;
  final String? profissional;
  final String? unidadeId;
  final String? data; // YYYY-MM-DD
  final String? periodo; // manha | tarde
  final String? hora; // HH:MM já disponível, para pré-seleção do horário
  final List<String> sugestoesDeHorario;
  final List<String> camposFaltantes;
  final bool fallback;

  const Interpretacao({
    this.servico,
    this.profissional,
    this.unidadeId,
    this.data,
    this.periodo,
    this.hora,
    this.sugestoesDeHorario = const [],
    this.camposFaltantes = const [],
    this.fallback = false,
  });

  /// Tem ao menos o servico: da para abrir o fluxo de agendamento pre-preenchido.
  bool get temServico => servico != null && servico!.isNotEmpty;

  factory Interpretacao.fromJson(Map<String, dynamic> j) {
    final intencao = (j['intencao'] as Map?)?.cast<String, dynamic>() ?? const {};
    return Interpretacao(
      servico: _s(intencao['servico']),
      profissional: _s(intencao['profissional']),
      unidadeId: _s(intencao['unidade']),
      data: _s(intencao['data']),
      periodo: _s(intencao['periodo']),
      hora: _s(j['hora_selecionada']),
      sugestoesDeHorario:
          ((j['sugestoes_de_horario'] as List?) ?? const []).map((e) => e.toString()).toList(),
      camposFaltantes:
          ((j['campos_faltantes'] as List?) ?? const []).map((e) => e.toString()).toList(),
      fallback: j['fallback'] == true,
    );
  }

  static String? _s(Object? v) {
    final t = v?.toString().trim() ?? '';
    return t.isEmpty ? null : t;
  }
}

/// Cliente do endpoint de agendamento por linguagem natural. A chave de IA fica
/// so no backend; o app apenas envia o texto e recebe a intencao ja validada.
class InterpretarRepository {
  final ApiClient _api;
  InterpretarRepository(this._api);

  Future<Interpretacao> interpretar(String texto) async {
    try {
      final res = await _api.dio.post('/interpretar', data: {'texto': texto});
      return Interpretacao.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.toApiException(e);
    }
  }
}

final interpretarRepoProvider = Provider<InterpretarRepository>(
  (ref) => InterpretarRepository(ref.read(apiClientProvider)),
);
