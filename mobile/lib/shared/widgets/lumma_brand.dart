import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/lumma_colors.dart';
import '../../core/theme/lumma_typography.dart';

/// Logomark (SVG) da marca.
class LummaLogo extends StatelessWidget {
  final double size;
  const LummaLogo({super.key, this.size = 72});
  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset('assets/images/logomark.svg', width: size, height: size);
  }
}

/// Wordmark "LUMMA" + tagline opcional, na tipografia da marca.
class LummaWordmark extends StatelessWidget {
  final double fontSize;
  final Color color;
  final String? tagline;
  const LummaWordmark({super.key, this.fontSize = 30, this.color = LummaColors.text, this.tagline});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('LUMMA', style: LummaTypography.wordmark(fontSize: fontSize, color: color, weight: FontWeight.w300)),
      if (tagline != null) ...[
        const SizedBox(height: 4),
        Text(
          tagline!.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.0,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    ]);
  }
}
