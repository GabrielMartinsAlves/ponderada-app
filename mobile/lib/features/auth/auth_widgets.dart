import 'package:flutter/material.dart';
import '../../core/theme/lumma_colors.dart';

/// Caixa de erro inline (login/cadastro).
class ErroBox extends StatelessWidget {
  final String msg;
  const ErroBox(this.msg, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: LummaColors.errorBg, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          const Icon(Icons.error_outline, size: 18, color: LummaColors.errorText),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: const TextStyle(color: LummaColors.errorText))),
        ]),
      );
}
