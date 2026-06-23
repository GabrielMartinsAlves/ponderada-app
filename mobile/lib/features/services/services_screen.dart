import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/lumma_colors.dart';
import '../../shared/widgets/lumma_card.dart';
import '../../shared/widgets/state_views.dart';
import 'booking_screen.dart';
import 'catalogo_repository.dart';
import 'interpretar_repository.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(servicosProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Serviços')),
      body: Column(
        children: [
          const _BuscaInteligente(),
          Expanded(
            child: async.when(
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
                  onTap: () => context.push('/agendar', extra: BookingPrefill(servico: s.servico)),
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
          ),
        ],
      ),
    );
  }
}

/// Campo de agendamento por linguagem natural. Envia o texto ao backend, que
/// extrai a intencao com a IA e valida tudo contra o catalogo real. Em caso de
/// sucesso, abre o fluxo pre-preenchido; em qualquer falha, cai no passo a passo.
class _BuscaInteligente extends ConsumerStatefulWidget {
  const _BuscaInteligente();
  @override
  ConsumerState<_BuscaInteligente> createState() => _BuscaInteligenteState();
}

class _BuscaInteligenteState extends ConsumerState<_BuscaInteligente> {
  final _controller = TextEditingController();
  bool _carregando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _carregando) return;
    FocusScope.of(context).unfocus();
    setState(() => _carregando = true);
    try {
      final r = await ref.read(interpretarRepoProvider).interpretar(texto);
      if (!mounted) return;
      if (r.temServico) {
        // Pre-preenche o fluxo; a pessoa confirma (nunca agenda sozinho).
        context.push(
          '/agendar',
          extra: BookingPrefill(
            servico: r.servico,
            profissional: r.profissional,
            unidadeId: r.unidadeId,
            data: r.data,
            hora: r.hora,
            sugestoes: r.sugestoesDeHorario,
          ),
        );
      } else {
        _avisar('Não consegui entender tudo. Escolha um serviço para continuar.');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      _avisar(e.statusCode == 429
          ? e.message
          : 'Não consegui interpretar agora. Vamos no passo a passo.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _avisar(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: LummaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.auto_awesome, size: 18, color: LummaColors.mauveDark),
              SizedBox(width: 8),
              Text('Agende em uma frase',
                  style: TextStyle(fontWeight: FontWeight.w600, color: LummaColors.text)),
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              enabled: !_carregando,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _enviar(),
              decoration: InputDecoration(
                hintText: "Descreva o que você quer: ex. 'unha sexta de manhã com a Aline'",
                suffixIcon: _carregando
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: LummaColors.mauve),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send_rounded, color: LummaColors.mauveDark),
                        onPressed: _enviar,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
