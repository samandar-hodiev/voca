# Voca mobile app — Flutter, feature-based Clean Architecture.
#
# STATUS: structural skeleton only. Every .dart file is a placeholder holding a comment
# that states what belongs in it. There is no logic yet, and android/ and ios/ do not exist
# because `flutter create` generates them.
#
# First implementation step: run `flutter create` over this directory, then fill modules in
# the order given in ARCHITECTURE.md 37.
#
# Layout:
#   lib/core/       shared infrastructure — network, storage, audio, analytics, theme,
#                   localization, DI. Must never import a feature.
#   lib/features/   isolated features, each with data / domain / presentation.
#                   See lib/features/README.md for the layer rules.
#   lib/routing/    GoRouter configuration and guards.
#
# Non-negotiable rules:
#   - NO SECRETS. The app holds no Azure key, no RevenueCat secret key, no database
#     credential — only public client identifiers.
#   - Premium gating in the UI is cosmetic. The backend is the only authority.
#   - No learning content is hardcoded; words come from the API.
#   - domain/ is pure Dart: no flutter, no dio, no JSON.
