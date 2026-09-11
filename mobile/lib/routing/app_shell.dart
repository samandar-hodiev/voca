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
import '../core/theme/app_colors.dart';
import '../l10n/l10n.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static List<LiquidNavItem> _items(AppLocalizations l) => [
    LiquidNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: l.navHome,
    ),
    LiquidNavItem(
      icon: Icons.mic_none_rounded,
      activeIcon: Icons.mic_rounded,
      label: l.navPractice,
    ),
    LiquidNavItem(
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights_rounded,
      label: l.navProgress,
    ),
    LiquidNavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: l.navProfile,
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
        // The same quiet wash as every other screen. The liquid is on the cards and
        // controls in front of it, not in the background.
        intensity: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [navigationShell, const _ScrollEdge()],
        ),
      ),
      bottomNavigationBar: LiquidBottomBar(
        items: _items(context.l10n),
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

/// The iOS scroll edge: content scrolling up under the status bar fades out instead of
/// running into the clock and the battery.
class _ScrollEdge extends StatelessWidget {
  const _ScrollEdge();

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: MediaQuery.paddingOf(context).top + 20,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors.background.withValues(alpha: 0.92),
                colors.background.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
