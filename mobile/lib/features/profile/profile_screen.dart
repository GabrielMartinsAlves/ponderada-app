import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/theme/lumma_colors.dart';
import '../../shared/widgets/lumma_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final nome = (user?.nome.isNotEmpty ?? false) ? user!.nome : 'Visitante';
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: LummaColors.pink,
                child: Text(
                  nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 32, color: LummaColors.mauveDark, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              Text(nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: LummaColors.text)),
              Text(user?.email ?? '', style: const TextStyle(color: LummaColors.textMuted)),
            ]),
          ),
          const SizedBox(height: 24),
          LummaCard(
            padding: EdgeInsets.zero,
            child: Column(children: const [
              _Item(Icons.person_outline, 'Meus dados'),
              Divider(height: 1, color: LummaColors.borderLight),
              _Item(Icons.notifications_none_rounded, 'Notificações'),
              Divider(height: 1, color: LummaColors.borderLight),
              _Item(Icons.place_outlined, 'Unidades'),
            ]),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Item(this.icon, this.label);
  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: LummaColors.mauve),
        title: Text(label, style: const TextStyle(color: LummaColors.text)),
        trailing: const Icon(Icons.chevron_right, color: LummaColors.mauve),
      );
}
