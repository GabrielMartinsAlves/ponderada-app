import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../home/unidades_repository.dart';
import 'agendamentos_repository.dart';

String _dataBr(String ymd) {
  final p = ymd.split('-');
  return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : ymd;
}

String _valorBr(num v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

/// Texto do comprovante montado a partir do agendamento real.
String comprovanteTexto(Agendamento a, Unidade? u) {
  return [
    'Comprovante — Espaço Lumma',
    '',
    'Serviço: ${a.servico}',
    'Profissional: ${a.profissional}',
    if (u != null) 'Unidade: ${u.nomeCurto}',
    'Quando: ${_dataBr(a.data)} às ${a.hora}',
    'Valor: ${_valorBr(a.valor)}',
    if (u?.endereco != null) 'Endereço: ${u!.endereco}',
  ].join('\n');
}

/// Compartilha o comprovante (recurso nativo do SO). Tenta a imagem do card
/// (RepaintBoundary -> PNG) com o texto; se não der, compartilha só o texto.
Future<void> compartilharComprovante(Agendamento a, Unidade? u, {GlobalKey? imagemKey}) async {
  final texto = comprovanteTexto(a, u);
  try {
    final ctx = imagemKey?.currentContext;
    if (ctx != null) {
      final boundary = ctx.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes != null) {
        final dir = await getTemporaryDirectory();
        final file = await File('${dir.path}/comprovante_lumma.png')
            .writeAsBytes(bytes.buffer.asUint8List());
        await SharePlus.instance.share(ShareParams(
          text: texto,
          subject: 'Comprovante — Espaço Lumma',
          files: [XFile(file.path)],
        ));
        return;
      }
    }
  } catch (_) {
    // qualquer falha na imagem -> cai para texto puro
  }
  await SharePlus.instance.share(ShareParams(text: texto, subject: 'Comprovante — Espaço Lumma'));
}

String _icsStamp(String ymd, String hhmm, {int addMinutes = 0}) {
  final p = ymd.split('-').map(int.parse).toList();
  final h = hhmm.split(':').map(int.parse).toList();
  final dt = DateTime(p[0], p[1], p[2], h[0], h.length > 1 ? h[1] : 0)
      .add(Duration(minutes: addMinutes));
  String two(int v) => v.toString().padLeft(2, '0');
  return '${dt.year}${two(dt.month)}${two(dt.day)}T${two(dt.hour)}${two(dt.minute)}00';
}

String _escape(String s) => s.replaceAll('\\', '\\\\').replaceAll(',', '\\,').replaceAll(';', '\\;');

/// Monta o evento no padrão iCalendar (.ics), com fuso America/Sao_Paulo
/// declarado para o horário não cair deslocado em nenhuma agenda.
String construirIcs(Agendamento a, Unidade? u) {
  final start = _icsStamp(a.data, a.hora);
  final end = _icsStamp(a.data, a.hora, addMinutes: a.duracaoMinutos > 0 ? a.duracaoMinutos : 60);
  final now = DateTime.now().toUtc();
  String two(int v) => v.toString().padLeft(2, '0');
  final stamp =
      '${now.year}${two(now.month)}${two(now.day)}T${two(now.hour)}${two(now.minute)}${two(now.second)}Z';
  final desc = 'Profissional: ${a.profissional}${u != null ? '\\nUnidade: ${u.nomeCurto}' : ''}';
  return [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Espaco Lumma//Agendamentos//PT-BR',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    'BEGIN:VTIMEZONE',
    'TZID:America/Sao_Paulo',
    'BEGIN:STANDARD',
    'DTSTART:19700101T000000',
    'TZOFFSETFROM:-0300',
    'TZOFFSETTO:-0300',
    'TZNAME:-03',
    'END:STANDARD',
    'END:VTIMEZONE',
    'BEGIN:VEVENT',
    'UID:${a.id}@lumma',
    'DTSTAMP:$stamp',
    'DTSTART;TZID=America/Sao_Paulo:$start',
    'DTEND;TZID=America/Sao_Paulo:$end',
    'SUMMARY:${_escape('${a.servico} — Espaço Lumma')}',
    'LOCATION:${_escape(u?.endereco ?? 'Espaço Lumma')}',
    'DESCRIPTION:$desc',
    'END:VEVENT',
    'END:VCALENDAR',
  ].join('\r\n');
}

/// Gera o .ics e abre no app de agenda (intent ACTION_VIEW text/calendar),
/// que abre a tela de "adicionar evento" já preenchida.
/// Retorna null em sucesso, ou uma mensagem de erro para a UI.
Future<String?> salvarNaAgenda(Agendamento a, Unidade? u) async {
  try {
    final ics = construirIcs(a, u);
    final dir = await getTemporaryDirectory();
    final file = await File('${dir.path}/agendamento_lumma.ics').writeAsString(ics);
    final res = await OpenFilex.open(file.path, type: 'text/calendar');
    switch (res.type) {
      case ResultType.done:
        return null;
      case ResultType.noAppToOpen:
        return 'Nenhum app de agenda encontrado para abrir o evento.';
      default:
        return 'Não foi possível abrir a agenda agora.';
    }
  } catch (_) {
    return 'Falha ao gerar o evento de calendário.';
  }
}
