/// The root widget.
///
/// Assembles the theme, the router and localization. Deliberately thin: it wires, it does
/// not decide.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/di/providers.dart';
import 'core/l10n/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'l10n/app_localizations.dart';
import 'routing/app_router.dart';

/// Holds the router for the lifetime of the app. Rebuilding a GoRouter drops navigation
/// state, so it is created once.
final routerProvider = Provider<GoRouter>((ref) {
  return AppRouter.create(ref.watch(appConfigProvider));
});

class VocaApp extends ConsumerWidget {
  const VocaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Voca',
      // The corner ribbon only says "this is a debug build", which the people looking at
      // the app already know and nobody outside the team benefits from seeing.
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),

      theme: VocaTheme.light(),
      darkTheme: VocaTheme.dark(),
      // The person's choice, which defaults to following the device until they make one.
      themeMode: ref.watch(themeModeProvider),

      // English by default; Uzbek and Russian are chosen in Settings or on the first
      // screen, and the choice is kept on the device.
      locale: ref.watch(localeProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,

      builder: (context, child) {
        // Clamp text scaling. People legitimately enlarge text, and the layout must
        // accommodate that; beyond this bound the design breaks rather than adapts, and a
        // broken layout is less accessible than a slightly smaller one.
        final scale = MediaQuery.textScalerOf(
          context,
        ).clamp(minScaleFactor: 0.85, maxScaleFactor: 1.4);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scale),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
