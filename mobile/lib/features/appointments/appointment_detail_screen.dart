import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_exception.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/theme/lumma_colors.dart';
import '../../shared/widgets/lumma_card.dart';
import '../../shared/widgets/state_views.dart';
import '../home/maps_helper.dart';
import '../home/unidades_repository.dart';
import 'agendamentos_repository.dart';
import 'comprovante_helper.dart';

class AppointmentDetailScreen extends ConsumerStatefulWidget {
  final Object? agendamento;
  const AppointmentDetailScreen({super.key, this.agendamento});
  @override
  ConsumerState<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends ConsumerState<AppointmentDetailScreen> {
  bool _cancelando = false;
  bool _abrindoAgenda = false;
  final GlobalKey _comprovanteKey = GlobalKey();

  String _fmtData(String ymd) {
    final p = ymd.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : ymd;
  }

  void _msg(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _compartilhar(Agendamento a, Unidade? u) async {
    try {
      await compartilharComprovante(a, u, imagemKey: _comprovanteKey);
    } catch (_) {
      if (mounted) _msg('Não foi possível compartilhar agora.');
    }
  }

  Future<void> _salvarNaAgenda(Agendamento a, Unidade? u) async {
    setState(() => _abrindoAgenda = true);
    try {
      final erro = await salvarNaAgenda(a, u);
      if (mounted && erro != null) _msg(erro);
    } finally {
      if (mounted) setState(() => _abrindoAgenda = false);
    }
  }

  Future<void> _cancelar(Agendamento a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cancelar agendamento?'),
        content: const Text('Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Voltar')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Cancelar', style: TextStyle(color: LummaColors.mauveDark)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _cancelando = true);
    try {
      await ref.read(agendamentosRepoProvider).cancelar(a.id);
      // fecha o loop: o lembrete agendado não deve mais disparar
      await NotificationService.instance.cancelForAppointment(a.id);
      ref.invalidate(meusAgendamentosProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agendamento cancelado.')));
      context.pop();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _cancelando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.agendamento;
    if (a is! Agendamento) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhe')),
        body: const EmptyView(title: 'Agendamento não encontrado'),
      );
    }
    final unidade = ref.watch(unidadesProvider).maybeWhen(
      data: (us) {
        final m = us.where((x) => x.id == a.unidadeId);
        return m.isEmpty ? null : m.first;
      },
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do agendamento')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          RepaintBoundary(
            key: _comprovanteKey,
            child: LummaCard(
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                _Linha(Icons.spa_outlined, 'Serviço', a.servico),
                const Divider(height: 22, color: LummaColors.borderLight),
                _Linha(Icons.person_outline, 'Profissional', a.profissional),
                if (unidade != null) ...[
                  const Divider(height: 22, color: LummaColors.borderLight),
                  _Linha(Icons.place_outlined, 'Unidade', unidade.nomeCurto),
                ],
                const Divider(height: 22, color: LummaColors.borderLight),
                _Linha(Icons.schedule, 'Quando', '${_fmtData(a.data)} · ${a.hora}'),
                const Divider(height: 22, color: LummaColors.borderLight),
                _Linha(Icons.attach_money, 'Valor', 'R\$ ${a.valor.toStringAsFixed(2).replaceAll('.', ',')}'),
                const Divider(height: 22, color: LummaColors.borderLight),
                _Linha(Icons.info_outline, 'Status', a.status),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: (unidade?.lat != null && unidade?.lng != null)
                ? () => abrirRota(unidade!.lat!, unidade.lng!)
                : () => _msg('Rota indisponível para esta unidade.'),
            icon: const Icon(Icons.directions_outlined),
            label: const Text('Como chegar'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _compartilhar(a, unidade),
            icon: const Icon(Icons.ios_share),
            label: const Text('Compartilhar comprovante'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _abrindoAgenda ? null : () => _salvarNaAgenda(a, unidade),
            icon: _abrindoAgenda
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: LummaColors.mauveDark))
                : const Icon(Icons.event_available_outlined),
            label: const Text('Salvar na agenda'),
          ),
          const SizedBox(height: 10),
          if (a.cancelado)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: LummaColors.cream, borderRadius: BorderRadius.circular(12)),
              child: const Row(children: [
                Icon(Icons.cancel_outlined, size: 20, color: LummaColors.mauveDark),
                SizedBox(width: 10),
                Text('Agendamento cancelado', style: TextStyle(color: LummaColors.mauveDark)),
              ]),
            )
          else
            OutlinedButton.icon(
              onPressed: _cancelando ? null : () => _cancelar(a),
              style: OutlinedButton.styleFrom(foregroundColor: LummaColors.mauveDark, side: const BorderSide(color: LummaColors.border)),
              icon: _cancelando
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: LummaColors.mauveDark))
                  : const Icon(Icons.close),
              label: const Text('Cancelar agendamento'),
            ),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  final IconData icon;
  final String rotulo, valor;
  const _Linha(this.icon, this.rotulo, this.valor);
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 20, color: LummaColors.mauve),
        const SizedBox(width: 12),
        Text('$rotulo: ', style: const TextStyle(color: LummaColors.textMuted)),
        Expanded(child: Text(valor, style: const TextStyle(color: LummaColors.text, fontWeight: FontWeight.w500))),
      ]);
}
