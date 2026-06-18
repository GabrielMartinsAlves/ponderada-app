import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_providers.dart';

class Agendamento {
  final String id;
  final String data; // data_agendamento (YYYY-MM-DD)
  final String hora;
  final String profissional;
  final String servico;
  final int duracaoMinutos;
  final num valor;
  final String status;
  final String? unidadeId;
  const Agendamento({
    required this.id,
    required this.data,
    required this.hora,
    required this.profissional,
    required this.servico,
    required this.duracaoMinutos,
    required this.valor,
    required this.status,
    this.unidadeId,
  });

  factory Agendamento.fromJson(Map<String, dynamic> j) => Agendamento(
        id: (j['id'] ?? '').toString(),
        data: (j['data_agendamento'] ?? '').toString(),
        hora: (j['hora'] ?? '').toString(),
        profissional: (j['profissional'] ?? '').toString(),
        servico: (j['servico'] ?? '').toString(),
        duracaoMinutos: (j['duracao_minutos'] as num?)?.toInt() ?? 0,
        valor: (j['valor'] as num?) ?? 0,
        status: (j['status'] ?? '').toString(),
        unidadeId: j['unidade_id']?.toString(),
      );

  bool get cancelado => status == 'Cancelado';
}

/// 409 do POST: horário já reservado (advisory lock no backend). UI mostra msg amigável.
class SlotTakenException implements Exception {
  final String message;
  SlotTakenException([this.message = 'Esse horário acabou de ser reservado. Escolha outro.']);
}

class AgendamentosRepository {
  final ApiClient _api;
  AgendamentosRepository(this._api);

  Future<List<Agendamento>> meus({String? escopo}) async {
    try {
      final res = await _api.dio.get('/agendamentos', queryParameters: {
        if (escopo != null) 'escopo': escopo,
      });
      final list = (res.data['agendamentos'] as List?) ?? [];
      return list.map((e) => Agendamento.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiClient.toApiException(e);
    }
  }

  Future<Agendamento> criar({
    required String servico,
    required String profissional,
    String? unidadeId,
    required String data,
    required String hora,
    String? observacoes,
  }) async {
    try {
      final res = await _api.dio.post('/agendamentos', data: {
        'servico': servico,
        'profissional': profissional,
        if (unidadeId != null) 'unidade_id': unidadeId,
        'data': data,
        'hora': hora,
        if (observacoes != null && observacoes.isNotEmpty) 'observacoes': observacoes,
      });
      return Agendamento.fromJson(res.data['agendamento'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) throw SlotTakenException();
      throw ApiClient.toApiException(e);
    } catch (e) {
      throw ApiClient.toApiException(e);
    }
  }

  Future<void> cancelar(String id) async {
    try {
      await _api.dio.patch('/agendamentos/$id/cancelar');
    } catch (e) {
      throw ApiClient.toApiException(e);
    }
  }
}

final agendamentosRepoProvider =
    Provider<AgendamentosRepository>((ref) => AgendamentosRepository(ref.read(apiClientProvider)));

final meusAgendamentosProvider =
    FutureProvider<List<Agendamento>>((ref) => ref.read(agendamentosRepoProvider).meus());
