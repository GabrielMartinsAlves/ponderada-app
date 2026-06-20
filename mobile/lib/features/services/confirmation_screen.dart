import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/lumma_colors.dart';
import '../../core/theme/lumma_typography.dart';
import '../../shared/widgets/lumma_card.dart';

class ConfirmationScreen extends StatelessWidget {
  final Map<String, String>? resumo;
  const ConfirmationScreen({super.key, this.resumo});

  @override
  Widget build(BuildContext context) {
    final r = resumo ?? const {};
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, size: 84, color: LummaColors.sageDark),
              const SizedBox(height: 16),
              Text('Agendamento confirmado!', style: LummaTypography.displayTitle(fontSize: 26), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              LummaCard(
                padding: const EdgeInsets.all(18),
                child: Column(children: [
                  _Linha(Icons.spa_outlined, r['servico'] ?? 'Serviço'),
                  const Divider(height: 22, color: LummaColors.borderLight),
                  _Linha(Icons.person_outline, r['profissional'] ?? '—'),
                  if (r['unidade'] != null) ...[
                    const Divider(height: 22, color: LummaColors.borderLight),
                    _Linha(Icons.place_outlined, r['unidade']!),
                  ],
                  const Divider(height: 22, color: LummaColors.borderLight),
                  _Linha(Icons.schedule, '${r['data'] ?? ''} · ${r['hora'] ?? ''}'),
                ]),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/agendamentos'),
                  child: const Text('Ver meus agendamentos'),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Compartilhamento chega na Fase 4')),
                ),
                icon: const Icon(Icons.ios_share),
                label: const Text('Compartilhar comprovante'),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: () => context.go('/home'), child: const Text('Voltar ao início')),
            ],
          ),
        ),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  final IconData icon;
  final String texto;
  const _Linha(this.icon, this.texto);
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 20, color: LummaColors.mauve),
        const SizedBox(width: 12),
        Expanded(child: Text(texto, style: const TextStyle(color: LummaColors.text, fontWeight: FontWeight.w500))),
      ]);
}
