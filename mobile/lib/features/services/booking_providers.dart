import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_providers.dart';
import 'disponibilidade.dart';
import 'feriados_service.dart';

final disponibilidadeRepoProvider = Provider<DisponibilidadeRepository>(
  (ref) => DisponibilidadeRepository(ref.read(apiClientProvider)),
);

final feriadosServiceProvider = Provider<FeriadosService>((ref) => FeriadosService());

/// Feriados nacionais de um ano (para desabilitar dias no date picker).
final feriadosAnoProvider = FutureProvider.family<Set<String>, int>(
  (ref, ano) => ref.read(feriadosServiceProvider).doAno(ano),
);

/// Disponibilidade de slots para (data, profissional, servico).
final disponibilidadeProvider =
    FutureProvider.family<Disponibilidade, (String data, String profissional, String? servico)>(
  (ref, k) => ref.read(disponibilidadeRepoProvider).buscar(
        data: k.$1,
        profissional: k.$2,
        servico: k.$3,
      ),
);
