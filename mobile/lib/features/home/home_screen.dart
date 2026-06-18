import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/lumma_colors.dart';
import '../../core/theme/lumma_typography.dart';
import '../../shared/widgets/lumma_card.dart';
import '../appointments/agendamentos_repository.dart';
import 'location_service.dart';
import 'maps_helper.dart';
import 'unidades_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nome = ref.watch(authControllerProvider).user?.nome ?? 'Visitante';
    final primeiro = nome.trim().isEmpty ? 'Visitante' : nome.trim().split(' ').first;
    return Scaffold(
      appBar: AppBar(title: Text('LUMMA', style: LummaTypography.wordmark(fontSize: 22))),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(posicaoProvider);
          ref.invalidate(unidadesProvider);
          ref.invalidate(meusAgendamentosProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text('Olá, $primeiro', style: LummaTypography.displayTitle(fontSize: 28)),
            const SizedBox(height: 4),
            const Text('Pronta para se cuidar?', style: TextStyle(color: LummaColors.textMuted)),
            const SizedBox(height: 20),
            const _ProximoAgendamento(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/servicos'),
                icon: const Icon(Icons.add),
                label: const Text('Agendar um horário'),
              ),
            ),
            const SizedBox(height: 24),
            Row(children: [
              const Text('Nossas unidades', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: LummaColors.text)),
              const Spacer(),
              IconButton(
                tooltip: 'Atualizar localização',
                onPressed: () => ref.invalidate(posicaoProvider),
                icon: const Icon(Icons.my_location, size: 20, color: LummaColors.mauve),
              ),
            ]),
            const SizedBox(height: 6),
            const _UnidadesComDistancia(),
          ],
        ),
      ),
    );
  }
}

class _ProximoAgendamento extends ConsumerWidget {
  const _ProximoAgendamento();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(meusAgendamentosProvider).maybeWhen(
          data: (ags) {
            final ativos = ags.where((a) => !a.cancelado).toList();
            if (ativos.isEmpty) return const SizedBox.shrink();
            final a = ativos.first;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: LummaCard(
                onTap: () => context.push('/agendamento-detalhe', extra: a),
                child: Row(children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(color: LummaColors.cream, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.event_available_rounded, color: LummaColors.mauveDark),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Próximo agendamento', style: TextStyle(fontWeight: FontWeight.w600, color: LummaColors.text)),
                      const SizedBox(height: 2),
                      Text('${a.servico} · ${a.data} ${a.hora}', style: const TextStyle(color: LummaColors.textMuted, fontSize: 13)),
                    ]),
                  ),
                  const Icon(Icons.chevron_right, color: LummaColors.mauve),
                ]),
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
  }
}

class _UnidadesComDistancia extends ConsumerWidget {
  const _UnidadesComDistancia();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unidadesAsync = ref.watch(unidadesProvider);
    return unidadesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(color: LummaColors.mauve)),
      ),
      error: (e, _) => _erro(e is ApiException ? e.message : 'Erro ao carregar unidades', () => ref.invalidate(unidadesProvider)),
      data: (unidades) {
        final posAsync = ref.watch(posicaoProvider);
        return posAsync.when(
          loading: () => Column(children: [
            _aviso('Obtendo sua localização...', icon: Icons.my_location),
            ...unidades.map((u) => _card(u, null)),
          ]),
          error: (_, _) => Column(children: unidades.map((u) => _card(u, null)).toList()),
          data: (res) {
            if (!res.permitido) {
              return Column(children: [
                _aviso(res.aviso ?? 'Localização indisponível.', onAtivar: () => ref.invalidate(posicaoProvider)),
                ...unidades.map((u) => _card(u, null)),
              ]);
            }
            final pos = res.posicao!;
            final comDist = unidades.where((u) => u.lat != null && u.lng != null).map((u) {
              final d = Geolocator.distanceBetween(pos.latitude, pos.longitude, u.lat!, u.lng!);
              return (u, d);
            }).toList()
              ..sort((a, b) => a.$2.compareTo(b.$2));
            final semCoord = unidades.where((u) => u.lat == null || u.lng == null);
            return Column(children: [
              ...comDist.map((e) => _card(e.$1, e.$2)),
              ...semCoord.map((u) => _card(u, null)),
            ]);
          },
        );
      },
    );
  }

  Widget _card(Unidade u, double? distancia) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: LummaCard(
          child: Row(children: [
            const Icon(Icons.place_outlined, color: LummaColors.mauve),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(u.nomeCurto, style: const TextStyle(fontWeight: FontWeight.w600, color: LummaColors.text))),
                  if (distancia != null)
                    Text(fmtDistancia(distancia), style: const TextStyle(color: LummaColors.mauveDark, fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
                if (u.endereco != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(u.endereco!, style: const TextStyle(color: LummaColors.textMuted, fontSize: 12)),
                  ),
              ]),
            ),
            if (u.lat != null && u.lng != null)
              IconButton(
                tooltip: 'Como chegar',
                onPressed: () => abrirRota(u.lat!, u.lng!),
                icon: const Icon(Icons.directions_rounded, color: LummaColors.mauve),
              ),
          ]),
        ),
      );

  Widget _aviso(String msg, {VoidCallback? onAtivar, IconData icon = Icons.location_off_outlined}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: LummaColors.cream, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(icon, size: 18, color: LummaColors.mauveDark),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(color: LummaColors.mauveDark, fontSize: 13))),
            if (onAtivar != null) TextButton(onPressed: onAtivar, child: const Text('Ativar')),
          ]),
        ),
      );

  Widget _erro(String msg, VoidCallback onRetry) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Expanded(child: Text(msg, style: const TextStyle(color: LummaColors.mauveDark))),
          TextButton(onPressed: onRetry, child: const Text('Tentar de novo')),
        ]),
      );
}
