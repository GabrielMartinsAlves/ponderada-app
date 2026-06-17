import 'package:flutter/material.dart';
import '../../core/theme/lumma_colors.dart';

/// Estado de carregamento central.
class LoadingView extends StatelessWidget {
  final String? label;
  const LoadingView({super.key, this.label});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: LummaColors.mauve),
        if (label != null) ...[
          const SizedBox(height: 12),
          Text(label!, style: const TextStyle(color: LummaColors.textMuted)),
        ],
      ]),
    );
  }
}

/// Estado vazio (lista sem itens).
class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  const EmptyView({super.key, this.icon = Icons.inbox_outlined, required this.title, this.subtitle, this.action});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 56, color: LummaColors.mauve400),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: LummaColors.text)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(color: LummaColors.textMuted)),
          ],
          if (action != null) ...[const SizedBox(height: 20), action!],
        ]),
      ),
    );
  }
}

/// Estado de erro com ação de tentar novamente.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorView({super.key, required this.message, this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 56, color: LummaColors.mauveDark),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: LummaColors.text)),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Tentar novamente')),
          ],
        ]),
      ),
    );
  }
}
