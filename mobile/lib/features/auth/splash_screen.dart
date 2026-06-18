import 'package:flutter/material.dart';
import '../../core/theme/lumma_colors.dart';
import '../../shared/widgets/lumma_brand.dart';

/// Tela de partida enquanto o token é validado (estado AuthStatus.unknown).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: LummaColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LummaLogo(size: 96),
            SizedBox(height: 28),
            CircularProgressIndicator(color: LummaColors.mauve),
          ],
        ),
      ),
    );
  }
}
