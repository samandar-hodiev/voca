/// The signed-in app: four tabs over one liquid field, with the floating bar.
///
/// One Scaffold for the whole shell, so the liquid field is painted once and every tab
/// sits on top of it. The tabs keep their scroll position and loaded data when switched,
/// because each is its own branch in a StatefulShellRoute.
///
/// Profile is the rightmost destination, where the person's own account conventionally
/// lives.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/liquid_background.dart';
import '../core/widgets/liquid_bottom_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    LiquidNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Bosh sahifa',
    ),
    LiquidNavItem(
      icon: Icons.mic_none_rounded,
      activeIcon: Icons.mic_rounded,
      label: 'Mashq',
    ),
    LiquidNavItem(
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights_rounded,
      label: 'Natijalar',
    ),
    LiquidNavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  void _onTap(int index) {
    // Tapping the tab that is already open returns it to its first screen, the way people
    // expect a tab bar to behave.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Content scrolls underneath the floating bar instead of stopping above it.
      extendBody: true,
      body: LiquidBackground(
        // Calmer than the setup screens: these pages are dense, and the field is there to
        // give depth, not to compete with numbers.
        intensity: 0.6,
        child: navigationShell,
      ),
      bottomNavigationBar: LiquidBottomBar(
        items: _items,
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
      ),
    );
  }
}
