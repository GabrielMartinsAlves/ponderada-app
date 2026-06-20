import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../features/appointments/agendamentos_repository.dart';

/// Notificações locais do app: confirmação imediata ao agendar e lembrete
/// agendado antes do horário. Fuso fixo em America/Sao_Paulo.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Timers do lembrete em modo de teste (por id de agendamento).
  final Map<String, Timer> _demoTimers = {};

  /// Modo de teste: o lembrete cai poucos segundos após criar, para ser
  /// observável na demo. Em produção (false) cai em T-2h e T-24h do horário.
  static const bool reminderDemoMode = true;
  static const Duration _demoLead = Duration(seconds: 30);

  static const _chConfirm = 'lumma_confirmacoes';
  static const _chReminder = 'lumma_lembretes';

  Future<void> init() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    final impl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await impl?.createNotificationChannel(const AndroidNotificationChannel(
      _chConfirm, 'Confirmações',
      description: 'Confirmação dos seus agendamentos', importance: Importance.high));
    await impl?.createNotificationChannel(const AndroidNotificationChannel(
      _chReminder, 'Lembretes',
      description: 'Lembrete do seu horário', importance: Importance.high));
    _ready = true;
  }

  /// Pede permissão de notificação (Android 13+). true = pode notificar.
  Future<bool> ensurePermission() async {
    final impl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await impl?.requestNotificationsPermission();
    return granted ?? true;
  }

  // IDs estáveis entre execuções (não usa String.hashCode, que pode variar).
  int _stableId(String s, int salt) {
    var h = 0x811c9dc5 ^ salt;
    for (final c in s.codeUnits) {
      h = (h ^ c) * 0x01000193;
      h &= 0x7fffffff;
    }
    return h & 0x7fffffff;
  }

  int _confirmId(String id) => _stableId(id, 1);
  int _reminderId(String id, int n) => _stableId(id, 10 + n);

  AndroidNotificationDetails _details(String channel, String name) =>
      AndroidNotificationDetails(channel, name,
          channelDescription: name,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher');

  String _quando(Agendamento a) {
    final p = a.data.split('-');
    final dataBr = p.length == 3 ? '${p[2]}/${p[1]}' : a.data;
    return '$dataBr às ${a.hora}';
  }

  tz.TZDateTime _apptDateTime(Agendamento a) {
    final p = a.data.split('-').map(int.parse).toList();
    final h = a.hora.split(':').map(int.parse).toList();
    return tz.TZDateTime(tz.local, p[0], p[1], p[2], h[0], h.length > 1 ? h[1] : 0);
  }

  /// Notificação imediata ao confirmar o agendamento.
  Future<void> showConfirmation(Agendamento a, {String? unidadeNome}) async {
    if (!_ready) return;
    if (!await ensurePermission()) return;
    final local = unidadeNome != null ? ' · $unidadeNome' : '';
    await _plugin.show(
      _confirmId(a.id),
      'Agendamento confirmado',
      '${a.servico} com ${a.profissional} — ${_quando(a)}$local',
      NotificationDetails(android: _details(_chConfirm, 'Confirmações')),
    );
  }

  /// Agenda o(s) lembrete(s) antes do horário. Demo: ~30s; produção: T-2h e T-24h.
  Future<void> scheduleReminders(Agendamento a, {String? unidadeNome}) async {
    if (!_ready) return;
    if (!await ensurePermission()) return;
    final local = unidadeNome != null ? ' — $unidadeNome' : '';
    final body = '${a.servico} com ${a.profissional} ${_quando(a)}$local';

    if (reminderDemoMode) {
      // Modo de teste: dispara o lembrete em segundos para ser observável na demo.
      _demoTimers.remove(a.id)?.cancel();
      _demoTimers[a.id] = Timer(_demoLead, () {
        _plugin.show(
          _reminderId(a.id, 0),
          'Lembrete do seu horário',
          body,
          NotificationDetails(android: _details(_chReminder, 'Lembretes')),
        );
      });
      return;
    }

    // Produção: lembretes agendados pelo SO em T-2h e T-24h do horário.
    final agora = tz.TZDateTime.now(tz.local);
    final appt = _apptDateTime(a);
    const leads = [Duration(hours: 2), Duration(hours: 24)];
    for (var i = 0; i < leads.length; i++) {
      final t = appt.subtract(leads[i]);
      if (!t.isAfter(agora)) continue;
      await _plugin.zonedSchedule(
        _reminderId(a.id, i),
        'Lembrete do seu horário',
        body,
        t,
        NotificationDetails(android: _details(_chReminder, 'Lembretes')),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Cancela confirmação e lembretes do agendamento (chamado ao cancelar).
  Future<void> cancelForAppointment(String id) async {
    _demoTimers.remove(id)?.cancel(); // fecha o loop também no lembrete de teste
    await _plugin.cancel(_confirmId(id));
    for (var n = 0; n < 3; n++) {
      await _plugin.cancel(_reminderId(id, n));
    }
  }
}
