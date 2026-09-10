/// Configuration the client cannot know on its own.
///
/// Sign-in methods depend on credentials that live only on the server, so the app asks
/// which ones actually work rather than guessing. A button that cannot succeed is never
/// offered (ARCHITECTURE.md 25.3).
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';

class Capabilities {
  const Capabilities({this.googleSignIn = false, this.appleSignIn = false});

  final bool googleSignIn;
  final bool appleSignIn;

  factory Capabilities.fromJson(Map<String, dynamic> json) => Capabilities(
        googleSignIn: json['google_sign_in'] as bool? ?? false,
        appleSignIn: json['apple_sign_in'] as bool? ?? false,
      );
}

/// What the server says is available.
///
/// Failure resolves to everything disabled rather than throwing: an unreachable server
/// should leave the screen usable with email and guest, not broken.
final capabilitiesProvider = FutureProvider<Capabilities>((ref) async {
  try {
    final res = await ref
        .watch(dioProvider)
        .get<Map<String, dynamic>>('/api/v1/config');
    final data = res.data?['data'] as Map<String, dynamic>?;
    final caps = data?['capabilities'] as Map<String, dynamic>?;
    return caps == null ? const Capabilities() : Capabilities.fromJson(caps);
  } on DioException {
    return const Capabilities();
  }
});
