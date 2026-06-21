import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/lumma_theme.dart';
import 'routing/app_router.dart';

class LummaApp extends ConsumerWidget {
  const LummaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Lumma Agendamentos',
      debugShowCheckedModeBanner: false,
      theme: LummaTheme.light,
      routerConfig: router,
    );
  }
}
