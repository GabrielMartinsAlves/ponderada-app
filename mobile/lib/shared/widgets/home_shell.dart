import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Casca das 4 raízes com BottomNavigationBar (Início | Serviços | Agenda | Perfil).
class HomeShell extends StatelessWidget {
  final StatefulNavigationShell navShell;
  const HomeShell({super.key, required this.navShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navShell.currentIndex,
        onTap: (i) => navShell.goBranch(i, initialLocation: i == navShell.currentIndex),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.spa_outlined), activeIcon: Icon(Icons.spa_rounded), label: 'Serviços'),
          BottomNavigationBarItem(icon: Icon(Icons.event_outlined), activeIcon: Icon(Icons.event_rounded), label: 'Agenda'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    );
  }
}
