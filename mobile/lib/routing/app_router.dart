/// The application router.
///
/// One GoRouter for the whole app (ARCHITECTURE.md 4.4). Routes are declared here and
/// composed from per-feature fragments as features arrive, so adding a feature costs one
/// entry rather than an edit threaded through a large file.
///
/// The screens behind these routes are PLACEHOLDERS. This foundation proves the app
/// starts, the theme resolves and navigation works; the real screens belong to their
/// feature tasks.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/config/flavor.dart';
import '../core/widgets/placeholder_screen.dart';
import '../features/dev/design_system_gallery.dart';
import '../features/auth/presentation/pages/auth_entry_page.dart';
import '../features/auth/presentation/pages/create_profile_page.dart';
import '../features/auth/presentation/pages/email_sign_up_page.dart';
import '../features/auth/presentation/pages/email_verify_page.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/onboarding/presentation/pages/daily_goal_page.dart';
import '../features/onboarding/presentation/pages/goal_page.dart';
import '../features/onboarding/presentation/pages/level_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import 'routes.dart';

abstract final class AppRouter {
  static GoRouter create(AppConfig config) {
    return GoRouter(
      initialLocation: Routes.splash,
      debugLogDiagnostics: config.flavor.isDebugFriendly,
      routes: [
        GoRoute(
          path: Routes.splash,
          name: Routes.splashName,
          builder: (_, __) => const SplashPage(),
        ),
        GoRoute(
          path: Routes.onboarding,
          name: Routes.onboardingName,
          builder: (_, __) => const OnboardingPage(),
        ),
        // First-launch setup.
        GoRoute(
          path: Routes.level,
          name: Routes.levelName,
          builder: (_, __) => const LevelPage(),
        ),
        GoRoute(
          path: Routes.goal,
          name: Routes.goalName,
          builder: (_, __) => const GoalPage(),
        ),
        GoRoute(
          path: Routes.dailyGoal,
          name: Routes.dailyGoalName,
          builder: (_, __) => const DailyGoalPage(),
        ),

        // Authentication.
        GoRoute(
          path: Routes.authEntry,
          name: Routes.authEntryName,
          builder: (_, __) => const AuthEntryPage(),
        ),
        GoRoute(
          path: Routes.emailSignUp,
          name: Routes.emailSignUpName,
          builder: (_, __) => const EmailSignUpPage(),
        ),
        GoRoute(
          path: Routes.emailVerify,
          name: Routes.emailVerifyName,
          builder: (_, __) => const EmailVerifyPage(),
        ),
        GoRoute(
          path: Routes.createProfile,
          name: Routes.createProfileName,
          builder: (_, __) => const CreateProfilePage(),
        ),
        GoRoute(
          path: Routes.login,
          name: Routes.loginName,
          builder: (_, __) => const LoginPage(),
        ),
        GoRoute(
          path: Routes.forgotPassword,
          name: Routes.forgotPasswordName,
          builder: (_, __) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: Routes.forgotVerify,
          name: Routes.forgotVerifyName,
          builder: (_, __) => const ForgotVerifyPage(),
        ),
        GoRoute(
          path: Routes.newPassword,
          name: Routes.newPasswordName,
          builder: (_, __) => const NewPasswordPage(),
        ),

        GoRoute(
          path: Routes.home,
          name: Routes.homeName,
          builder: (_, __) => const PlaceholderScreen(
            title: 'Home',
            description: 'The learner dashboard will be built here.',
            icon: Icons.home_outlined,
          ),
        ),
        GoRoute(
          path: Routes.practice,
          name: Routes.practiceName,
          builder: (_, __) => const PlaceholderScreen(
            title: 'Practice',
            description: 'Word practice and the recording flow will be built here.',
            icon: Icons.mic_none_rounded,
          ),
        ),
        GoRoute(
          path: Routes.progress,
          name: Routes.progressName,
          builder: (_, __) => const PlaceholderScreen(
            title: 'Progress',
            description: 'Streaks, daily progress and weak sounds will be built here.',
            icon: Icons.insights_outlined,
          ),
        ),
        GoRoute(
          path: Routes.profile,
          name: Routes.profileName,
          builder: (_, __) => const PlaceholderScreen(
            title: 'Profile',
            description: 'Account and profile will be built here.',
            icon: Icons.person_outline_rounded,
          ),
        ),
        GoRoute(
          path: Routes.settings,
          name: Routes.settingsName,
          builder: (_, __) => const SettingsPage(),
        ),

        // Development only. The gallery is how the design system is reviewed without a
        // product screen to host it, and it must never ship in a production build.
        if (config.flavor.isDebugFriendly)
          GoRoute(
            path: Routes.designSystem,
            name: Routes.designSystemName,
            builder: (_, __) => const DesignSystemGallery(),
          ),
      ],
      errorBuilder: (context, state) => PlaceholderScreen(
        title: 'Not found',
        description: 'No route matches ${state.uri}.',
        icon: Icons.help_outline_rounded,
      ),
    );
  }
}
