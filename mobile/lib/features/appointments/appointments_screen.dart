import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/lumma_colors.dart';
import '../../shared/widgets/lumma_card.dart';
import '../../shared/widgets/state_views.dart';
import 'agendamentos_repository.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  static const _meses = ['', 'jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];
  static String _fmtData(String ymd) {
    final p = ymd.split('-');
    if (p.length != 3) return ymd;
    return '${p[2]}/${_meses[int.tryParse(p[1]) ?? 0]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(meusAgendamentosProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Meus agendamentos')),
      body: async.when(
        loading: () => const LoadingView(label: 'Carregando...'),
        error: (e, _) => ErrorView(
          message: e is ApiException ? e.message : 'Erro ao carregar',
          onRetry: () => ref.invalidate(meusAgendamentosProvider),
        ),
        data: (ags) {
          if (ags.isEmpty) {
            return EmptyView(
              icon: Icons.event_available_outlined,
              title: 'Você ainda não tem agendamentos',
              subtitle: 'Escolha um serviço e agende seu horário.',
              action: ElevatedButton(onPressed: () => context.go('/servicos'), child: const Text('Agendar')),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(meusAgendamentosProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: ags.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final a = ags[i];
                final cor = a.cancelado
                    ? LummaColors.mauveDark
                    : (a.status == 'Finalizado' ? LummaColors.sageDark : LummaColors.mauve);
                return LummaCard(
                  onTap: () => context.push('/agendamento-detalhe', extra: a),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.servico, style: const TextStyle(fontWeight: FontWeight.w600, color: LummaColors.text)),
                        const SizedBox(height: 4),
                        Text('${_fmtData(a.data)} · ${a.hora} · ${a.profissional}',
                            style: const TextStyle(color: LummaColors.textMuted, fontSize: 13)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                          child: Text(a.status, style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ),
                    const Icon(Icons.chevron_right, color: LummaColors.mauve),
                  ]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
