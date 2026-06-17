import 'package:flutter/material.dart';
import '../../core/theme/lumma_colors.dart';

/// Card padrão Lumma: branco, raio 16, borda rose/40, sombra sutil.
class LummaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const LummaCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: LummaColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LummaColors.borderLight),
        boxShadow: const [BoxShadow(color: Color(0x0D3D2B35), blurRadius: 2, offset: Offset(0, 1))],
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: content),
    );
  }
}
