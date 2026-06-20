import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_exception.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/theme/lumma_colors.dart';
import '../../shared/widgets/lumma_card.dart';
import '../../shared/widgets/state_views.dart';
import '../appointments/agendamentos_repository.dart';
import '../home/unidades_repository.dart';
import 'booking_providers.dart';
import 'catalogo_repository.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String? servico;
  const BookingScreen({super.key, this.servico});
  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  static const _diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  static const _meses = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];

  String? _unidadeId;
  String? _unidadeNome;
  String? _prof;
  DateTime? _data;
  String? _slot;
  bool _criando = false;

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _fmtData(DateTime d) => '${_diasSemana[d.weekday - 1]}, ${d.day} de ${_meses[d.month - 1]}';

  bool _diaAberto(DateTime d) => d.weekday >= DateTime.tuesday && d.weekday <= DateTime.saturday;

  DateTime _proximoValido(DateTime from, Set<String> feriados) {
    var d = from;
    for (var i = 0; i < 40; i++) {
      if (_diaAberto(d) && !feriados.contains(_ymd(d))) return d;
      d = d.add(const Duration(days: 1));
    }
    return from;
  }

  Future<void> _abrirCalendario() async {
    final hoje = DateTime.now();
    final inicio = DateTime(hoje.year, hoje.month, hoje.day);
    final fim = inicio.add(const Duration(days: 365));
    final feriados = <String>{};
    for (final ano in {inicio.year, fim.year}) {
      feriados.addAll(await ref.read(feriadosAnoProvider(ano).future));
    }
    if (!mounted) return;
    final escolhido = await showDatePicker(
      context: context,
      initialDate: _proximoValido(inicio, feriados),
      firstDate: inicio,
      lastDate: fim,
      helpText: 'Escolha a data',
      cancelText: 'Cancelar',
      confirmText: 'OK',
      selectableDayPredicate: (d) => _diaAberto(d) && !feriados.contains(_ymd(d)),
    );
    if (escolhido != null) {
      setState(() {
        _data = escolhido;
        _slot = null;
      });
    }
  }

  Future<void> _confirmar() async {
    if (_prof == null || _data == null || _slot == null) return;
    final dataYmd = _ymd(_data!);
    setState(() => _criando = true);
    try {
      final ag = await ref.read(agendamentosRepoProvider).criar(
            servico: widget.servico ?? '',
            profissional: _prof!,
            unidadeId: _unidadeId,
            data: dataYmd,
            hora: _slot!,
          );
      ref.invalidate(meusAgendamentosProvider);
      // Notificação imediata + lembrete agendado (degrade elegante se sem permissão).
      final notif = NotificationService.instance;
      await notif.showConfirmation(ag, unidadeNome: _unidadeNome);
      await notif.scheduleReminders(ag, unidadeNome: _unidadeNome);
      if (!mounted) return;
      context.push('/confirmacao', extra: <String, String>{
        'servico': ag.servico,
        'profissional': ag.profissional,
        if (_unidadeNome != null) 'unidade': _unidadeNome!,
        'data': _fmtData(_data!),
        'hora': ag.hora,
      });
    } on SlotTakenException catch (e) {
      if (!mounted) return;
      setState(() => _slot = null);
      // recarrega os horários (o slot foi tomado por outra pessoa)
      ref.invalidate(disponibilidadeProvider((dataYmd, _prof!, widget.servico)));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: LummaColors.mauveDark),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _criando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final podeConfirmar = _prof != null && _data != null && _slot != null && !_criando;
    return Scaffold(
      appBar: AppBar(title: const Text('Agendar')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          LummaCard(
            child: Row(children: [
              const Icon(Icons.spa_rounded, color: LummaColors.mauveDark),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.servico ?? 'Serviço',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: LummaColors.text)),
              ),
            ]),
          ),
          const SizedBox(height: 22),
          const _Label('Unidade'),
          _unidadesArea(),
          const SizedBox(height: 22),
          const _Label('Profissional'),
          _profissionaisArea(),
          const SizedBox(height: 22),
          const _Label('Data'),
          LummaCard(
            onTap: _abrirCalendario,
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined, color: LummaColors.mauve),
              const SizedBox(width: 12),
              Text(_data == null ? 'Escolher data' : _fmtData(_data!),
                  style: TextStyle(color: _data == null ? LummaColors.textMuted : LummaColors.text, fontWeight: FontWeight.w500)),
              const Spacer(),
              const Icon(Icons.chevron_right, color: LummaColors.mauve),
            ]),
          ),
          const SizedBox(height: 22),
          const _Label('Horário'),
          _slotsArea(),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: podeConfirmar ? _confirmar : null,
            child: _criando
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : const Text('Confirmar agendamento'),
          ),
        ],
      ),
    );
  }

  Widget _unidadesArea() {
    final async = ref.watch(unidadesProvider);
    return async.when(
      loading: () => const _ChipsLoading(),
      error: (e, _) => _InlineErro(e is ApiException ? e.message : 'Erro ao carregar unidades',
          () => ref.invalidate(unidadesProvider)),
      data: (unidades) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: unidades
            .map((u) => ChoiceChip(
                  label: Text(u.nomeCurto),
                  selected: _unidadeId == u.id,
                  onSelected: (_) => setState(() {
                    _unidadeId = u.id;
                    _unidadeNome = u.nomeCurto;
                    _prof = null;
                    _slot = null;
                  }),
                ))
            .toList(),
      ),
    );
  }

  Widget _profissionaisArea() {
    if (_unidadeId == null) return const _Hint('Escolha uma unidade primeiro.');
    final key = (_unidadeId, widget.servico);
    final async = ref.watch(profissionaisProvider(key));
    return async.when(
      loading: () => const _ChipsLoading(),
      error: (e, _) => _InlineErro(e is ApiException ? e.message : 'Erro ao carregar profissionais',
          () => ref.invalidate(profissionaisProvider(key))),
      data: (profs) {
        if (profs.isEmpty) return const _Hint('Nenhum profissional para este serviço nesta unidade.');
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: profs
              .map((p) => ChoiceChip(
                    label: Text(p),
                    selected: _prof == p,
                    onSelected: (_) => setState(() {
                      _prof = p;
                      _slot = null;
                    }),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _slotCell(String hora) {
    final sel = _slot == hora;
    return Material(
      color: sel ? LummaColors.pink : LummaColors.cream,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _slot = hora),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? LummaColors.mauve : LummaColors.border),
          ),
          child: Text(
            hora,
            style: TextStyle(
              color: sel ? LummaColors.mauveDark : LummaColors.text,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _slotsArea() {
    if (_prof == null) return const _Hint('Escolha um profissional para ver os horários.');
    if (_data == null) return const _Hint('Escolha uma data para ver os horários.');
    final key = (_ymd(_data!), _prof!, widget.servico);
    final async = ref.watch(disponibilidadeProvider(key));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: LoadingView(label: 'Carregando horários...'),
      ),
      error: (e, _) => _InlineErro(e is ApiException ? e.message : 'Erro ao carregar horários',
          () => ref.invalidate(disponibilidadeProvider(key))),
      data: (disp) {
        if (!disp.aberto) return _Hint('Indisponível: ${disp.motivo ?? 'salão fechado'}.', icon: Icons.block);
        final livres = disp.livres;
        if (livres.isEmpty) return const _Hint('Sem horários disponíveis nesse dia.', icon: Icons.event_busy);
        // Grade fixa: todas as células com o mesmo tamanho.
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: livres.map((s) => _slotCell(s.hora)).toList(),
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  final String t;
  const _Label(this.t);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, color: LummaColors.text)),
      );
}

class _Hint extends StatelessWidget {
  final String texto;
  final IconData icon;
  const _Hint(this.texto, {this.icon = Icons.info_outline});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: LummaColors.cream, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, size: 20, color: LummaColors.mauveDark),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: const TextStyle(color: LummaColors.mauveDark))),
        ]),
      );
}

class _ChipsLoading extends StatelessWidget {
  const _ChipsLoading();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: LummaColors.mauve)),
          SizedBox(width: 10),
          Text('Carregando...', style: TextStyle(color: LummaColors.textMuted)),
        ]),
      );
}

class _InlineErro extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _InlineErro(this.msg, this.onRetry);
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(msg, style: const TextStyle(color: LummaColors.mauveDark))),
        TextButton(onPressed: onRetry, child: const Text('Tentar de novo')),
      ]);
}
