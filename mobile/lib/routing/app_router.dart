import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_controller.dart';
import '../shared/widgets/home_shell.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/home/home_screen.dart';
import '../features/services/services_screen.dart';
import '../features/services/booking_screen.dart';
import '../features/services/confirmation_screen.dart';
import '../features/appointments/appointments_screen.dart';
import '../features/appointments/appointment_detail_screen.dart';
import '../features/profile/profile_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // bridge Riverpod -> Listenable do go_router
  final refresh = ValueNotifier(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final loc = state.matchedLocation;
      // bootstrap em andamento -> splash
      if (status == AuthStatus.unknown) return loc == '/splash' ? null : '/splash';
      final emAuth = loc == '/login' || loc == '/cadastro';
      if (status == AuthStatus.unauthenticated) return emAuth ? null : '/login';
      // autenticado: sai do splash/login para a home
      if (emAuth || loc == '/splash') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/cadastro', builder: (c, s) => const SignupScreen()),

      // Shell com BottomNavigationBar (4 raízes)
      StatefulShellRoute.indexedStack(
        builder: (c, s, navShell) => HomeShell(navShell: navShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/servicos', builder: (c, s) => const ServicesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/agendamentos', builder: (c, s) => const AppointmentsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/perfil', builder: (c, s) => const ProfileScreen()),
          ]),
        ],
      ),

      // Telas full-screen (push sobre o shell, sem bottom nav)
      GoRoute(
        path: '/agendar',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => BookingScreen(prefill: s.extra as BookingPrefill?),
      ),
      GoRoute(
        path: '/confirmacao',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => ConfirmationScreen(resumo: s.extra as Map<String, String>?),
      ),
      GoRoute(
        path: '/agendamento-detalhe',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => AppointmentDetailScreen(agendamento: s.extra),
      ),
    ],
  );
});
