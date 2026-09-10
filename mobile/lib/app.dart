/// The root widget.
///
/// Assembles the theme, the router and localization. Deliberately thin: it wires, it does
/// not decide.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/di/providers.dart';
import 'core/theme/app_theme.dart';
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
    final config = ref.watch(appConfigProvider);

    return MaterialApp.router(
      title: 'Voca',
      debugShowCheckedModeBanner: !config.isProd,
      routerConfig: ref.watch(routerProvider),

      theme: VocaTheme.light(),
      darkTheme: VocaTheme.dark(),
      // Follow the device. Dark mode is complete but not yet visually designed, so it is
      // honest to respect the system rather than force either.
      themeMode: ThemeMode.system,

      // Uzbek is the first UI language; English ships alongside it from day one to prove
      // the plumbing works before a second language is real (ARCHITECTURE.md 4.6).
      locale: const Locale('uz'),
      supportedLocales: const [Locale('uz'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      builder: (context, child) {
        // Clamp text scaling. People legitimately enlarge text, and the layout must
        // accommodate that; beyond this bound the design breaks rather than adapts, and a
        // broken layout is less accessible than a slightly smaller one.
        final scale = MediaQuery.textScalerOf(context).clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.4,
        );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scale),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
