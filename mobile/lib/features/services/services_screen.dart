import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/lumma_colors.dart';
import '../../shared/widgets/lumma_card.dart';
import '../../shared/widgets/state_views.dart';
import 'catalogo_repository.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(servicosProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Serviços')),
      body: async.when(
        loading: () => const LoadingView(label: 'Carregando serviços...'),
        error: (e, _) => ErrorView(
          message: e is ApiException ? e.message : 'Erro ao carregar serviços',
          onRetry: () => ref.invalidate(servicosProvider),
        ),
        data: (servicos) {
          if (servicos.isEmpty) {
            return const EmptyView(
              icon: Icons.spa_outlined,
              title: 'Nenhum serviço disponível',
              subtitle: 'Tente novamente mais tarde.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(servicosProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: servicos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final s = servicos[i];
                return LummaCard(
                  onTap: () => context.push('/agendar', extra: s.servico),
                  child: Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: LummaColors.pink, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.spa_rounded, color: LummaColors.mauveDark, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.servico, style: const TextStyle(fontWeight: FontWeight.w600, color: LummaColors.text)),
                        const SizedBox(height: 2),
                        Text('${s.duracaoMinutos} min · R\$ ${s.valor.toStringAsFixed(0)}',
                            style: const TextStyle(color: LummaColors.textMuted, fontSize: 13)),
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
