# ADR-001: Flutter for the mobile application

- **Status:** Proposed
- **Date:** 2026-09-09
- **Deciders:** Lead architect
- **Related:** [ADR-006](ADR-006-provider-abstraction.md)

## Context

Voca must ship on iOS and Android at the same time, with a visually rich result screen (score rings,
per-word chips, phoneme breakdown, animations) and reliable microphone recording. The team is small,
and pronunciation feedback UI is where most of the product's design effort will go. Building the
same screen twice, in two languages, on two release cadences, is the single largest avoidable cost
in front of us.

## Decision

Build the mobile app in **Flutter (Dart)**, using feature-based Clean Architecture, Riverpod for
state and dependency injection, and GoRouter for navigation.

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| **React Native** | Viable and popular, but its bridge to native audio and its platform-divergent rendering make pixel-identical, animation-heavy result screens more work. The team has no existing JS/React investment that would offset this |
| **Native Kotlin + Swift** | Best possible audio and platform integration, and the right answer for a large team. For this team it means two codebases, two test suites, two release pipelines, and roughly double the UI effort for a product whose differentiation is not platform-specific |
| **Kotlin Multiplatform** | Shares logic but not UI; we would still build the expensive part twice |
| **Web / PWA first** | Microphone and background behaviour on mobile browsers are poor, and in-app purchase (the revenue model) effectively requires native store integration |

## Rationale

Flutter renders its own UI, so the pronunciation result screen looks and behaves identically on both
platforms with one implementation. Recording, in-app purchase, push, and sign-in all have mature
plugins. Dart's null safety and strong typing suit a layered architecture, and the `domain` layer
stays pure Dart, which makes most of the app testable without a widget tree.

## Consequences

**Positive:** one codebase, one design implementation, one test suite; fast iteration on the
feedback UI; large plugin ecosystem for every platform capability MVP needs.

**Negative:** app binaries are larger than native; some platform features arrive via plugins rather
than first-party APIs; deep audio processing (if we ever do on-device analysis) will need platform
channels; the team must learn Dart if it does not know it.

**Mitigation:** the architecture keeps platform-specific work behind `core/audio` interfaces, so a
future platform channel implementation is a contained change.
