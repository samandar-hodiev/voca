/// The composition root.
///
/// Riverpod is both the state layer and the dependency injection container, so each layer
/// is exposed as a provider and tests override the one they need
/// (ARCHITECTURE.md 4.3, 22.2).
///
/// Dependencies flow one way:
///
///     appConfig -> dio -> (data sources) -> (repositories) -> (use cases) -> controllers
///
/// Only the first two links exist in this foundation. The rest arrive with their features.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../network/dio_client.dart';

/// Overridden in [bootstrap] with the flavor's configuration. Reading it without an
/// override is a wiring mistake, so it throws rather than guessing.
final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('appConfigProvider must be overridden in bootstrap');
});

/// Application version reported to the backend. Overridden at bootstrap.
final appVersionProvider = Provider<String>((ref) => '0.1.0');

/// Platform name reported to the backend. Overridden at bootstrap.
final platformProvider = Provider<String>((ref) => 'unknown');

/// The single HTTP client.
final dioProvider = Provider<Dio>((ref) {
  return DioClient.create(
    ref.watch(appConfigProvider),
    appVersion: ref.watch(appVersionProvider),
    platform: ref.watch(platformProvider),
  );
});
