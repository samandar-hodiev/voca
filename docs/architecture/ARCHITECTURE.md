# Voca — Architecture Specification

**Product:** Voca, an AI-powered English pronunciation coach for mobile.
**Status:** Proposed — awaiting review and freeze. No production code is written yet.
**Document owner:** Lead architect.
**Version:** 1.0 (pre-freeze draft)

---

## How to read this document

This document is the single source of truth for Voca's technical design. It is written to be
readable by a developer who is new to Go, while remaining precise enough to build a real
production system from.

The process this document belongs to is:

```
Design (this document)  ->  Review  ->  Freeze  ->  Implement module by module
```

Nothing in `mobile/` or `backend/` should be written until the **Architecture Freeze Checklist**
at the end of this document has been reviewed and approved. Every major decision below states
*why* it was made, because a decision without a reason cannot be revisited safely later.

Two rules govern the whole design:

1. **Anything supplied by a third party is behind an interface we own.** Azure, RevenueCat,
   Firebase, and any future replacement sit behind our own contracts. Business logic never
   imports a vendor SDK type.
2. **Do the simple thing now, but leave the seam.** We ship a modular monolith, no Redis, no
   queue, no Kubernetes. Every place where we expect future pressure gets an explicit boundary
   today so the future change is an *addition*, not a rewrite.

---

## Table of contents

| # | Section |
|---|---------|
| 1 | [Executive Architecture Summary](#1-executive-architecture-summary) |
| 2 | [Product Architecture](#2-product-architecture) |
| 3 | [System Architecture Diagram](#3-system-architecture-diagram) |
| 4 | [Mobile Architecture](#4-mobile-architecture) |
| 5 | [Backend Architecture](#5-backend-architecture) |
| 6 | [Pronunciation Architecture](#6-pronunciation-architecture) |
| 7 | [AI Provider Abstraction](#7-ai-provider-abstraction) |
| 8 | [Authentication Architecture](#8-authentication-architecture) |
| 9 | [Subscription Architecture](#9-subscription-architecture) |
| 10 | [Database Architecture](#10-database-architecture) |
| 11 | [API Architecture](#11-api-architecture) |
| 12 | [Audio Processing Architecture](#12-audio-processing-architecture) |
| 13 | [Practice Architecture](#13-practice-architecture) |
| 14 | [Progress Architecture](#14-progress-architecture) |
| 15 | [Weak Sound Architecture](#15-weak-sound-architecture) |
| 16 | [Analytics Architecture](#16-analytics-architecture) |
| 17 | [Notification Architecture](#17-notification-architecture) |
| 18 | [Security Architecture](#18-security-architecture) |
| 19 | [Error Handling](#19-error-handling) |
| 20 | [Caching](#20-caching) |
| 21 | [Background Jobs](#21-background-jobs) |
| 22 | [Testing Architecture](#22-testing-architecture) |
| 23 | [CI/CD](#23-cicd) |
| 24 | [Deployment Architecture](#24-deployment-architecture) |
| 25 | [Environment Strategy](#25-environment-strategy) |
| 26 | [Complete Repository Structure](#26-complete-repository-structure) |
| 27 | [Flutter Folder Structure](#27-flutter-folder-structure) |
| 28 | [Go Folder Structure](#28-go-folder-structure) |
| 29 | [Database ERD Description](#29-database-erd-description) |
| 30 | [API Endpoint Map](#30-api-endpoint-map) |
| 31 | [Dependency Rules](#31-dependency-rules) |
| 32 | [Architecture Decision Records](#32-architecture-decision-records) |
| 33 | [Scalability Plan](#33-scalability-plan) |
| 34 | [Future Feature Integration Strategy](#34-future-feature-integration-strategy) |
| 35 | [MVP vs Future Components](#35-mvp-vs-future-components) |
| 36 | [Technical Risks](#36-technical-risks) |
| 37 | [Recommended Implementation Order](#37-recommended-implementation-order) |
| — | [Architecture Freeze Checklist](#architecture-freeze-checklist) |

---

## 1. Executive Architecture Summary

Voca is a Flutter mobile client talking over a versioned REST API to a single Go service backed
by PostgreSQL. The Go service is a **modular monolith**: one deployable binary, but internally
split into independent modules (`auth`, `user`, `word`, `practice`, `pronunciation`, `progress`,
`subscription`, `notification`, `analytics`) that communicate only through explicit service
interfaces. Pronunciation assessment is performed by Microsoft Azure Speech, reached through a
`SpeechProvider` interface that our own domain defines and Azure implements.

**Why a monolith.** At MVP, and realistically until well past 10,000 users, a single Go binary
serving a few hundred requests per minute is not a scaling problem. Microservices would add
network hops, distributed transactions, deployment complexity, and debugging pain to solve a
problem we do not have. The modules are drawn along the exact lines we would later cut, so
extraction stays a mechanical operation rather than a redesign.

**Why the provider abstractions matter most.** Voca's core value depends on a third party we do
not control, cannot fully predict the pricing of, and may need to replace. The pronunciation
domain (attempts, scores, phonemes, feedback, weak sounds) is modelled in our own terms; the
Azure response shape stops at the boundary of the Azure adapter. The same discipline applies to
payments (RevenueCat), analytics, and push notifications.

**Why the mobile app is layered.** Each Flutter feature owns a `data`/`domain`/`presentation`
stack. Widgets never call HTTP, never know a JSON key, and never contain a scoring rule. This is
what allows the roadmap features (sentence practice, IELTS mode, conversation coach) to be added
as new folders rather than as edits threaded through existing screens.

**What we deliberately do not build now:** microservices, Kubernetes, Kafka, a job queue, an
object store for audio, a content CMS, or a custom scoring model. Sections 20, 21, 33, and 35
define exactly where each of those plugs in when it is actually needed.

---

## 2. Product Architecture

### 2.1 The core loop

```
Open app -> Get a word -> Hear native pronunciation -> Record own voice
   -> Backend assesses -> See scores + word/phoneme feedback + how to fix
   -> Retry or continue -> Progress, streak, and weak sounds update
```

Everything else in the product is either an input to this loop (content, practice selection),
an output of it (progress, weak sounds, recommendations), or a constraint on it (free usage
limits, premium access).

### 2.2 Actors

| Actor | Description | MVP |
|-------|-------------|-----|
| Free learner | Signed in, limited daily assessments | Yes |
| Premium learner | Active subscription, expanded/unlimited assessments and advanced feedback | Yes |
| System (scheduler) | Runs streak rollover, reminders, aggregation | Minimal in MVP |
| Content editor | Curates words, categories, phonetic data | Via seed scripts in MVP; admin tool later |

### 2.3 Product concepts mapped to code

The most useful thing this document can give a new developer is the map from product language to
module names. Every concept below has exactly one owner.

| Product concept | Backend module | Mobile feature | Owns the data |
|-----------------|----------------|----------------|---------------|
| Who the user is, sign-in | `auth` | `auth` | `users`, refresh tokens |
| Profile, preferences, goals | `user` | `profile`, `settings` | `profiles`, `user_preferences` |
| What to practise (words, categories) | `word` | `practice` (content view) | `words`, `categories` |
| A practice session and its items | `practice` | `practice` | `practice_sessions`, `practice_items` |
| An attempt and its assessment | `pronunciation` | `pronunciation` | `pronunciation_attempts`, `phoneme_results`, `feedback` |
| Streaks, daily progress, improvement | `progress` | `progress` | `daily_progress`, `streaks` |
| Weak sounds and recommendations | `progress` (weak-sound service) | `progress` | derived from `phoneme_results` |
| Entitlement, limits, billing state | `subscription` | `subscription` | `subscriptions`, `subscription_events` |
| Push tokens and reminders | `notification` | `settings` | `devices` |
| Product event tracking | `analytics` | `core/analytics` | none (forwarded) |

### 2.4 Scope boundaries for MVP

- Learning language: **English only**. Interface language: **Uzbek only**. Accent: **en-US only**.
- Practice type: **single words only**. Phrases and sentences are modelled but not exposed.
- Feedback: scores, word-level results, phoneme-level results, and a rule-generated explanation
  of how to produce the problematic sound.
- Monetization: one premium tier via RevenueCat, with a free daily assessment quota.

Every one of these limits is a *configuration or content* limit, not a structural one. Section 34
shows the exact change required to lift each.

---

## 3. System Architecture Diagram

### 3.1 Plain view

```
                        Flutter app (iOS / Android)
                                   |
                         HTTPS, JWT, /api/v1
                                   |
                                   v
                      +------------------------+
                      |   Go API (Gin)         |
                      |   modular monolith     |
                      |                        |
                      |  middleware chain      |
                      |  auth  user  word      |
                      |  practice  pronunciation
                      |  progress  subscription|
                      |  notification analytics|
                      +------------------------+
                       |        |            |
        +--------------+        |            +---------------+
        |                       |                            |
        v                       v                            v
  PostgreSQL             Provider adapters              Redis (optional,
  (managed)              (behind our interfaces)         not in MVP)
                          |    |     |     |
                          |    |     |     +-- AnalyticsProvider  -> PostHog / Firebase
                          |    |     +-------- NotificationProvider -> FCM (+ APNs)
                          |    +-------------- PaymentProvider    -> RevenueCat -> Apple / Google
                          +------------------- SpeechProvider     -> Azure Speech
```

### 3.2 Mermaid view

```mermaid
flowchart TB
    subgraph Client
      FL["Flutter app<br/>iOS + Android"]
    end

    subgraph Edge
      TLS["TLS termination<br/>reverse proxy / platform"]
    end

    subgraph API["Go modular monolith (single binary)"]
      MW["Middleware:<br/>request-id, logging, recovery,<br/>CORS, auth, rate limit"]
      MOD["Modules:<br/>auth · user · word · practice ·<br/>pronunciation · progress ·<br/>subscription · notification · analytics"]
      PORTS["Ports (interfaces we own):<br/>SpeechProvider · PaymentProvider ·<br/>AnalyticsProvider · NotificationProvider ·<br/>CacheStore"]
    end

    subgraph Data
      PG[("PostgreSQL")]
      RD[("Redis — optional,<br/>post-MVP")]
    end

    subgraph External
      AZ["Azure Speech<br/>Pronunciation Assessment"]
      RC["RevenueCat"]
      ST["App Store / Google Play"]
      FB["FCM / APNs"]
      AN["Analytics provider"]
    end

    FL -->|HTTPS /api/v1 + JWT| TLS --> MW --> MOD --> PORTS
    MOD --> PG
    PORTS -.optional.-> RD
    PORTS --> AZ
    PORTS --> RC --> ST
    PORTS --> FB
    PORTS --> AN
    RC -->|webhook| MW
    FL -.purchases via SDK.-> RC
    FL -.client events.-> AN
```

### 3.3 What is deliberately absent

No API gateway, no service mesh, no message broker, no separate worker fleet, no object storage.
Section 33 defines the user-count thresholds at which each of these is reconsidered, so the
absence is a dated decision rather than an oversight.

---

## 4. Mobile Architecture

### 4.1 Approach

Flutter with **feature-based Clean Architecture**. The app is a set of self-contained features;
each feature contains three layers, and dependencies only ever point inward toward `domain`.

```
presentation  ->  domain  <-  data
   (UI)          (rules)     (I/O)
```

`domain` depends on nothing. `presentation` and `data` both depend on `domain`. `presentation`
never imports `data`. This single rule is what makes features testable and replaceable.

### 4.2 What belongs in each layer

**`domain/` — the feature's business meaning. Pure Dart, no Flutter, no JSON, no Dio.**

| Contains | Example in Voca |
|----------|-----------------|
| Entities | `PronunciationResult`, `WordResult`, `PhonemeResult`, `Word`, `Streak` |
| Repository *interfaces* (abstract classes) | `PronunciationRepository`, `WordRepository` |
| Use cases / interactors | `SubmitPronunciationAttempt`, `GetDailyPracticeSet`, `GetWeakSounds` |
| Value objects and enums | `Score`, `PhonemeErrorType`, `PracticeType`, `CefrLevel` |
| Failure types | `NetworkFailure`, `UsageLimitReachedFailure`, `PremiumRequiredFailure` |

A `domain` file that imports `package:flutter/...`, `dio`, or `json_serializable` is a bug.

**`data/` — how the domain's needs are actually satisfied.**

| Contains | Example |
|----------|---------|
| DTO models with JSON mapping | `PronunciationResultDto` with `fromJson` and `toDomain()` |
| Remote data sources | `PronunciationRemoteDataSource` (Dio calls to `/api/v1/...`) |
| Local data sources | `WordLocalDataSource` (cached word list), `AuthLocalDataSource` (secure storage) |
| Repository *implementations* | `PronunciationRepositoryImpl implements PronunciationRepository` |
| Mappers | DTO -> entity, and error/status-code -> `Failure` |

DTOs are separate types from entities on purpose. When the API adds, renames, or nests a field,
only the DTO and its mapper change; the entity, use cases, and every widget stay untouched.

**`presentation/` — everything the user sees and every piece of screen state.**

| Contains | Example |
|----------|---------|
| Pages / screens | `PracticeScreen`, `PronunciationResultScreen` |
| Widgets local to the feature | `ScoreRing`, `PhonemeChip`, `RecordButton` |
| Riverpod controllers / notifiers | `PronunciationController extends AsyncNotifier<...>` |
| UI state models | `PracticeUiState` (loading, recording, assessing, result, error) |

A widget calls a controller. A controller calls a use case. A use case calls a repository
interface. Nothing skips a step.

### 4.3 State management: Riverpod

- Riverpod providers are the app's dependency injection container as well as its state layer.
- Each layer is exposed as a provider: `dioProvider` -> `pronunciationRemoteDataSourceProvider`
  -> `pronunciationRepositoryProvider` -> `submitAttemptUseCaseProvider` ->
  `pronunciationControllerProvider`.
- Because every dependency is a provider, tests override the repository provider with a fake and
  the whole widget tree runs without a network.
- Async work uses `AsyncNotifier` / `AsyncValue` so loading, data, and error are explicit states
  rather than ad-hoc booleans — important for the assessment screen, which has a genuinely long
  in-flight period.

### 4.4 Navigation: GoRouter

- Routes are declared centrally in `lib/routing/`, composed from per-feature route fragments so
  adding a feature does not require editing a giant file beyond one line.
- Deep links (`voca://practice/daily`, notification taps, subscription return) are first-class,
  which matters for push reminders in section 17.
- **Redirect guards** enforce two conditions: `authGuard` (signed in) and `premiumGuard` (UI-level
  gating only). The premium guard is a UX convenience; the authoritative check is always the
  backend (section 9).

### 4.5 Networking, storage, and offline behaviour

| Concern | Decision | Why |
|---------|----------|-----|
| HTTP client | Dio with interceptors | Interceptors give one place for auth headers, refresh-on-401, request IDs, retries, and logging |
| Auth token storage | `flutter_secure_storage` (Keychain / Keystore) | Tokens must never sit in `SharedPreferences` or plain files |
| Cache / non-secret persistence | Drift or Isar for structured cache; `shared_preferences` for flags | Word lists and last-known progress should survive an offline launch |
| Audio recording | `record` package writing to a temp file | Local file, uploaded once, deleted after upload |
| Offline policy | Browse cached words and view cached progress offline; assessment requires connectivity | Assessment inherently needs the server; a clear "needs internet" state beats a silent failure |
| Secrets | **None in the app** | The app holds no Azure key, no RevenueCat secret key, no DB credential. Only public client identifiers (Google/Apple client IDs, RevenueCat *public* SDK key, Firebase config) |

### 4.6 Localization and theming

- All user-visible strings live in ARB files under `core/localization` (`app_uz.arb` first,
  `app_en.arb` alongside it from day one to prove the plumbing).
- **Server-generated feedback text is localized by key, not by sentence.** The backend returns a
  `message_key` plus parameters; the app renders the Uzbek string. This is what makes a second
  interface language a translation task rather than a backend change (section 34).
- Theming is centralized in `core/theme` with design tokens, so a visual redesign is one folder.

### 4.7 Feature list

MVP features: `auth`, `home`, `practice`, `pronunciation`, `progress`, `subscription`, `profile`,
`settings`.

Roadmap features slot in as sibling folders with no changes to existing ones: `sentence_practice`,
`conversation`, `ielts`, `challenges`, `weak_sound_training`, `daily_challenge`, `leaderboard`,
`achievements`, `notifications`.

---

## 5. Backend Architecture

### 5.1 Shape

One Go binary, built with Gin, organized as a modular monolith. Each module is a Go package under
`internal/` and owns its own handlers, service, repository, domain models, and DTOs.

### 5.2 Request flow

```
HTTP request
  -> Middleware   (request ID, logger, recovery, CORS, rate limit, auth, entitlement)
  -> Handler      (bind + validate DTO, call service, map result/error to HTTP)
  -> Service      (all business rules, orchestration, transactions)
  -> Repository / Provider   (interfaces owned by the module)
  -> Infrastructure          (pgx/sqlc against PostgreSQL, HTTP calls to Azure/RevenueCat)
  -> Response     (standard envelope, section 19)
```

### 5.3 Responsibilities, stated as rules

**Handler (thin, no exceptions).** Decode request, validate shape, extract the authenticated user
from context, call exactly one service method, translate the returned domain error into an HTTP
status plus error code, encode the response. A handler contains no SQL, no provider call, no
business branch such as "if user is premium".

**Service (where the product lives).** Business rules, permission checks beyond authentication,
usage-limit enforcement, orchestration across repositories and providers, transaction boundaries,
domain event emission. A service depends only on interfaces, never on `*gin.Context`, never on
`*sql.DB`, and never on an Azure or RevenueCat type.

**Repository (data access only).** Implements an interface defined next to the service it serves.
Translates between database rows and domain models. Contains no business rules.

**Provider adapter (external world only).** Implements a port interface (`SpeechProvider`,
`PaymentProvider`, ...). Owns the vendor SDK/HTTP details, retries, timeouts, and the mapping from
vendor payload to our domain model. Nothing outside the adapter package knows the vendor exists.

### 5.4 Module anatomy

Every module has the same internal shape, which makes the codebase predictable:

```
internal/<module>/
  handler.go      HTTP layer (thin)
  routes.go       route registration for this module
  service.go      business logic (the module's public behaviour)
  repository.go   interface + PostgreSQL implementation
  model.go        domain entities for this module
  dto.go          request/response shapes for this module's HTTP API
  port.go         interfaces for external providers this module needs
  service_test.go / repository_test.go / handler_test.go
```

Larger modules (`pronunciation`) split these into subpackages; the layer names stay identical.

### 5.5 Cross-module rules

This is the discipline that keeps future extraction cheap:

1. A module may call another module **only through that module's exported service interface**,
   injected at wiring time in `internal/server`.
2. A module **never** imports another module's repository, SQL, or database models.
3. A module **never** reads or writes another module's tables directly. `pronunciation` does not
   `SELECT` from `subscriptions`; it asks `subscription.Service.GetEntitlement(ctx, userID)`.
4. Shared cross-cutting concerns live in `internal/shared` (errors, response envelope, validation,
   pagination) and `pkg/` (logger, JWT helpers) — never in a business module.
5. Circular dependencies are forbidden. If two modules need each other, the shared concept belongs
   in a third place or the call becomes an event (section 21).

Practical consequence: on the day `pronunciation` becomes its own service, its calls to
`subscription.Service` are already the only coupling, and they become HTTP or gRPC calls behind
the same interface. Nothing else in the module changes.

### 5.6 Technology choices inside the backend

| Concern | Choice | Why |
|---------|--------|-----|
| HTTP framework | Gin | Mature, fast, tiny API surface; middleware model matches our chain |
| DB driver | pgx (via `pgxpool`) | Native PostgreSQL protocol, better performance and types than `database/sql` |
| Query layer | sqlc | Generates type-safe Go from plain SQL. Beginner-friendly (you write real SQL), no ORM magic, compile-time safety |
| Migrations | golang-migrate (or goose) | Plain, versioned, up/down SQL files; runs in CI and on deploy |
| Config | envconfig-style struct loaded from environment | Twelve-factor; no config files with secrets in the repo |
| Logging | `log/slog` (stdlib) with JSON handler | Structured, no dependency, good enough at our scale |
| Validation | `go-playground/validator` on DTOs | Declarative request validation in the handler layer only |
| Errors | Custom `AppError` type in `internal/shared/apperr` | One mapping from domain error to HTTP status + client error code |
| Testing | stdlib `testing` + `testify` assertions + generated mocks | Standard, low ceremony |

### 5.7 Wiring

`internal/server` is the only place that knows the full object graph. It constructs the pgx pool,
builds each repository, injects repositories and provider adapters into services, injects services
into handlers, registers routes, and installs middleware. Everything else receives its
dependencies. This is manual constructor injection — no DI framework, because a monolith with
about ten modules does not need one, and explicit wiring is far easier for a new developer to read.

---

## 6. Pronunciation Architecture

This is the most important feature in the product and the one most exposed to third-party risk.
It gets the strictest separation.

### 6.1 End-to-end pipeline

```
Flutter: record audio (constrained format, duration, size)
   |
   v
POST /api/v1/pronunciation/attempts   (multipart: audio + reference)
   |
   v
Middleware: request ID -> logging -> recovery -> auth (JWT) -> rate limit
   |
   v
Handler: bind + validate DTO, no logic
   |
   v
PronunciationService
   |-- 1. Authorization: does this user own the practice item?
   |-- 2. Entitlement + usage limit: subscription.Service + UsageLimiter
   |-- 3. Audio validation: MIME, size, duration, sample rate
   |-- 4. Assess via SpeechProvider (interface)
   |         |
   |         v
   |     Azure adapter: HTTP/SDK call -> raw Azure JSON -> azureMapper -> domain result
   |         (raw response never leaves this package)
   |-- 5. ScoringEngine: normalize/verify/derive our scores from the provider signal
   |-- 6. AnalysisEngine: detect PronunciationError set from word + phoneme results
   |-- 7. FeedbackEngine: turn errors into Feedback (message keys + articulation tips + examples)
   |-- 8. Persist: attempt, phoneme results, feedback (one transaction)
   |-- 9. Emit: progress update + analytics event (non-blocking, best effort)
   |
   v
API response: our own PronunciationResult DTO
   |
   v
Flutter result screen: scores, per-word chips, phoneme breakdown, fix-it tips, retry
```

Mermaid form:

```mermaid
sequenceDiagram
    participant App as Flutter
    participant MW as Middleware
    participant H as Handler
    participant S as PronunciationService
    participant Sub as subscription.Service
    participant P as SpeechProvider (port)
    participant AZ as Azure adapter
    participant E as Scoring/Analysis/Feedback engines
    participant DB as PostgreSQL

    App->>MW: POST /api/v1/pronunciation/attempts (audio + item)
    MW->>H: authenticated request (+ request ID)
    H->>S: SubmitAttempt(cmd)
    S->>Sub: GetEntitlement(userID)
    Sub-->>S: free | premium
    S->>S: usage limit check + audio validation
    S->>P: Assess(ctx, AssessmentInput)
    P->>AZ: vendor call
    AZ->>AZ: raw JSON -> mapper -> domain model
    AZ-->>S: AssessmentOutput (our types)
    S->>E: score -> analyse -> generate feedback
    E-->>S: PronunciationResult + Feedback
    S->>DB: persist attempt, phonemes, feedback (tx)
    S-->>H: PronunciationResult
    H-->>App: 200 + our DTO
```

### 6.2 The seven separated concerns

The pipeline is deliberately split so each piece can change independently:

| # | Concern | Package | Changes when... |
|---|---------|---------|-----------------|
| 1 | Provider integration | `internal/integrations/speech/azure` | Azure API/SDK changes, or we add Google |
| 2 | Provider response mapping | `.../azure/mapper.go` (private) | Azure's payload shape changes |
| 3 | Scoring | `internal/pronunciation/scoring` | We change how a score is computed or weighted |
| 4 | Phoneme analysis | `internal/pronunciation/analysis` | We change how errors are detected/classified |
| 5 | Feedback generation | `internal/pronunciation/feedback` | We improve coaching text or add tips |
| 6 | Learning recommendation | `internal/progress/recommendation` | We improve what to practise next |
| 7 | Persistence | `internal/pronunciation/repository.go` | Storage/schema changes |

A change to coaching wording must not require touching the Azure adapter. A switch to Google must
not require touching scoring. That is the test of whether this split is being respected.

### 6.3 Pronunciation domain model

These are *our* entities, designed around the product, not copied from any vendor payload.

**`PronunciationAttempt`** — one recording submitted for one reference text.

| Field | Notes |
|-------|-------|
| `ID` | UUID |
| `UserID`, `PracticeItemID` | ownership and context |
| `ReferenceText` | what the user was asked to say (denormalized on purpose; content may change later) |
| `AttemptNumber` | 1, 2, 3... for retries on the same item |
| `AudioDurationMs`, `AudioFormat` | for validation, analytics, and debugging |
| `Status` | `completed` \| `failed` \| `rejected` |
| `Result` | `PronunciationResult` (nil when failed) |
| `ProviderName`, `ProviderLatencyMs` | which assessment engine produced this signal, and how slow it was |
| `CreatedAt` | |

**`PronunciationResult`** — the assessment outcome.

| Field | Notes |
|-------|-------|
| `OverallScore` | 0–100, our number (section 6.4) |
| `AccuracyScore`, `FluencyScore`, `CompletenessScore` | 0–100 |
| `ProsodyScore` | optional; present only if the provider supplies it |
| `Words` | `[]WordResult` |
| `Confidence` | how much we trust this signal (short audio, low SNR, provider warning -> lower) |

**`WordResult`**: `Word`, `Score`, `ErrorType`, `Phonemes []PhonemeResult`, `Offset/DurationMs`.

**`PhonemeResult`**: `Phoneme` (IPA, e.g. `θ`), `DisplayLabel` (e.g. `TH`), `Score`, `ErrorType`,
`WordIndex`.

**`PronunciationError`** — a *derived* diagnosis, not a vendor field:
`Type` (`mispronunciation` \| `omission` \| `insertion` \| `unexpected_break` \| `missing_break` \|
`monotone`), `Word`, `Phoneme`, `Severity` (`minor` \| `moderate` \| `severe`).

**`Feedback`** — what the learner is actually shown:
`ID`, `AttemptID`, `RelatedWord`, `RelatedPhoneme`, `MessageKey`, `Params`, `ArticulationTipKey`,
`ExampleWords []string`, `Priority`.

**`LearningRecommendation`** — computed, not stored in MVP:
`UserID`, `WeakSounds []WeakSound`, `RecommendedWordIDs`, `GeneratedAt`.

Note two deliberate choices. First, feedback carries **keys, not sentences**, so the Uzbek text
lives in the app's ARB files and a second UI language costs nothing on the backend. Second,
`LearningRecommendation` is derived on demand from `phoneme_results`; we do not create a table for
data we can compute, until query cost says otherwise.

### 6.4 Score system

**Principle: the provider gives us a signal, not the truth.** Azure returns numbers computed by a
model we do not control, tuned on speakers who may not resemble Uzbek learners of English, on
audio captured by phone microphones of wildly varying quality. Treating those numbers as ground
truth would make our product's core metric un-ownable.

So the `ScoringEngine` sits between the provider and everything else, and it is where scoring
policy lives:

```
provider signal  ->  ScoringEngine  ->  Voca scores (what we store and show)
```

MVP scoring policy (intentionally simple, and versioned):

| Score | MVP rule |
|-------|----------|
| Accuracy | Provider accuracy, passed through |
| Fluency | Provider fluency, passed through |
| Completeness | Provider completeness, passed through |
| Overall | Weighted blend: `0.5·accuracy + 0.3·fluency + 0.2·completeness`, clamped 0–100 |
| Confidence | Reduced for very short audio, detected clipping/silence, or provider warnings |
| Improvement | `current.Overall − best_previous.Overall` for the same word; also tracked as a rolling per-word trend |

Design rules that keep this evolvable:

1. Every stored attempt records `scoring_version`. When the formula changes, old rows remain
   interpretable and can be recomputed rather than silently reinterpreted.
2. Weights come from configuration, not from constants scattered in code.
3. The engine takes normalized inputs and returns our scores, so a future custom or hybrid model
   (for example, calibrating for L1-Uzbek speakers) is a new implementation behind the same call.
4. Displayed bands (`needs work` / `good` / `excellent`) are defined once, server-side, so app and
   backend never disagree about what "good" means.

### 6.5 Reliability of the assessment call

| Concern | Decision |
|---------|----------|
| Timeout | Hard per-request budget (about 10 s) on the provider call, with `context` cancellation |
| Retry | At most one retry, only for transient network/5xx, never for a 4xx |
| Failure behaviour | Attempt persisted with `status = failed`; user sees a retry prompt; **the attempt does not consume the free quota** |
| Circuit breaking | Deferred; a failure-rate counter and provider latency metric are recorded from day one so we know when it becomes necessary |
| Idempotency | Client sends an `Idempotency-Key`; a repeated submit of the same recording returns the original result instead of double-charging quota and provider cost |

---

## 7. AI Provider Abstraction

### 7.1 The port

Defined by the pronunciation module — the consumer owns the interface, not the vendor:

```
package pronunciation

type SpeechProvider interface {
    Name() string
    AssessPronunciation(ctx context.Context, in AssessmentInput) (AssessmentOutput, error)
}
```

`AssessmentInput` carries: audio bytes or reader, audio format descriptor, reference text,
learning language (`en`), accent (`en-US`), granularity (`word` \| `phoneme`), and an optional
user-locale hint. `AssessmentOutput` carries our `PronunciationResult` plus provider metadata
(`ProviderName`, `LatencyMs`, `RawWarnings`).

Two things are true of this signature and must stay true:

- It contains **no Azure type, no Azure enum, and no Azure field name**.
- It describes what the *product* needs, so a second provider can satisfy it without contortion.

### 7.2 Adapter structure

```
internal/integrations/speech/
  provider.go          # the shared adapter contract + registry/factory
  azure/
    client.go          # HTTP/SDK calls, auth, timeouts, retries
    response.go        # private structs mirroring Azure's JSON exactly
    mapper.go          # private: Azure response -> pronunciation domain model
    provider.go        # implements pronunciation.SpeechProvider
    mapper_test.go     # golden-file tests: recorded Azure payloads -> expected domain output
  google/              # future, same shape
  mock/
    provider.go        # deterministic fake used by tests and local development
```

The `response.go` structs are unexported. This is enforced by Go's own visibility rules: no other
package *can* refer to an Azure field, so the coupling cannot leak by accident.

### 7.3 Selecting a provider

The provider is chosen at startup from configuration (`SPEECH_PROVIDER=azure|google|mock`) and
injected into `PronunciationService`. Consequences:

- Local development and CI run against `mock` with no Azure key and no cost.
- A provider swap is a configuration change plus a new adapter package — zero changes in service,
  scoring, feedback, persistence, API, or the Flutter app.
- Running two providers in parallel for comparison later is a decorator implementing the same
  interface, not a redesign.

### 7.4 Mapping rules (the part that protects the domain)

| Rule | Reason |
|------|--------|
| Map every vendor field explicitly; never embed raw JSON in the domain | Prevents vendor shape from becoming our shape by accident |
| Normalize phonemes to IPA plus a display label | Vendors differ (SAPI, ARPAbet, IPA); our weak-sound data must be comparable across providers and across time |
| Unknown/absent vendor fields map to explicit optionals | A provider without prosody must not produce a fake prosody score |
| Vendor errors map to our `apperr` taxonomy | Handlers never see a vendor error type |
| Golden tests on recorded payloads | Mapping regressions are caught by CI, not by users |

### 7.5 The same pattern elsewhere

`PaymentProvider` (section 9), `AnalyticsProvider` (section 16), `NotificationProvider`
(section 17), and `CacheStore` (section 20) all follow this exact structure: port owned by the
consuming module, adapter in `internal/integrations/...`, vendor types unexported, mock
implementation shipped alongside. Learn it once, apply it five times.

---

## 8. Authentication Architecture

### 8.1 Sign-in methods

MVP: **Sign in with Apple** and **Google Sign-In**. Email/password is designed for but not built.

Flow: the app performs the native sign-in and receives an identity token from Apple/Google. It
sends that token to our backend. The backend **verifies the token against the provider's public
keys** (issuer, audience, expiry, signature, nonce), finds or creates the user, and issues Voca's
own tokens. The app never trusts its own local claim of identity, and the backend never trusts an
unverified token.

### 8.2 Token model

| Token | Type | Lifetime | Storage | Purpose |
|-------|------|----------|---------|---------|
| Access token | JWT, HS256 | ~15 minutes | Device secure storage (Keychain/Keystore) | Sent as `Authorization: Bearer` on every call |
| Refresh token | Opaque random string, stored **hashed** server-side | ~60 days, rotated on each use | Device secure storage | Obtains a new access token |

Reasoning:

- **Short access tokens** limit the damage of a leaked token, without forcing frequent sign-ins.
- **Opaque refresh tokens** are revocable. A JWT refresh token cannot be invalidated before expiry
  without exactly the server-side store we would be trying to avoid.
- **Rotation with reuse detection**: using an already-consumed refresh token invalidates the whole
  family and forces re-authentication, which is the standard defence against token theft.
- **HS256 now, RS256 later.** With one service issuing and verifying, a shared secret is simpler.
  When a second service must verify tokens independently, we move to asymmetric keys; the mobile
  client is unaffected because it never inspects the signature. The verification path is behind a
  `TokenVerifier` interface so this is a contained change.

Access token claims are minimal: `sub` (user ID), `iat`, `exp`, `jti`, `token_version`.
**Entitlement is deliberately not a claim** — see section 9.4.

### 8.3 Session lifecycle in the app

- Dio interceptor attaches the access token; on `401` with code `TOKEN_EXPIRED` it performs a
  single refresh, retries the original request once, and queues concurrent requests during refresh
  so a burst does not trigger several refreshes.
- Refresh failure clears secure storage and routes to sign-in via the GoRouter auth guard.
- Sign-out revokes the refresh token server-side and clears local storage and caches.

### 8.4 User and profile model

Identity is split across three tables for a reason:

| Table | Holds | Why separate |
|-------|-------|--------------|
| `users` | Identity and credentials: auth provider, external subject ID, email, status | Security-sensitive, rarely read for display, subject to deletion law |
| `profiles` | Display name, avatar, native language | Display data, frequently read, safe to expose to other users if social features arrive |
| `user_preferences` | UI language, learning language, accent, difficulty, daily goal, notification opt-ins | Changes often, read on nearly every session, expands with every new setting |

Splitting them means a future "public profile" feature never risks exposing an identity row, and
adding a preference never touches the identity table.

Learning preferences (`learning_language = en`, `accent = en-US`, `difficulty`, `daily_goal`) exist
as columns from day one even though only one value is currently possible. This is cheap now and
removes a schema migration plus a data backfill later.

### 8.5 Authorization

Two distinct checks, never conflated:

1. **Authentication** (`RequireAuth` middleware): valid access token -> user ID in request context.
2. **Resource ownership** (service layer): the service verifies that the practice item, attempt, or
   progress row belongs to the caller. Never inferred from the URL. `GET /attempts/{id}` for
   someone else's attempt returns `404`, not `403`, so IDs cannot be probed.

Account deletion (`DELETE /api/v1/users/me`) is required by both stores: it revokes all tokens,
soft-deletes the user, anonymizes profile data, and schedules hard deletion of personal rows after
a short retention window, while retaining anonymized aggregate counters.

---

## 9. Subscription Architecture

### 9.1 Model

Two tiers: **free** (daily assessment quota, core feedback) and **premium** (expanded or unlimited
assessments plus advanced features). Billing runs through Apple's and Google's stores because
in-app purchase of digital goods must; **RevenueCat** sits in front of both.

### 9.2 Why RevenueCat

Receipt validation, renewal state machines, grace periods, billing retries, refunds, upgrades,
proration, family sharing, and store-specific webhook quirks are a large amount of work that is
pure risk and no product differentiation. RevenueCat normalizes Apple and Google into one model
and one webhook. We still keep it behind our own `PaymentProvider` interface, because our
*entitlement* concept must outlive any particular vendor.

### 9.3 Responsibilities

| Component | Responsibility |
|-----------|----------------|
| Flutter + RevenueCat SDK | Show offerings, run the native purchase and restore flows, identify the customer using **our** user ID |
| RevenueCat | Validate receipts with Apple/Google, maintain subscription lifecycle, send webhooks |
| Backend `subscription` module | Consume webhooks, persist entitlement state, expose entitlement, enforce limits |
| Backend everywhere else | Ask `subscription.Service` for entitlement; never inspect a store, receipt, or RevenueCat payload |

### 9.4 The backend is the source of truth

The mobile app's local entitlement is a **UI hint only**. Every premium-gated action is authorized
server-side against `subscriptions`, because a client can be patched, replayed, or run on a rooted
device.

Entitlement is *not* placed in the JWT. A 15-minute-old claim would let a cancelled or refunded
subscription keep working, and would let a fresh purchase feel broken until the token refreshed.
Instead the entitlement lookup is a cheap indexed read (later a short-TTL cache, section 20), and
it is always current.

Enforcement points:

- `RequirePremium` middleware for wholly premium endpoints.
- `UsageLimiter` inside `PronunciationService` for quota-limited actions — the check happens
  *before* the provider call, so a blocked request costs no Azure money.
- Limits are configuration (`FREE_DAILY_ASSESSMENT_LIMIT`), not literals scattered in code, so
  pricing experiments do not require a release.

### 9.5 Webhooks and state

`POST /api/v1/subscriptions/webhooks/revenuecat` is unauthenticated by JWT but **verified by a
shared secret / signature header**, rejecting anything unverified before parsing. Then:

1. Append the raw payload to `subscription_events` (append-only audit log; invaluable for billing
   disputes and for replaying after a bug).
2. Map the vendor event to our own status machine.
3. Upsert the current state in `subscriptions`.
4. Emit a server-side analytics event (trusted, unlike client-reported purchases).

Our status model, independent of any store: `trialing`, `active`, `grace_period`, `cancelled`
(still entitled until period end), `expired`, `refunded`.

Webhook handling is **idempotent** — events can arrive twice or out of order, so each event has a
provider event ID with a unique constraint, and state transitions are applied by event timestamp.

A reconciliation job (post-MVP, section 21) periodically re-syncs active subscribers from the
provider to heal any missed webhook.

### 9.6 The port

```
type PaymentProvider interface {
    Name() string
    GetCustomerEntitlement(ctx context.Context, appUserID string) (Entitlement, error)
    ParseWebhook(ctx context.Context, headers map[string]string, body []byte) (WebhookEvent, error)
}
```

`Entitlement` and `WebhookEvent` are our types. Apple, Google, and RevenueCat vocabulary stops at
the adapter boundary, which is what keeps a future move to direct StoreKit/Play Billing, or to a
web/Stripe tier for a desktop product, from touching business logic.

---

## 10. Database Architecture

PostgreSQL, one database, one schema for MVP. Conventions applied to every table:

- **Primary keys**: UUID (`uuid_generate_v7()`-style time-ordered UUIDs preferred, else v4) so IDs
  can be generated client-side of the DB, are non-enumerable in URLs, and merge cleanly if data is
  ever split across services.
- **Timestamps**: `created_at timestamptz NOT NULL DEFAULT now()`, `updated_at timestamptz` on
  mutable tables. All times are UTC; day-boundary logic uses the user's timezone explicitly.
- **Soft delete**: only where it earns its place — `users` (legal/recovery window) and `words`
  (`is_active`, so removing content never orphans historical attempts). Everything else is hard
  deleted or cascades.
- **Money/score types**: scores are `numeric(5,2)` (exact, comparable) rather than floats.
- **Enums**: PostgreSQL `text` columns with `CHECK` constraints rather than native enum types,
  because adding a value to a native enum is a migration with locking implications, while adding a
  value to a check constraint is trivial. This matters — we *will* add practice types and statuses.

### 10.1 Identity

**`users`** — one row per person.

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid PK | |
| `auth_provider` | text NOT NULL | `apple` \| `google` \| `email` (future) |
| `external_auth_id` | text | Provider subject (`sub`). Null only for future email auth |
| `email` | citext | Nullable: Apple private relay or hidden email |
| `email_verified` | bool NOT NULL default false | |
| `password_hash` | text NULL | Reserved for future email auth (Argon2id). Never populated in MVP |
| `status` | text NOT NULL | `active` \| `deleted` |
| `last_login_at` | timestamptz | |
| `created_at`, `updated_at`, `deleted_at` | timestamptz | Soft delete |

Constraints/indexes: `UNIQUE (auth_provider, external_auth_id)` — the real identity key;
`UNIQUE (email) WHERE deleted_at IS NULL AND email IS NOT NULL`; index on `status`.

**`profiles`** — display identity. `id` PK, `user_id` uuid UNIQUE NOT NULL FK -> `users(id)`
ON DELETE CASCADE, `display_name` text, `avatar_url` text, `native_language` text NOT NULL
default `uz`, timestamps. One-to-one with `users`.

**`user_preferences`** — learning and app settings. `id` PK, `user_id` uuid UNIQUE NOT NULL FK
CASCADE, `ui_language` text NOT NULL default `uz`, `learning_language` text NOT NULL default `en`,
`accent` text NOT NULL default `en-US`, `difficulty_level` text NOT NULL default `beginner`
(CHECK in `beginner|intermediate|advanced`), `daily_goal` int NOT NULL default 10,
`timezone` text NOT NULL default `Asia/Tashkent`, `reminder_enabled` bool default true,
`reminder_time` time, `streak_reminder_enabled` bool default true, timestamps.

`timezone` is not optional detail: streaks and daily goals are meaningless without knowing when the
user's day ends.

### 10.2 Content

**`categories`** — `id` PK, `slug` text UNIQUE NOT NULL, `name_key` text NOT NULL (i18n key),
`description_key` text, `icon` text, `sort_order` int NOT NULL default 0, `is_active` bool NOT NULL
default true, timestamps.

**`words`** — the MVP practice unit.

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid PK | |
| `text` | text NOT NULL | The word itself |
| `language` | text NOT NULL default `en` | Future: other learning languages |
| `accent` | text NOT NULL default `en-US` | Future: en-GB, en-AU variants |
| `phonetic_ipa` | text | e.g. `θɪŋk` |
| `phonetic_respelling` | text | Learner-friendly form |
| `target_phonemes` | text[] | Phonemes this word exercises — powers weak-sound practice (section 15) |
| `audio_url` | text | Reference pronunciation, served from CDN/storage |
| `category_id` | uuid FK -> `categories(id)` | Many words to one category |
| `difficulty_level` | text NOT NULL | `beginner` \| `intermediate` \| `advanced` |
| `cefr_level` | text | `A1`..`C2` |
| `part_of_speech` | text | |
| `meaning_uz` | text | Translation for the first UI language |
| `example_sentence` | text | |
| `frequency_rank` | int | Enables "common words first" ordering |
| `is_active` | bool NOT NULL default true | Soft-disable without orphaning attempts |
| `created_at`, `updated_at` | timestamptz | |

Indexes: `(language, accent, is_active)`, `(category_id)`, `(difficulty_level)`, `(cefr_level)`,
GIN on `target_phonemes`, and a trigram or `lower(text)` index for search.
`UNIQUE (text, language, accent)` prevents duplicate content.

**Content is never hardcoded in Flutter.** Words come from the API and are cached locally. Meanings
and example sentences are per-language columns now; when a third language arrives they move to a
`word_translations` table (section 34) — a contained migration, because the app already reads them
through a repository.

### 10.3 Practice

**`practice_sessions`** — `id` PK, `user_id` FK CASCADE, `session_type` text NOT NULL
(`daily|random|targeted|weak_sound|category`), `content_type` text NOT NULL default `word`
(`word|phrase|sentence` — the seam for future practice types), `status` text NOT NULL
(`in_progress|completed|abandoned`), `item_count` int NOT NULL, `completed_item_count` int NOT NULL
default 0, `average_score` numeric(5,2), `started_at` timestamptz NOT NULL, `completed_at`
timestamptz, `created_at`.
Indexes: `(user_id, started_at DESC)`, `(user_id, status)`.

**`practice_items`** — `id` PK, `session_id` FK CASCADE, `word_id` FK -> `words(id)` RESTRICT,
`position` int NOT NULL, `status` text NOT NULL (`pending|attempted|completed|skipped`),
`best_attempt_id` uuid NULL FK -> `pronunciation_attempts(id)`, `attempt_count` int NOT NULL
default 0, `created_at`, `updated_at`.
Constraints: `UNIQUE (session_id, position)`; index `(session_id)`, `(word_id)`.

`best_attempt_id` is a deliberate denormalization: the result screen and progress views ask "how
did this item end up?" constantly, and recomputing a max across attempts each time is wasteful.

### 10.4 Assessment

**`pronunciation_attempts`** — the central record of the product.

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid PK | |
| `user_id` | uuid NOT NULL FK CASCADE | Denormalized from the session for fast per-user queries |
| `practice_item_id` | uuid NULL FK -> `practice_items(id)` | Null allows a future free-form "practise any word" flow |
| `word_id` | uuid NULL FK -> `words(id)` | Direct link for per-word history |
| `reference_text` | text NOT NULL | Snapshot of what was asked |
| `attempt_number` | int NOT NULL default 1 | |
| `status` | text NOT NULL | `completed` \| `failed` \| `rejected` |
| `overall_score`, `accuracy_score`, `fluency_score`, `completeness_score`, `prosody_score` | numeric(5,2) NULL | Null when failed |
| `confidence` | numeric(5,2) | Our trust in this signal |
| `word_results` | jsonb | Word-level breakdown; queried as a whole, never filtered field-by-field |
| `audio_duration_ms` | int | |
| `audio_format` | text | |
| `provider_name` | text NOT NULL | `azure`, later `google` |
| `provider_latency_ms` | int | Feeds the latency metric in section 18 |
| `scoring_version` | text NOT NULL | Which scoring policy produced these numbers |
| `error_code` | text NULL | Why it failed, when it failed |
| `created_at` | timestamptz | |

Indexes: `(user_id, created_at DESC)`, `(practice_item_id)`, `(user_id, word_id, created_at DESC)`,
and `(user_id, created_at)` supporting the daily quota count.

Word-level detail is JSONB rather than a table because it is always read as a whole with its
attempt and never aggregated across users. Phoneme detail is a real table because it *is*
aggregated across attempts — that asymmetry is the whole reason for the split, and it is the
answer to "why not normalize everything".

**`phoneme_results`** — the data that makes weak-sound detection possible.

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid PK | |
| `attempt_id` | uuid NOT NULL FK CASCADE | |
| `user_id` | uuid NOT NULL FK CASCADE | **Denormalized on purpose** — every weak-sound query filters by user |
| `phoneme` | text NOT NULL | IPA, normalized across providers |
| `display_label` | text | e.g. `TH` |
| `word` | text NOT NULL | Which word it occurred in |
| `word_index` | int NOT NULL | |
| `score` | numeric(5,2) NOT NULL | |
| `error_type` | text NOT NULL | `none|mispronunciation|omission|insertion` |
| `created_at` | timestamptz NOT NULL | |

Indexes: `(user_id, phoneme, created_at DESC)` — the weak-sound aggregation index; `(attempt_id)`.

**`feedback`** — coaching shown for an attempt. `id` PK, `attempt_id` FK CASCADE, `type` text
(`sound_tip|word_tip|encouragement|recommendation`), `related_word` text NULL, `related_phoneme`
text NULL, `message_key` text NOT NULL, `params` jsonb, `example_words` text[], `priority` int NOT
NULL default 0, `created_at`. Index `(attempt_id)`.

Storing feedback rather than regenerating it means the user's history does not change retroactively
when we improve the feedback rules.

### 10.5 Progress

**`daily_progress`** — one row per user per local day. `id` PK, `user_id` FK CASCADE,
`local_date` date NOT NULL, `attempt_count` int NOT NULL default 0, `completed_item_count` int NOT
NULL default 0, `average_score` numeric(5,2), `best_score` numeric(5,2), `practice_seconds` int NOT
NULL default 0, `goal_met` bool NOT NULL default false, timestamps.
`UNIQUE (user_id, local_date)`; index `(user_id, local_date DESC)`. Updated by upsert on each
completed attempt, so the common "last 30 days" chart is one indexed range scan.

**`streaks`** — one row per user. `id` PK, `user_id` UNIQUE FK CASCADE, `current_streak` int NOT
NULL default 0, `longest_streak` int NOT NULL default 0, `last_practice_date` date,
`streak_freeze_count` int NOT NULL default 0 (reserved for a future premium perk), `updated_at`.

Kept separate from `profiles` because streak logic will grow (freezes, repairs, milestones) and
because it is written on a different cadence than profile data.

### 10.6 Monetization

**`subscriptions`** — current entitlement state.

| Column | Notes |
|--------|-------|
| `id` uuid PK | |
| `user_id` uuid NOT NULL FK CASCADE | |
| `provider` text NOT NULL | `revenuecat` |
| `store` text NOT NULL | `app_store` \| `play_store` |
| `provider_customer_id` text | RevenueCat app user ID |
| `product_id`, `entitlement_id` text | |
| `status` text NOT NULL | `trialing|active|grace_period|cancelled|expired|refunded` |
| `is_trial` bool NOT NULL default false | |
| `current_period_start`, `current_period_end` timestamptz | |
| `trial_end` timestamptz NULL | |
| `auto_renew` bool | |
| `original_transaction_id` text | Store-side identity of the subscription |
| `last_event_at` timestamptz | Guards against out-of-order webhooks |
| `created_at`, `updated_at` | |

`UNIQUE (user_id, store)` — one current state per store per user; history lives in events.
Index `(status, current_period_end)` for expiry sweeps.

**`subscription_events`** — append-only audit log. `id` PK, `user_id` NULL FK, `subscription_id`
NULL FK, `provider` text, `provider_event_id` text **UNIQUE** (idempotency), `event_type` text,
`store` text, `payload` jsonb NOT NULL (raw vendor body), `occurred_at` timestamptz,
`received_at` timestamptz, `processed_at` timestamptz NULL, `processing_error` text NULL.
Index `(user_id, occurred_at DESC)`, `(processed_at) WHERE processed_at IS NULL`.

This is the one place we deliberately store a raw vendor payload, because billing disputes require
evidence and replay. It is scoped, documented, and never read by domain logic.

### 10.7 Devices

**`devices`** — `id` PK, `user_id` FK CASCADE, `platform` text NOT NULL (`ios|android`),
`push_token` text NOT NULL, `app_version` text, `os_version` text, `locale` text,
`push_enabled` bool NOT NULL default true, `last_seen_at` timestamptz, timestamps.
`UNIQUE (push_token)` with upsert-on-conflict reassigning the row to the current user, because a
token belongs to one app install at a time and users share devices.

### 10.8 Relationship notes

- `users` is the root of everything user-owned; all such FKs cascade so account deletion is
  complete and provable.
- `words` uses `RESTRICT`/`is_active` rather than cascade: deleting content must never delete a
  learner's history.
- `practice_items` -> `pronunciation_attempts` is one-to-many because retries are a core feature.
- `pronunciation_attempts` -> `phoneme_results` is the analytical spine of the product.

### 10.9 What we are not doing

No table for `word_results` (JSONB is right until it is queried across rows). No
`learning_recommendations` table (computed). No many-to-many word/category join table (a word has
one primary category; tagging arrives with a `tags` table when the roadmap actually needs it). No
event-sourcing, no partitioning, no sharding. Section 33 states when partitioning
`pronunciation_attempts` and `phoneme_results` by month becomes worth doing.

---

## 11. API Architecture

### 11.1 Conventions

| Rule | Detail |
|------|--------|
| Base path | `/api/v1` — version in the path, because it is explicit, cacheable, and obvious in logs |
| Transport | HTTPS only; HTTP redirects to HTTPS; HSTS enabled |
| Auth | `Authorization: Bearer <access token>` unless stated otherwise |
| Content type | `application/json`; audio upload uses `multipart/form-data` |
| Success envelope | `{"data": {...}, "meta": {...}}` — `meta` carries pagination and request ID |
| Error envelope | `{"error": {"code": "...", "message": "...", "details": {}}}` (section 19) |
| Pagination | Cursor-based (`?limit=&cursor=`) for attempt history; offset allowed for small static lists |
| Idempotency | `Idempotency-Key` header honoured on attempt submission and purchase sync |
| Correlation | `X-Request-ID` accepted from the client, generated if absent, echoed in the response |
| Client identification | `X-App-Version`, `X-Platform` headers for diagnostics and forced-upgrade support |
| Time | ISO-8601 UTC everywhere |
| Naming | `snake_case` JSON fields, plural collection nouns, no verbs in paths except explicit actions (`/complete`, `/refresh`) |

**Versioning policy.** `v1` is additive-only once frozen: fields may be added, never removed or
retyped; enum values may be added, and clients must ignore unknown values. Breaking changes create
`/api/v2` while `v1` remains until analytics show old app versions have drained. The Go router
mounts modules under a version group, so `v2` is a second group reusing the same services.

### 11.2 Endpoint contracts

Legend for Auth: `public` (none), `user` (valid access token), `webhook` (signature-verified).

#### auth

| Method | Route | Auth | Request | Response | Errors | Rate limit |
|--------|-------|------|---------|----------|--------|------------|
| POST | `/api/v1/auth/apple` | public | `{identity_token, nonce, full_name?}` | `{access_token, refresh_token, expires_in, user}` | `VALIDATION_ERROR`, `INVALID_IDENTITY_TOKEN`, `PROVIDER_ERROR` | 10/min/IP |
| POST | `/api/v1/auth/google` | public | `{id_token}` | same as above | same as above | 10/min/IP |
| POST | `/api/v1/auth/refresh` | public | `{refresh_token}` | `{access_token, refresh_token, expires_in}` | `INVALID_REFRESH_TOKEN`, `TOKEN_REUSE_DETECTED` | 20/min/IP |
| POST | `/api/v1/auth/logout` | user | `{refresh_token}` | `204` | `UNAUTHENTICATED` | 20/min/user |

#### users

| Method | Route | Auth | Request | Response | Errors |
|--------|-------|------|---------|----------|--------|
| GET | `/api/v1/users/me` | user | — | `{user, profile, preferences, entitlement}` | `UNAUTHENTICATED` |
| PATCH | `/api/v1/users/me` | user | `{display_name?, avatar_url?}` | updated profile | `VALIDATION_ERROR` |
| GET | `/api/v1/users/me/preferences` | user | — | preferences | — |
| PUT | `/api/v1/users/me/preferences` | user | `{ui_language, learning_language, accent, difficulty_level, daily_goal, timezone, reminder_*}` | preferences | `VALIDATION_ERROR` |
| DELETE | `/api/v1/users/me` | user | `{confirmation: true}` | `204` | `VALIDATION_ERROR` |

The composite `GET /users/me` exists so app launch is one round trip rather than four.

#### words (content)

| Method | Route | Auth | Request | Response | Errors |
|--------|-------|------|---------|----------|--------|
| GET | `/api/v1/categories` | user | — | `[{id, slug, name_key, icon, word_count}]` | — |
| GET | `/api/v1/words` | user | `?category_id&difficulty&cefr&phoneme&search&limit&cursor` | paged words | `VALIDATION_ERROR` |
| GET | `/api/v1/words/{id}` | user | — | word detail incl. `phonetic_ipa`, `audio_url`, `meaning_uz`, `example_sentence` | `NOT_FOUND` |

Content responses carry `ETag`/`Cache-Control`; the app caches locally and revalidates.

#### practice

| Method | Route | Auth | Request | Response | Errors |
|--------|-------|------|---------|----------|--------|
| POST | `/api/v1/practice/sessions` | user | `{session_type, content_type=word, category_id?, item_count?}` | session + items (words embedded) | `VALIDATION_ERROR`, `PREMIUM_REQUIRED` (premium session types), `USAGE_LIMIT_REACHED` |
| GET | `/api/v1/practice/sessions/{id}` | user | — | session + items + per-item best result | `NOT_FOUND` |
| GET | `/api/v1/practice/sessions` | user | `?status&limit&cursor` | recent sessions | — |
| POST | `/api/v1/practice/sessions/{id}/complete` | user | — | session summary (scores, improvement, streak update) | `NOT_FOUND`, `CONFLICT` |

Returning items *with* their words embedded is deliberate: the practice screen must not need N+1
requests, and it must work when connectivity is poor mid-session.

#### pronunciation

| Method | Route | Auth | Request | Response | Errors | Rate limit |
|--------|-------|------|---------|----------|--------|------------|
| POST | `/api/v1/pronunciation/attempts` | user | multipart: `audio` file + `practice_item_id`/`word_id` + `reference_text` + `audio_format` + `duration_ms`; `Idempotency-Key` header | `PronunciationResult` DTO: scores, `words[]` with `phonemes[]`, `errors[]`, `feedback[]`, `improvement`, `attempt_number` | `VALIDATION_ERROR`, `AUDIO_TOO_LARGE`, `AUDIO_TOO_LONG`, `UNSUPPORTED_AUDIO_FORMAT`, `USAGE_LIMIT_REACHED`, `PREMIUM_REQUIRED`, `PROVIDER_UNAVAILABLE`, `PROVIDER_TIMEOUT` | 20/min/user + daily quota |
| GET | `/api/v1/pronunciation/attempts/{id}` | user | — | stored result | `NOT_FOUND` |
| GET | `/api/v1/pronunciation/attempts` | user | `?word_id&from&to&limit&cursor` | attempt history | — |

This single POST is the product. Everything in section 6 happens behind it.

#### progress

| Method | Route | Auth | Response |
|--------|-------|------|----------|
| GET | `/api/v1/progress/summary` | user | totals, average score, trend, current + longest streak, goal state |
| GET | `/api/v1/progress/daily` | user | `?from&to` -> per-day counts/averages/goal met |
| GET | `/api/v1/progress/streak` | user | current, longest, last practice date, days remaining today |
| GET | `/api/v1/progress/weak-sounds` | user | ranked weak phonemes with severity, sample words, recommended word IDs |
| GET | `/api/v1/progress/words/{word_id}` | user | per-word attempt history and improvement |

#### subscriptions

| Method | Route | Auth | Request | Response | Errors |
|--------|-------|------|---------|----------|--------|
| GET | `/api/v1/subscriptions/me` | user | — | `{tier, status, expires_at, is_trial, limits:{daily_assessments, used_today, resets_at}}` | — |
| POST | `/api/v1/subscriptions/sync` | user | `{app_user_id}` | refreshed entitlement | `PROVIDER_ERROR` |
| POST | `/api/v1/subscriptions/webhooks/revenuecat` | webhook | vendor payload | `200` | `INVALID_SIGNATURE` |

`/sync` exists for the restore-purchases path and as a self-heal if a webhook is delayed; it pulls
current state from the provider rather than trusting the client's claim.

#### notifications

| Method | Route | Auth | Request | Response |
|--------|-------|------|---------|----------|
| PUT | `/api/v1/notifications/devices` | user | `{platform, push_token, app_version, os_version, locale}` | `204` |
| DELETE | `/api/v1/notifications/devices/{token}` | user | — | `204` |
| PUT | `/api/v1/notifications/preferences` | user | `{reminder_enabled, reminder_time, streak_reminder_enabled}` | preferences |

#### system

| Method | Route | Auth | Purpose |
|--------|-------|------|---------|
| GET | `/healthz` | public | Liveness — process is up |
| GET | `/readyz` | public | Readiness — DB reachable, config valid |
| GET | `/api/v1/config` | user | Remote config: min supported app version, feature flags, free limits |

`/api/v1/config` is small but strategically important: it lets us force upgrades and toggle
features without an app release.

### 11.3 OpenAPI

The contract above is authored as `docs/api/openapi.yaml` at the start of implementation and kept
in the repository as the single source of truth for request/response shapes. CI validates it and
generates the Dart client models, so app and server cannot silently drift. It is deliberately not
written yet — freezing the contract is the point of the review step this document precedes.

---

## 12. Audio Processing Architecture

### 12.1 Capture (Flutter)

| Parameter | Value | Why |
|-----------|-------|-----|
| Format | 16-bit PCM WAV, mono | What speech assessment engines want; avoids server-side transcoding and lossy artefacts that depress scores |
| Sample rate | 16 kHz | The standard for speech models; higher rates add bytes, not accuracy |
| Channels | 1 | Speech assessment is monophonic |
| Max duration | 15 s for a word, configurable per content type (30 s reserved for sentences) | Bounds cost, upload time, and abuse |
| Min duration | ~0.4 s | Rejects accidental taps before they cost a provider call |
| Max size | 2 MB enforced client and server side | 15 s of 16 kHz mono PCM is about 480 KB, so this is generous with headroom |
| Permissions | Requested in context, with a clear denial state | Store requirement and a common support issue |

The recorder writes to a temporary file, the app shows a live level meter, and the file is deleted
immediately after upload succeeds or fails. If a device or platform cannot produce WAV cheaply, the
app may send AAC/M4A and the server transcodes; the request declares `audio_format` so the server
never guesses.

### 12.2 Upload and validation

`multipart/form-data` streamed to the API. Server-side validation, in order, and before any
provider call:

1. Request body size cap enforced at the middleware layer (`MaxBytesReader`) so an oversized upload
   is rejected without buffering.
2. Declared MIME type against an allow-list (`audio/wav`, `audio/x-wav`, `audio/mp4`, `audio/aac`).
3. **Magic-byte sniffing** of the actual content — a declared MIME type is a claim, not a fact.
4. Header parse: sample rate, channel count, bit depth, duration; reject outside policy.
5. Duration cross-check against the client-declared `duration_ms`.

Rejections return specific error codes (`AUDIO_TOO_LARGE`, `AUDIO_TOO_LONG`,
`UNSUPPORTED_AUDIO_FORMAT`) so the app can give an actionable message rather than "something went
wrong". Validation happens before the entitlement counter is consumed and before the provider is
called: invalid input costs us nothing.

### 12.3 Processing and retention

Audio is handled **in memory or in a request-scoped temp file, streamed to the provider, and
discarded**. There is no audio table, no bucket, and no backup containing user voice in MVP.

Reasons: voice is personal data with real privacy weight; storing it invites retention, deletion,
consent, and jurisdiction obligations we gain nothing from at MVP; and it costs money. What we keep
is the *derived assessment*, which is what the product needs.

**The seam for later.** An `AudioStore` interface is defined from the start:

```
type AudioStore interface {
    Put(ctx, key string, r io.Reader, meta AudioMeta) (string, error)
    SignedURL(ctx, key string, ttl time.Duration) (string, error)
    Delete(ctx, key string) error
}
```

MVP wires a `noop` implementation and `AUDIO_RETENTION_ENABLED=false`. When a feature genuinely
needs playback of past attempts (self-comparison, human coach review, model training), we implement
`s3`/`azureblob` behind the same interface, add an `audio_key` column to `pronunciation_attempts`,
add explicit user consent, and set a retention policy. No pipeline restructuring.

### 12.4 Reference audio

Native pronunciation audio for words is *content*, not user data: pre-generated, stored in object
storage or the CDN, referenced by `words.audio_url`, cached aggressively on device, and versioned by
URL so a corrected recording invalidates cleanly.

---

## 13. Practice Architecture

### 13.1 Practice types

The `PracticeType` concept exists in full from day one; only `word` content ships in MVP.

| Type | Description | MVP |
|------|-------------|-----|
| `daily` | The day's curated set, sized to the user's `daily_goal` | Yes |
| `random` | Random words within the user's level | Yes |
| `category` | Words from a chosen category | Yes |
| `targeted` | Specific words the user picks | Post-MVP |
| `weak_sound` | Words exercising the user's weak phonemes (section 15) | Post-MVP (data captured from day one) |

Content types: `word` (MVP), `phrase`, `sentence` (modelled, not exposed).

### 13.2 Session selection

Item selection lives in a `PracticeSelector` inside the practice service — one place, one
responsibility, easily replaced:

```
PracticeSelector.Select(ctx, userID, criteria) -> []Word
```

MVP strategy: filter by learning language, accent, active status, and the user's difficulty; exclude
words practised well recently; prefer higher `frequency_rank`; shuffle deterministically per day so
"daily practice" is stable if the app is reopened.

The interface is what matters. An adaptive-difficulty or spaced-repetition selector later is a new
implementation of `PracticeSelector`, chosen by configuration or experiment flag, with no change to
sessions, items, attempts, or the app.

### 13.3 Session lifecycle

```
POST /practice/sessions        -> session created (in_progress) with N items
(user practises; each attempt) -> POST /pronunciation/attempts updates item + counters
POST /practice/sessions/{id}/complete -> status completed, averages computed,
                                          daily_progress upserted, streak evaluated
```

Sessions may be abandoned; a scheduled sweep marks stale `in_progress` sessions `abandoned` so
analytics on completion rate stay honest.

### 13.4 Content architecture

Content is a first-class, server-owned domain (backend module `word`, conceptually "content"):

- **Structure**: `categories` -> `words`, with `difficulty_level`, `cefr_level`, `accent`,
  `language`, `phonetic_ipa`, `target_phonemes`, `meaning_uz`, `example_sentence`, `audio_url`.
- **Never in the app.** No word list, no phonetic string, and no example sentence is compiled into
  Flutter. Content updates must not require an app release or store review.
- **Seeding**: versioned SQL/CSV seed data under `backend/migrations/seed/`, applied per
  environment, reviewed like code.
- **Future content sets** (IELTS, business, travel, interview, academic English) are *categories and
  tags plus rows*, not new code paths. The one schema addition they imply is a `tags` table when a
  word needs to belong to several sets at once.
- **Future authoring**: an internal admin tool writing to the same tables through the same service.
  Not built for MVP; seed scripts are sufficient and honest at this size.

---

## 14. Progress Architecture

### 14.1 What progress means here

Four questions the product must answer, each mapped to a data path:

| Question | Source |
|----------|--------|
| "What did I do today, and did I hit my goal?" | `daily_progress` (upserted per completed attempt) |
| "How many days in a row?" | `streaks` |
| "Am I getting better?" | Attempt trend per word and overall; `improvement` on each result |
| "What should I fix?" | `phoneme_results` aggregation (section 15) |

### 14.2 Update path

Progress is updated **synchronously inside the attempt transaction** for MVP: when an attempt
completes, the same transaction upserts `daily_progress` and updates `practice_items`. Streak
evaluation runs immediately after, using the user's timezone.

Why synchronous: correctness and simplicity. The user must see their streak update the moment they
finish, and at MVP volume these are two indexed writes. The seam for later is that all of it lives
behind `progress.Service.RecordAttempt(...)`, so moving it to an asynchronous job (section 21) is a
change at one call site.

### 14.3 Streak rules

Defined explicitly, because ambiguity here produces bug reports:

- A day counts when the user completes at least one **successful** attempt (a failed provider call
  never breaks a streak — we do not punish users for our outage).
- Day boundaries use `user_preferences.timezone`, not server time.
- Practising twice in one day does not increase the streak.
- Missing a day resets `current_streak` to 0; `longest_streak` is preserved.
- `streak_freeze_count` exists in the schema for a future premium perk but is unused in MVP.

### 14.4 Improvement measurement

- **Per attempt**: score minus the user's previous best for that word, returned in the result so the
  app can say "+8 vs your best".
- **Per word**: chronological attempt scores; the mastery threshold (for example, two consecutive
  attempts at or above 80) is configuration.
- **Overall**: 7-day and 30-day rolling averages from `daily_progress`.
- All comparisons record `scoring_version`; scores produced by different scoring policies are never
  silently compared.

---

## 15. Weak Sound Architecture

### 15.1 Goal

Detect that a specific learner repeatedly struggles with a specific sound — for example `/θ/` (the
TH in *think*) — explain it, and hand them targeted practice: *think, three, thank, through*.

This is the feature most likely to differentiate Voca for Uzbek speakers, whose first language lacks
several English phonemes. **That is why phoneme-level data is captured from the very first attempt
even though the weak-sound screen ships later.** Analysis features are worthless without history;
history cannot be created retroactively.

### 15.2 Data path

```
Assessment -> PhonemeResult[] -> phoneme_results rows (user_id denormalized)
                                        |
                                        v
                        WeakSoundService aggregation (rolling window)
                                        |
                        +---------------+---------------+
                        v                               v
              GET /progress/weak-sounds        PracticeSelector (weak_sound sessions)
```

### 15.3 Detection rules

A phoneme is a **weak sound** for a user when, within a rolling window (last 30 days or last 200
phoneme observations, whichever is smaller):

| Signal | MVP threshold |
|--------|---------------|
| Minimum observations | at least 5 occurrences (below this, we say nothing — noise is not a diagnosis) |
| Average score | below 60 |
| Error rate | at least 30% of occurrences classified as an error |
| Severity | `severe` under 40, `moderate` 40–59, `minor` 60–69 with a high error rate |
| Recency weighting | Recent occurrences weighted higher, so improvement is reflected quickly |

Thresholds are configuration, not constants. They *will* be tuned against real data, and tuning
must not require a code change.

### 15.4 From weakness to practice

`words.target_phonemes` (a GIN-indexed array) is what closes the loop: given weak phoneme `θ`, find
active words at the user's level whose `target_phonemes` contain `θ`, ordered by frequency. That is
one indexed query, which is precisely why the column exists in the MVP schema despite the feature
shipping later.

Each weak sound is presented with: the phoneme and a learner-friendly label, severity, example words
the user actually got wrong, an articulation tip (tongue/lip/airflow, by message key so it is Uzbek
today and any language tomorrow), and a "practise this sound" action that starts a `weak_sound`
session.

### 15.5 Boundaries

`WeakSoundService` lives in the `progress` module and reads `phoneme_results` through the
pronunciation module's repository interface. It does not reach into the pronunciation module's
tables directly (section 5.5), so the analysis can later move to a read replica, a materialized
view, or its own service without touching the assessment path.

Scale seam: when live aggregation gets expensive, add a `user_phoneme_stats` rollup table maintained
by a background job. The API contract does not change; only the query behind it does.

---

## 16. Analytics Architecture

### 16.1 Abstraction

Feature code never imports Firebase or PostHog. Both platforms define a narrow port:

```
// Flutter: lib/core/analytics/analytics_service.dart
abstract class AnalyticsService {
  Future<void> track(AnalyticsEvent event);
  Future<void> identify(String userId, {Map<String, Object?> traits});
  Future<void> screen(String name, {Map<String, Object?> properties});
  Future<void> reset();
}

// Go: internal/analytics/port.go
type AnalyticsProvider interface {
    Track(ctx context.Context, e Event) error
    Identify(ctx context.Context, userID string, traits map[string]any) error
}
```

Implementations: `FirebaseAnalyticsService`, `PostHogAnalyticsService`, `CompositeAnalyticsService`
(fan-out to several), `NoopAnalyticsService` (tests, and any environment where tracking is off).
Swapping providers is a one-line change in the composition root.

**Events are typed, not stringly-typed.** A sealed `AnalyticsEvent` class hierarchy (Dart) and typed
constructors (Go) mean an event name or property can never be misspelled in one place and silently
break a funnel. Event names live in one file, `core/analytics/events.dart`.

### 16.2 Client vs server events

| Emitted by | Events | Why |
|------------|--------|-----|
| Mobile | UI and funnel events: `app_opened`, `practice_started`, `word_viewed`, `audio_played`, `recording_started`, `recording_completed`, `retry_clicked`, `premium_viewed`, `paywall_dismissed` | Only the client knows these happened |
| Backend | Money and truth events: `assessment_completed`, `trial_started`, `subscription_started`, `subscription_renewed`, `subscription_cancelled`, `usage_limit_reached` | A client can be tampered with; revenue reporting must come from verified webhook state |

Server-side tracking is **fire-and-forget with a timeout**, never inside a database transaction, and
never able to fail a user request. An analytics outage must not become a product outage.

### 16.3 Event catalogue (MVP)

`app_opened`, `onboarding_started`, `onboarding_completed`, `signup_completed`, `login_completed`,
`practice_started`, `word_viewed`, `audio_played`, `recording_started`, `recording_completed`,
`assessment_requested`, `assessment_completed` (with `overall_score` band, `word_id`, `attempt_number`),
`assessment_failed` (with `error_code`), `retry_clicked`, `session_completed`, `weak_sound_viewed`,
`premium_viewed`, `paywall_dismissed`, `trial_started`, `subscription_started`,
`subscription_cancelled`, `usage_limit_reached`, `streak_milestone_reached`.

Every event carries a common context: `user_id` (pseudonymous), `platform`, `app_version`,
`ui_language`, `entitlement_tier`, `session_id`.

### 16.4 Metrics these events must support

| Metric | Definition |
|--------|------------|
| DAU / WAU / MAU | Distinct users with `app_opened` in 1 / 7 / 30 days |
| D1 / D7 / D30 retention | Returned on day 1 / 7 / 30 after signup |
| Practice completion rate | `session_completed` ÷ `practice_started` |
| Average pronunciation score | Mean `overall_score` of completed assessments, by cohort and over time |
| Retry rate | `retry_clicked` ÷ `assessment_completed` |
| Free-to-premium conversion | `subscription_started` ÷ users reaching `premium_viewed` (and ÷ all signups) |
| Trial conversion | Trials converting to paid |
| Churn / subscription retention | Cancelled or expired ÷ active at period start |
| Limit pressure | `usage_limit_reached` per free user — the leading indicator for pricing decisions |

Score-related product metrics are computed from our own database rather than the analytics vendor,
because that data is authoritative, queryable, and not subject to a vendor's sampling or retention.

### 16.5 Privacy

No raw audio, no email address, no auth token, and no free-text user input is ever sent to an
analytics provider. `user_id` is our internal UUID, not an email. Analytics can be disabled by
configuration per environment, and tracking respects platform consent requirements (ATT on iOS).

---

## 17. Notification Architecture

### 17.1 Abstraction

```
type NotificationProvider interface {
    Send(ctx context.Context, msg PushMessage) (Receipt, error)
    SendBatch(ctx context.Context, msgs []PushMessage) ([]Receipt, error)
}
```

`PushMessage` carries device token, platform, a **localization key with parameters** (not a rendered
sentence), a deep link, and a data payload. Rendering happens against the device's locale, which is
what makes the second UI language free.

MVP implementation: **Firebase Cloud Messaging** for both platforms, since FCM delivers to iOS via
APNs. A direct APNs adapter can be added behind the same interface if we ever need APNs-specific
features or want to remove the Firebase dependency.

### 17.2 Notification types

| Type | Trigger | Notes |
|------|---------|-------|
| Daily practice reminder | User's `reminder_time` in their timezone, if they have not practised | The core retention mechanism |
| Streak at risk | Late in the user's day with an active streak and no practice | High-value, must not be sent after they practise |
| Weak-sound nudge | Periodic, when a weak sound is detected | Post-MVP |
| Subscription events | Trial ending, billing problem, expiry | Driven by `subscription_events` |
| Milestones | Streak and mastery achievements | Post-MVP |

### 17.3 Delivery discipline

- **Token lifecycle**: registered on login and app start, removed on logout, and invalid tokens
  pruned when the provider reports them unregistered.
- **Preferences respected server-side.** `user_preferences` gates sending; a user who disables
  reminders must not receive them even if a job says otherwise.
- **Frequency cap**: at most one reminder-class notification per user per day, enforced centrally,
  because the fastest way to lose a learner is to nag them.
- **Quiet hours** derived from the user's timezone.
- Every notification carries a deep link into the exact screen it promises (section 4.4).

MVP scope is deliberately small: daily reminder plus streak-at-risk, scheduled by the in-process
scheduler (section 21). Fan-out to a queue arrives with the worker process, not before.

---

## 18. Security Architecture

### 18.1 Principles

Security by default: every endpoint authenticated unless explicitly marked public; every input
validated; every secret from the environment; every response scrubbed of internals.

### 18.2 Controls

| Area | Control |
|------|---------|
| Transport | HTTPS only, TLS 1.2+, HSTS; certificate pinning considered post-MVP |
| Authentication | Apple/Google identity tokens verified against provider JWKS (signature, `iss`, `aud`, `exp`, nonce) |
| Sessions | Short-lived HS256 access JWT; opaque, hashed, rotating refresh tokens with reuse detection |
| Token storage (device) | Keychain / EncryptedSharedPreferences via `flutter_secure_storage`; never in plain preferences or logs |
| Authorization | Ownership checked in the service layer on every user-scoped resource; unknown-vs-forbidden collapsed to `404` |
| Entitlement | Enforced server-side only; client flags are cosmetic |
| Passwords (future) | Argon2id, per-user salt, never logged, never returned |
| Rate limiting | Per-IP on auth endpoints, per-user on assessment endpoints, global safety limit; in-memory token bucket for MVP, Redis-backed when multi-instance |
| Upload validation | Size cap at middleware, MIME allow-list, magic-byte sniffing, duration and sample-rate checks (section 12.2) |
| Input validation | Struct tags on every DTO; unknown fields rejected; strict types; length caps on all strings |
| SQL injection | sqlc/pgx parameterized queries only. **String-concatenated SQL is banned**, enforced in review and by lint |
| CORS | Locked to known origins; the mobile app needs none, so CORS is effectively off in production |
| Secrets | Environment variables injected by the platform's secret manager; `.env` files are local-only and git-ignored; secret scanning in CI |
| Mobile secrets | **No Azure key, no RevenueCat secret key, no database credential ever ships in the app.** Only public client IDs |
| Webhooks | Signature/shared-secret verification before parsing; replay protection via unique provider event ID |
| Dependencies | `govulncheck`, Dependabot, `flutter pub outdated` in CI |
| Account deletion | Full cascade delete plus token revocation, exposed in-app (store requirement) |
| Privacy | Data minimization; no audio retention; documented data map and retention policy |
| Headers | `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, no `Server` version banner |
| Panics | Recovery middleware converts a panic into `500 INTERNAL_ERROR` with a request ID, never a stack trace to the client |

### 18.3 Threats we explicitly design against

| Threat | Mitigation |
|--------|------------|
| Free user bypasses limits by patching the app | Server-side quota; client flags are hints only |
| Stolen refresh token | Rotation with reuse detection invalidates the family |
| Fake purchase / replayed receipt | Entitlement derives from provider-verified webhooks, never client claims |
| Abusive upload flood driving Azure cost | Per-user rate limit + daily quota + size caps, all checked before the provider call |
| ID enumeration | UUID keys and `404`-on-not-owned |
| Someone else's attempt read via a guessed ID | Ownership check in the service layer |
| Vendor outage cascading into data loss | Failed attempts persisted with status, quota not consumed, user told to retry |

### 18.4 Observability, and what must never be logged

Structured logging with `log/slog` in JSON. Every log line carries `request_id`, `method`, `path`,
`status`, `duration_ms`, `user_id` when authenticated, and `app_version`.

- **Request ID** is generated (or accepted) per request, stored in `context.Context`, attached to
  every log line, returned in `X-Request-ID`, and shown in the app's error state so a user's
  screenshot is directly traceable.
- **Correlation ID** propagates the same value into provider calls and, later, across extracted
  services — the seam that makes distributed tracing an addition rather than a retrofit.

Metrics recorded from day one, because they define our scaling and vendor decisions:

| Metric | Why it exists |
|--------|---------------|
| API latency by route (p50/p95/p99) | User-perceived speed |
| Assessment end-to-end latency | The one number that defines the core experience |
| **Provider latency and error rate** (`provider_latency_ms`, failures by code) | Vendor health, SLA evidence, and the trigger for circuit breaking or switching |
| Database query latency and pool saturation | The first thing to break under load |
| Daily assessments per user and quota-hit rate | Cost forecasting and pricing |
| Error rate by error code | Product bugs vs vendor problems, separated |

**Never logged, under any circumstance:** passwords, password hashes, access tokens, refresh tokens,
Apple/Google identity tokens, API keys or secrets, full webhook payloads containing personal data
(store the raw body in `subscription_events`, not in logs), raw audio or audio file contents, email
addresses in analytics events, and full request bodies for auth or upload endpoints.

Error tracking and crash reporting (Sentry for backend, Sentry or Crashlytics for mobile) run behind
a thin wrapper so the vendor is replaceable, with scrubbing rules configured to drop the fields above
before transmission.

---

## 19. Error Handling

### 19.1 Wire format

```json
{
  "error": {
    "code": "PREMIUM_REQUIRED",
    "message": "Premium subscription required",
    "details": { "limit": 10, "used": 10, "resets_at": "2026-09-10T00:00:00Z" },
    "request_id": "01J9F2K7Q0X3MZ8VYB4T6N1RCD"
  }
}
```

`code` is a stable machine-readable string the app switches on. `message` is a short, safe,
human-readable fallback. `details` is structured, optional, and never contains internals.
`request_id` ties a user report to a log line.

**The app localizes by `code`, not by `message`.** The Uzbek text lives in the app's ARB files. That
is why the message field can stay in English and why a second UI language costs no backend work.

### 19.2 Categories

| Category | HTTP | Example codes |
|----------|------|---------------|
| Validation | 400 | `VALIDATION_ERROR`, `UNSUPPORTED_AUDIO_FORMAT`, `AUDIO_TOO_LONG` |
| Payload too large | 413 | `AUDIO_TOO_LARGE` |
| Authentication | 401 | `UNAUTHENTICATED`, `TOKEN_EXPIRED`, `INVALID_REFRESH_TOKEN`, `TOKEN_REUSE_DETECTED` |
| Authorization | 403 | `FORBIDDEN`, `PREMIUM_REQUIRED` |
| Not found | 404 | `NOT_FOUND` |
| Conflict | 409 | `CONFLICT`, `ALREADY_COMPLETED` |
| Rate limit / quota | 429 | `RATE_LIMITED`, `USAGE_LIMIT_REACHED` (with `Retry-After`) |
| Provider | 502 / 503 / 504 | `PROVIDER_ERROR`, `PROVIDER_UNAVAILABLE`, `PROVIDER_TIMEOUT` |
| Database / internal | 500 | `INTERNAL_ERROR` |
| Maintenance | 503 | `SERVICE_UNAVAILABLE` |

`USAGE_LIMIT_REACHED` versus `PREMIUM_REQUIRED` is a meaningful distinction: the first means "come
back tomorrow or upgrade", the second means "this feature is not in your plan". The app shows
different screens, so the API must not collapse them.

### 19.3 Implementation

- One `apperr.AppError{Code, HTTPStatus, Message, Details, Err}` type in `internal/shared/apperr`.
- Services return domain errors; a single mapping function in the handler layer turns them into HTTP
  responses. There is exactly one place where an error becomes a status code.
- **Database and provider errors are wrapped, never surfaced.** A client must never see a
  constraint name, a table name, a driver message, an Azure error body, or a stack trace. The
  internal detail goes to the log with the request ID; the client gets `INTERNAL_ERROR` and that ID.
- Panics are caught by recovery middleware, logged with a stack trace, and returned as
  `INTERNAL_ERROR`.
- Flutter mirrors this: the Dio error interceptor maps `code` to a typed `Failure`, use cases return
  `Result<T, Failure>`, and the UI renders per-failure states (retry, upgrade, sign in again) rather
  than a generic dialog.

---

## 20. Caching

### 20.1 Position

**Redis is not required for MVP and is not deployed at MVP.** A single instance with PostgreSQL can
serve the entire early user base, and every cache adds an invalidation problem. But the code is
written so Redis can be introduced without touching business logic.

### 20.2 The seam

```
type CacheStore interface {
    Get(ctx context.Context, key string, dest any) (bool, error)
    Set(ctx context.Context, key string, val any, ttl time.Duration) error
    Delete(ctx context.Context, keys ...string) error
    Increment(ctx context.Context, key string, ttl time.Duration) (int64, error)
}
```

MVP ships an **in-process implementation** (TTL map, bounded size). It is a real implementation, not
a stub: caching code paths exist, are exercised, and are tested from day one. Adding Redis later is
`CACHE_DRIVER=redis` plus a `redis` implementation of the same interface, with correctness already
proven by the tests that ran against the memory driver.

The one behaviour that differs between drivers is sharing across instances, which is exactly why the
switch is required before running more than one API instance (section 33, Stage 2).

### 20.3 Planned uses, in the order they will be needed

| Use | Stage | Notes |
|-----|-------|-------|
| Rate limit counters | When >1 instance runs | In-memory buckets stop being correct the moment traffic is split |
| Daily usage quota counters | Stage 2 | Currently a `COUNT` on an indexed column; cheap until it is not |
| Word and category content cache | Stage 2 | Read-heavy, rarely changes, invalidated on content update |
| Entitlement cache (short TTL, 60 s) | Stage 2 | Cuts a read from every gated request, with a TTL short enough that a cancelled subscription cannot linger |
| Refresh-token revocation list | Stage 2–3 | Fast negative lookups |
| Background job queue backing store | Stage 3 | Section 21 |
| Leaderboard sorted sets | When gamification ships | The classic Redis use case; part of why we reserve it now |

Rules: caches always have a TTL, the database is always the source of truth, and nothing that
affects money or entitlement is cached for longer than a minute.

---

## 21. Background Jobs

### 21.1 MVP position

No queue, no broker, no separate worker fleet. The handful of periodic tasks MVP genuinely needs run
on an **in-process scheduler** (`robfig/cron`) inside the API binary, guarded by an advisory lock in
PostgreSQL so that running two instances never double-executes a job.

MVP jobs:

| Job | Cadence | Purpose |
|-----|---------|---------|
| Streak rollover | Hourly (timezone-aware) | Resets streaks for users whose day ended without practice |
| Daily reminder dispatch | Every 15 minutes | Sends reminders to users whose `reminder_time` has arrived |
| Stale session sweep | Hourly | Marks abandoned `in_progress` sessions |
| Subscription expiry sweep | Hourly | Downgrades entitlements past `current_period_end` if no webhook arrived |

### 21.2 The boundary that makes extraction cheap

Jobs are written as **thin triggers over existing services**:

```
type Job interface {
    Name() string
    Run(ctx context.Context) error
}
```

A job holds no business logic. `StreakRolloverJob.Run` calls `progress.Service.RolloverStreaks(ctx)`.
That is the whole discipline, and it produces three properties:

1. Jobs are unit-testable without a scheduler.
2. The same logic can be triggered by cron today, by a queue consumer tomorrow, and by an admin
   endpoint for debugging, with no duplication.
3. Moving to a real queue means changing *how `Run` is invoked* and building `cmd/worker` — not
   rewriting the work.

### 21.3 Growth path

| Stage | Mechanism |
|-------|-----------|
| MVP | In-process cron + advisory lock, same binary |
| Stage 2–3 | Redis-backed queue (`asynq`) for fan-out work such as push batches; `cmd/worker` runs as a second deployment of the *same image* with a different entrypoint |
| Stage 4 | Broker (NATS/SQS/Kafka) only if event-driven cross-service flows genuinely require it |

Work that becomes asynchronous later, and the reason it is synchronous now: progress and streak
updates (correctness and instant feedback beat throughput at this size), analytics forwarding
(already fire-and-forget), and recommendation generation (currently computed on read).

Deliberately **not** made asynchronous: pronunciation assessment itself. The user is waiting for the
result on screen; a job queue would add latency and a polling protocol to solve a problem we do not
have. If assessment ever becomes slow enough to need it, the API gains an async submission mode
alongside the synchronous one.

---

## 22. Testing Architecture

Testing is not a phase; it is a property of the interfaces defined in this document. Every provider
has a port, so every provider has a mock, so every layer can be tested in isolation. That is the
main reason the abstractions exist.

### 22.1 Backend

| Level | What it covers | Dependencies | Speed |
|-------|----------------|--------------|-------|
| Unit | Pure logic: scoring engine, phoneme analysis, feedback rules, weak-sound thresholds, streak calculation, validation | None | Milliseconds |
| Service | Business rules and orchestration: quota enforcement, entitlement gating, retry numbering, error mapping | Mocked repositories and providers | Milliseconds |
| Repository | SQL correctness: queries, constraints, indexes, transactions, upserts | Real PostgreSQL via `testcontainers-go` (or docker-compose in CI) | Seconds |
| Handler | HTTP contract: binding, validation, status codes, error envelope, auth middleware | `httptest` + mocked services | Milliseconds |
| Integration | Full stack through the real router and real database, with mocked external providers | Postgres + `mock` SpeechProvider/PaymentProvider | Seconds |
| Provider adapter | Mapping correctness | Golden files of recorded vendor payloads | Milliseconds |

The highest-value tests in this system, ranked:

1. **Azure mapper golden tests.** Recorded Azure responses (including edge cases: omitted phonemes,
   insertions, empty recognition, partial results) mapped to expected domain objects. This is where
   a vendor change would otherwise silently corrupt scores.
2. **Scoring engine tests.** Fixed inputs, exact expected outputs, per `scoring_version`.
3. **Quota and entitlement tests.** Free user at limit, premium user, expired subscription, refunded
   subscription, failed attempt not consuming quota.
4. **Webhook idempotency tests.** Duplicate and out-of-order events converge to correct state.
5. **Streak boundary tests.** Timezones, midnight, missed days, same-day repeats.

Mocking approach: interfaces are small and hand-written fakes are often clearest; `mockery`-generated
mocks are used where a fake would be tedious. `SpeechProvider`, `PaymentProvider`,
`AnalyticsProvider`, `NotificationProvider`, and `CacheStore` each ship a mock implementation in the
same package tree as the real one, so tests never construct a vendor client.

Coverage policy: meaningful thresholds on `internal/*/service` and the pronunciation engines (target
80%+); no global percentage chased for its own sake.

### 22.2 Mobile

| Level | What it covers | Tooling |
|-------|----------------|---------|
| Unit | Use cases, mappers, failure translation, score formatting, validators | `flutter_test` |
| Provider/controller | Riverpod controllers with overridden repositories: loading -> recording -> assessing -> result -> error transitions | `ProviderContainer` overrides |
| Widget | Screens render correctly per state; the result screen renders scores, phoneme chips, and tips; the paywall appears on `PREMIUM_REQUIRED` | `flutter_test` + golden tests for key screens |
| Integration | Critical journeys on a device/emulator: sign in, start practice, record, submit, see result, retry | `integration_test` |

Because `domain` is pure Dart with no Flutter imports, the majority of app logic is testable without
a widget tree — which is the practical payoff of the layering in section 4.

### 22.3 Contract alignment

The OpenAPI document is the shared contract. CI validates it, generates Dart models from it, and
runs backend contract tests against it, so a backend field rename fails the build rather than
failing in production on a user's phone.

---

## 23. CI/CD

### 23.1 Repository and branching

Single repository (monorepo) containing `mobile/`, `backend/`, `docs/`, `infra/`. One repo keeps the
API contract, its server, and its client in the same commit and the same pull request, which is
worth far more at this size than independent release cadences.

Branching: trunk-based. Short-lived feature branches into `main`; `main` is always deployable;
tags (`backend-v1.2.0`, `mobile-v1.2.0`) trigger releases.

### 23.2 Workflows

**`backend-ci.yml`** — on pull request and push to `main`, paths `backend/**`:

```
gofmt -l (fail on diff)  ->  go vet  ->  golangci-lint  ->  govulncheck
  ->  sqlc diff (generated code is current)
  ->  go test ./... -race -cover            (unit + service + handler)
  ->  integration tests (postgres service container, migrations applied, mock providers)
  ->  go build  ->  docker build (+ push to registry on main)
```

**`mobile-ci.yml`** — on pull request and push to `main`, paths `mobile/**`:

```
dart format --set-exit-if-changed  ->  flutter analyze (fatal-infos)
  ->  flutter test --coverage       (unit + widget + golden)
  ->  flutter build appbundle --flavor staging   (Ubuntu runner)
  ->  flutter build ipa --flavor staging         (macOS runner, signed via secrets)
```

**`openapi-ci.yml`** — validates `docs/api/openapi.yaml`, regenerates the Dart client, and fails if
the committed client is stale.

**`deploy-staging.yml`** — automatic on green `main`: run migrations, deploy the image, smoke-test
`/readyz`, and post the result.

**`deploy-production.yml`** — manual approval or tag: same steps against production, with migration
review, and an automatic rollback path to the previous image.

**Mobile distribution**: staging builds to TestFlight and Play internal testing via Fastlane;
production releases are promoted deliberately, since store review makes rollback slow — an argument
for keeping business rules server-side wherever we reasonably can.

### 23.3 CI principles

- CI runs no external provider calls: `SPEECH_PROVIDER=mock`, `PAYMENT_PROVIDER=mock`,
  `ANALYTICS_PROVIDER=noop`. Builds are free, deterministic, and offline.
- Migrations run in CI against a scratch database so a broken migration cannot reach staging.
- Secrets live in GitHub Environments with required reviewers on production.
- Every image is tagged with the commit SHA; deploys reference the SHA, so rollback is redeploying a
  previous tag.

---

## 24. Deployment Architecture

### 24.1 Target shape (MVP)

```
Flutter app  ->  App Store / Google Play

Go API (Docker image)  ->  managed container platform (1–2 instances)
PostgreSQL             ->  managed database with automated backups + PITR
Reference audio/assets ->  object storage + CDN
Redis                  ->  not deployed
Azure Speech           ->  external SaaS
RevenueCat             ->  external SaaS
```

### 24.2 Options considered

| Option | Setup | Ops burden | Cost at MVP | Scaling path | Verdict |
|--------|-------|-----------|-------------|--------------|---------|
| **A. Single VPS + Docker Compose + Caddy** | Low | Manual: patching, backups, TLS, monitoring, and a single point of failure | Lowest | Vertical only; horizontal means building an orchestration story | Cheapest, but hand-rolled backups and no redundancy is a poor trade for a paid product |
| **B. Managed container platform (Fly.io / Render / Railway) + managed Postgres (Neon / Supabase / RDS)** | Low | Platform handles TLS, health checks, rolling deploys, scaling, backups | Low | Add instances with a config change; add read replicas and Redis as managed add-ons | **Recommended** |
| **C. AWS ECS Fargate / GCP Cloud Run + RDS/Cloud SQL + ElastiCache** | Medium-high | IaC, IAM, VPC, monitoring stack to run | Medium | Effectively unlimited | Right at Stage 3–4, premature now |
| **D. Kubernetes** | High | A full-time concern | Highest | Unlimited | Explicitly rejected for MVP (ADR-011 context) |

### 24.3 Recommendation

**Option B.** It gives managed TLS, health checks, zero-downtime rolling deploys, automated database
backups with point-in-time recovery, and a metrics dashboard on day one, for roughly the price of a
VPS, without a person owning server maintenance. Since the artefact is a plain Docker image and the
only stateful dependency is PostgreSQL reached by `DATABASE_URL`, moving to Option C later is an
infrastructure change with **zero application code changes** — which is the point of keeping the
application twelve-factor and stateless.

### 24.4 Operational requirements from day one

| Requirement | Detail |
|-------------|--------|
| Statelessness | No local session state, no local file persistence; any instance can serve any request |
| Health endpoints | `/healthz` (liveness) and `/readyz` (readiness: DB reachable, config valid, migrations applied) |
| Graceful shutdown | Stop accepting connections, drain in-flight requests, close the pool — required for zero-downtime deploys |
| Migrations | Run as a distinct step before the new image serves traffic; forward-compatible so old and new instances coexist during a rolling deploy |
| Backups | Automated daily plus PITR; a **restore drill performed before launch**, because an untested backup is not a backup |
| Secrets | Platform secret store injected as environment variables; never in the image, never in git |
| Logs | JSON to stdout, collected by the platform, retained ~30 days |
| Alerts | Error rate, p95 latency, provider failure rate, database connection saturation, disk usage |
| TLS | Managed certificates, auto-renewed |
| Region | Closest to the primary user base (Uzbekistan): a European region, weighed against Azure Speech region latency |

### 24.5 Runtime cost drivers

Azure Speech per-assessment cost is the dominant variable and scales directly with usage. The free
daily quota is therefore a **cost control** as much as a monetization lever, which is why the quota
check runs before the provider call and why provider latency and failure rates are first-class
metrics (section 18.4).

---

## 25. Environment Strategy

### 25.1 Environments

| Environment | Backend | Database | Speech | Payments | Analytics | Mobile |
|-------------|---------|----------|--------|----------|-----------|--------|
| **development** | Local Docker Compose | Local Postgres container | `mock` by default; real Azure dev key optional | `mock` | `noop` | Debug flavor, points at localhost |
| **staging** | Deployed, production-like | Managed, separate instance | Real Azure (dev/test key) | RevenueCat sandbox, store sandbox accounts | Separate analytics project | TestFlight / Play internal, staging flavor |
| **production** | Deployed, min 2 instances once traffic warrants | Managed, backups + PITR | Real Azure (production key) | RevenueCat production | Production analytics project | Store releases |

Rules: environments never share a database or a secret; staging data is synthetic; production data is
never copied to a laptop; Flutter flavors (`dev`, `staging`, `prod`) carry distinct bundle IDs so all
three can coexist on one device.

### 25.2 Configuration variables

All configuration comes from the environment. No secret is committed; `.env.example` documents names
and formats with placeholder values only.

**Backend**

| Variable | Purpose | Example / format |
|----------|---------|------------------|
| `APP_ENV` | Environment name | `development` \| `staging` \| `production` |
| `PORT` | HTTP listen port | `8080` |
| `LOG_LEVEL` | Log verbosity | `debug` \| `info` \| `warn` \| `error` |
| `DATABASE_URL` | PostgreSQL DSN | `postgres://user:pass@host:5432/voca?sslmode=require` |
| `DATABASE_MAX_CONNS` | Pool size | `20` |
| `JWT_SECRET` | Access-token signing key | 32+ random bytes, base64 |
| `JWT_ACCESS_TTL` / `JWT_REFRESH_TTL` | Token lifetimes | `15m` / `1440h` |
| `SPEECH_PROVIDER` | Active speech adapter | `azure` \| `google` \| `mock` |
| `AZURE_SPEECH_KEY` | Azure subscription key | secret |
| `AZURE_SPEECH_REGION` | Azure region | `westeurope` |
| `AZURE_SPEECH_TIMEOUT` | Per-call budget | `10s` |
| `PAYMENT_PROVIDER` | Active payment adapter | `revenuecat` \| `mock` |
| `REVENUECAT_SECRET_KEY` | Server-side API key | secret |
| `REVENUECAT_WEBHOOK_SECRET` | Webhook verification | secret |
| `APPLE_BUNDLE_ID`, `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY` | Sign in with Apple verification | secret |
| `GOOGLE_IOS_CLIENT_ID`, `GOOGLE_ANDROID_CLIENT_ID`, `GOOGLE_WEB_CLIENT_ID` | Google token audience validation | public IDs |
| `ANALYTICS_PROVIDER` | Server-side analytics adapter | `posthog` \| `firebase` \| `noop` |
| `ANALYTICS_API_KEY`, `ANALYTICS_HOST` | Analytics credentials | secret / URL |
| `NOTIFICATION_PROVIDER` | Push adapter | `fcm` \| `noop` |
| `FCM_SERVICE_ACCOUNT_JSON` | FCM credentials | secret (JSON) |
| `CACHE_DRIVER` | Cache implementation | `memory` (MVP) \| `redis` |
| `REDIS_URL` | Redis DSN when enabled | `redis://host:6379/0` |
| `FREE_DAILY_ASSESSMENT_LIMIT` | Free-tier quota | `10` |
| `MAX_AUDIO_SIZE_BYTES`, `MAX_AUDIO_DURATION_MS` | Upload policy | `2097152`, `15000` |
| `SCORING_VERSION`, `SCORE_WEIGHT_ACCURACY/FLUENCY/COMPLETENESS` | Scoring policy | `v1`, `0.5`/`0.3`/`0.2` |
| `AUDIO_RETENTION_ENABLED` | Future audio storage switch | `false` |
| `SENTRY_DSN` | Error tracking | secret |
| `CORS_ALLOWED_ORIGINS` | Allowed origins | comma-separated |
| `RATE_LIMIT_*` | Limits per scope | integers |

**Mobile (compile-time, via `--dart-define` per flavor — public values only)**

`API_BASE_URL`, `APP_ENV`, `REVENUECAT_PUBLIC_SDK_KEY`, `ANALYTICS_PUBLIC_KEY`, `SENTRY_DSN`,
`GOOGLE_CLIENT_ID`. Firebase configuration files (`google-services.json`,
`GoogleService-Info.plist`) are per-flavor. **No server secret ever appears here** (section 18.2).

### 25.3 Feature flags

`GET /api/v1/config` returns remote flags and the minimum supported app version. This lets us dark-
launch a feature, disable a broken one, change free limits, and force upgrades without a store
release — which is the main lever we have against slow mobile release cycles.

---

## 26. Complete Repository Structure

```
voca/
├── .github/
│   └── workflows/
│       ├── backend-ci.yml
│       ├── mobile-ci.yml
│       ├── openapi-ci.yml
│       ├── deploy-staging.yml
│       └── deploy-production.yml
├── backend/                  # Go modular monolith (section 28)
├── mobile/                   # Flutter application (section 27)
├── docs/
│   ├── architecture/
│   │   ├── ARCHITECTURE.md   # this document
│   │   └── adr/              # ADR-001 … ADR-011 (section 32)
│   ├── api/
│   │   └── openapi.yaml      # the frozen API contract (authored at implementation start)
│   ├── database/
│   │   └── erd.md            # generated ERD + schema notes
│   ├── product/
│   │   ├── events.md         # analytics event catalogue
│   │   └── metrics.md        # metric definitions
│   └── runbooks/
│       ├── incident-response.md
│       ├── restore-from-backup.md
│       └── provider-outage.md
├── infra/
│   ├── docker/
│   │   └── backend.Dockerfile
│   ├── compose/
│   │   ├── docker-compose.dev.yml     # api + postgres (+ redis, off by default)
│   │   └── docker-compose.test.yml    # postgres for integration tests
│   ├── deploy/
│   │   └── <platform config>          # fly.toml / render.yaml
│   └── terraform/                     # reserved; empty until Stage 3
├── scripts/
│   ├── dev.sh                # start local stack
│   ├── migrate.sh
│   └── seed.sh
├── .gitignore
├── .editorconfig
├── Makefile                  # one entry point: make dev / test / lint / migrate / seed
└── README.md
```

| Directory | Responsibility |
|-----------|----------------|
| `.github/workflows` | All automation. Nothing is run manually that CI could run |
| `backend/` | The Go service; self-contained, own module, own tests |
| `mobile/` | The Flutter app; self-contained, own tests |
| `docs/architecture` | Design authority: this document plus decision records |
| `docs/api` | The contract both sides build against |
| `docs/database` | Schema documentation and ERD |
| `docs/product` | Event and metric definitions, so analytics stays consistent |
| `docs/runbooks` | What to do at 3am — written before launch, not after the first incident |
| `infra/` | Everything about running the system; no application code |
| `scripts/` | Developer ergonomics; a new developer should be productive with one command |

---

## 27. Flutter Folder Structure

```
mobile/
├── lib/
│   ├── main.dart                     # thin: bootstrap + runApp
│   ├── main_dev.dart                 # flavor entrypoints
│   ├── main_staging.dart
│   ├── main_prod.dart
│   ├── bootstrap.dart                # init: DI container, error handlers, analytics, crash reporting
│   │
│   ├── core/                         # shared infrastructure — no feature-specific logic
│   │   ├── config/
│   │   │   ├── app_config.dart       # values from --dart-define
│   │   │   ├── flavor.dart
│   │   │   └── remote_config.dart    # /api/v1/config: flags, min version, limits
│   │   ├── network/
│   │   │   ├── dio_client.dart
│   │   │   ├── interceptors/         # auth, refresh, request-id, retry, logging
│   │   │   ├── api_exception.dart
│   │   │   └── api_response.dart     # envelope parsing
│   │   ├── error/
│   │   │   ├── failure.dart          # typed failures the UI switches on
│   │   │   └── error_mapper.dart     # API error code -> Failure
│   │   ├── storage/
│   │   │   ├── secure_storage.dart   # tokens only
│   │   │   ├── key_value_store.dart
│   │   │   └── local_database.dart   # cached content/progress
│   │   ├── analytics/
│   │   │   ├── analytics_service.dart      # abstract port
│   │   │   ├── firebase_analytics_service.dart
│   │   │   ├── posthog_analytics_service.dart
│   │   │   ├── noop_analytics_service.dart
│   │   │   └── events.dart                 # typed event catalogue
│   │   ├── audio/
│   │   │   ├── audio_recorder.dart   # record with enforced format/duration
│   │   │   └── audio_player.dart     # reference pronunciation playback
│   │   ├── localization/
│   │   │   ├── l10n/app_uz.arb       # first UI language
│   │   │   ├── l10n/app_en.arb
│   │   │   └── message_keys.dart     # server message_key -> localized string
│   │   ├── theme/                    # tokens, typography, component themes
│   │   ├── widgets/                  # shared UI: buttons, score ring, empty/error states
│   │   ├── utils/                    # formatters, validators, extensions
│   │   └── di/
│   │       └── providers.dart        # root Riverpod providers (composition root)
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── datasources/auth_remote_data_source.dart
│   │   │   │   ├── datasources/auth_local_data_source.dart
│   │   │   │   ├── models/auth_tokens_dto.dart
│   │   │   │   └── repositories/auth_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/auth_session.dart
│   │   │   │   ├── repositories/auth_repository.dart      # interface
│   │   │   │   └── usecases/sign_in_with_apple.dart
│   │   │   └── presentation/
│   │   │       ├── controllers/auth_controller.dart
│   │   │       ├── pages/sign_in_page.dart
│   │   │       └── widgets/
│   │   ├── home/
│   │   ├── practice/                 # session setup, word list, practice flow
│   │   ├── pronunciation/            # record, submit, result, retry  (the core feature)
│   │   │   ├── data/                 # dtos + mappers for the result payload
│   │   │   ├── domain/               # PronunciationResult, WordResult, PhonemeResult, use cases
│   │   │   └── presentation/         # RecordScreen, ResultScreen, ScoreRing, PhonemeChip
│   │   ├── progress/                 # stats, streak, weak sounds
│   │   ├── subscription/             # paywall, purchase, restore, entitlement state
│   │   ├── profile/
│   │   └── settings/                 # language, accent, difficulty, goal, reminders
│   │
│   └── routing/
│       ├── app_router.dart           # GoRouter instance
│       ├── routes.dart               # route names/paths (typed)
│       └── guards.dart               # auth guard, premium guard (UI-level only)
│
├── test/
│   ├── core/
│   ├── features/<feature>/{domain,data,presentation}/
│   └── helpers/                      # fakes, fixtures, provider overrides
├── integration_test/
│   └── practice_flow_test.dart
├── assets/
│   ├── images/
│   ├── icons/
│   └── animations/
├── android/  ios/                    # platform projects (flavors, signing, permissions)
├── analysis_options.yaml             # strict lints; enforced in CI
├── pubspec.yaml
└── README.md
```

**Why this shape.** A new feature is a new folder with three subfolders and one route line, touching
no existing feature. A removed feature is a deleted folder plus one route line. That is what "feature
isolation" has to mean in practice for the roadmap in section 34 to be affordable.

---

## 28. Go Folder Structure

```
backend/
├── cmd/
│   ├── api/main.go               # API entrypoint: load config, build server, run, graceful shutdown
│   ├── migrate/main.go           # apply/rollback migrations
│   ├── seed/main.go              # load content seed data
│   └── worker/                   # RESERVED — created at Stage 3, same image, different entrypoint
│
├── internal/                     # private application code (Go forbids external import)
│   ├── config/
│   │   └── config.go             # typed config from environment; fails fast on missing values
│   ├── server/
│   │   ├── server.go             # http.Server, graceful shutdown, health endpoints
│   │   ├── router.go             # /api/v1 group; each module registers its routes
│   │   └── wire.go               # composition root: builds every dependency, injects everything
│   ├── middleware/
│   │   ├── request_id.go  logger.go  recovery.go  cors.go
│   │   ├── auth.go               # JWT -> user ID in context
│   │   ├── entitlement.go        # RequirePremium
│   │   ├── ratelimit.go
│   │   └── body_limit.go
│   ├── database/
│   │   ├── postgres.go           # pgxpool setup, health check
│   │   ├── tx.go                 # transaction helper used by services
│   │   └── sqlc/                 # generated code (never edited by hand)
│   │
│   ├── auth/                     # ── module: sign-in, tokens, sessions
│   │   ├── handler.go  routes.go  service.go  repository.go
│   │   ├── model.go  dto.go
│   │   ├── verifier.go           # Apple/Google identity token verification (interface + impls)
│   │   └── *_test.go
│   ├── user/                     # profiles, preferences, account deletion
│   ├── word/                     # content: words, categories, search, seeding
│   ├── practice/                 # sessions, items, PracticeSelector
│   ├── pronunciation/            # ── the core module
│   │   ├── handler.go  routes.go  dto.go
│   │   ├── service.go            # orchestrates the pipeline in section 6.1
│   │   ├── port.go               # SpeechProvider interface (owned here, not by the adapter)
│   │   ├── model.go              # PronunciationAttempt/Result/WordResult/PhonemeResult/Error/Feedback
│   │   ├── repository.go
│   │   ├── scoring/              # ScoringEngine + versioned policies
│   │   ├── analysis/             # phoneme/word error detection
│   │   ├── feedback/             # error -> Feedback (message keys, tips, examples)
│   │   ├── validation/           # audio validation rules
│   │   └── *_test.go
│   ├── progress/                 # daily progress, streaks, weak sounds, recommendations
│   │   ├── weaksound/            # WeakSoundService (section 15)
│   │   └── recommendation/
│   ├── subscription/             # entitlement, usage limits, webhooks
│   │   ├── port.go               # PaymentProvider interface
│   │   ├── usage_limiter.go
│   │   └── webhook_handler.go
│   ├── notification/             # device registry, reminder composition
│   │   └── port.go               # NotificationProvider interface
│   ├── analytics/                # server-side event emission
│   │   └── port.go               # AnalyticsProvider interface
│   │
│   ├── integrations/             # ── adapters: the ONLY place vendor SDKs appear
│   │   ├── speech/
│   │   │   ├── azure/{client.go,response.go,mapper.go,provider.go,testdata/}
│   │   │   ├── google/           # future
│   │   │   └── mock/
│   │   ├── payment/{revenuecat/,mock/}
│   │   ├── push/{fcm/,mock/}
│   │   ├── analytics/{posthog/,noop/}
│   │   └── storage/{noop/,s3/}   # AudioStore; noop in MVP
│   │
│   ├── jobs/                     # scheduler + thin job triggers (section 21)
│   ├── cache/                    # CacheStore interface + memory and redis implementations
│   └── shared/
│       ├── apperr/               # AppError, codes, HTTP mapping
│       ├── httpx/                # response envelope, pagination, binding helpers
│       ├── validator/
│       └── ctxutil/              # user ID / request ID accessors
│
├── pkg/                          # generic, reusable, no business logic, safe to extract
│   ├── logger/                   # slog setup
│   ├── jwt/                      # sign/verify helpers
│   └── idgen/                    # UUID generation
│
├── migrations/
│   ├── 000001_init.up.sql / .down.sql
│   ├── 000002_content.up.sql / .down.sql
│   └── seed/{categories.sql,words.sql}
│
├── docs/                         # module notes, generated sqlc docs
├── tests/
│   ├── integration/              # full-stack tests against real Postgres + mock providers
│   ├── fixtures/
│   └── testdata/                 # recorded provider payloads (golden files)
│
├── queries/                      # hand-written SQL consumed by sqlc
├── sqlc.yaml
├── .golangci.yml
├── Dockerfile -> ../infra/docker/backend.Dockerfile
├── Makefile
├── go.mod / go.sum
└── .env.example                  # names and formats only, never real values
```

**`internal/` vs `pkg/`.** Go refuses to let any code outside this module import `internal/`, which
is a compiler-enforced boundary around all business logic. `pkg/` holds genuinely generic helpers
with no product knowledge — the only things that would still make sense if lifted into another
repository. If something in `pkg/` needs a domain type, it belongs in `internal/`.

**Where a vendor may appear.** `internal/integrations/**` and nowhere else. A pull request that
imports an Azure, RevenueCat, or Firebase package anywhere else is rejected on that basis alone.

---

## 29. Database ERD Description

```mermaid
erDiagram
    USERS ||--|| PROFILES : "has one"
    USERS ||--|| USER_PREFERENCES : "has one"
    USERS ||--|| STREAKS : "has one"
    USERS ||--o{ DEVICES : "registers"
    USERS ||--o{ PRACTICE_SESSIONS : "starts"
    USERS ||--o{ PRONUNCIATION_ATTEMPTS : "submits"
    USERS ||--o{ PHONEME_RESULTS : "accumulates"
    USERS ||--o{ DAILY_PROGRESS : "accrues"
    USERS ||--o{ SUBSCRIPTIONS : "holds"

    CATEGORIES ||--o{ WORDS : "groups"
    WORDS ||--o{ PRACTICE_ITEMS : "is practised as"

    PRACTICE_SESSIONS ||--o{ PRACTICE_ITEMS : "contains"
    PRACTICE_ITEMS ||--o{ PRONUNCIATION_ATTEMPTS : "is attempted by"

    PRONUNCIATION_ATTEMPTS ||--o{ PHONEME_RESULTS : "breaks down into"
    PRONUNCIATION_ATTEMPTS ||--o{ FEEDBACK : "produces"

    SUBSCRIPTIONS ||--o{ SUBSCRIPTION_EVENTS : "logs"
```

Reading the diagram (column-level detail is in section 10):

- **`users` is the spine.** Identity, display data, and settings are three tables rather than one so
  that sensitive identity data, publicly displayable data, and frequently-changing settings evolve
  and are protected independently.
- **Content is separate from user data.** `categories` -> `words` has no dependency on any user
  table, so content can be seeded, updated, cached, and eventually served from a CDN without
  touching user data. Deleting a word is a soft `is_active = false`, never a cascade into history.
- **The practice chain is `session -> item -> attempt`.** One item has many attempts because retry is
  a core loop, and `practice_items.best_attempt_id` denormalizes the outcome the UI reads constantly.
- **`pronunciation_attempts` fans out two ways.** Downward into `phoneme_results` (a real table,
  because it is aggregated across attempts to find weak sounds) and into `feedback` (stored, so a
  learner's history does not change when we improve the rules). Word-level detail stays as JSONB on
  the attempt because it is only ever read together with it.
- **`user_id` is denormalized onto `pronunciation_attempts` and `phoneme_results`** so the two
  hottest queries in the product — "my history" and "my weak sounds" — are single-index lookups with
  no joins through sessions.
- **Money is split into state and log.** `subscriptions` holds one current row per user per store
  (fast entitlement reads); `subscription_events` is the append-only, idempotent audit trail that
  makes billing disputes and replays tractable.

---

## 30. API Endpoint Map

Compact reference; full contracts in section 11.

| Group | Method | Path | Auth |
|-------|--------|------|------|
| auth | POST | `/api/v1/auth/apple` | public |
| auth | POST | `/api/v1/auth/google` | public |
| auth | POST | `/api/v1/auth/refresh` | public |
| auth | POST | `/api/v1/auth/logout` | user |
| users | GET | `/api/v1/users/me` | user |
| users | PATCH | `/api/v1/users/me` | user |
| users | DELETE | `/api/v1/users/me` | user |
| users | GET | `/api/v1/users/me/preferences` | user |
| users | PUT | `/api/v1/users/me/preferences` | user |
| words | GET | `/api/v1/categories` | user |
| words | GET | `/api/v1/words` | user |
| words | GET | `/api/v1/words/{id}` | user |
| practice | POST | `/api/v1/practice/sessions` | user |
| practice | GET | `/api/v1/practice/sessions` | user |
| practice | GET | `/api/v1/practice/sessions/{id}` | user |
| practice | POST | `/api/v1/practice/sessions/{id}/complete` | user |
| pronunciation | POST | `/api/v1/pronunciation/attempts` | user |
| pronunciation | GET | `/api/v1/pronunciation/attempts` | user |
| pronunciation | GET | `/api/v1/pronunciation/attempts/{id}` | user |
| progress | GET | `/api/v1/progress/summary` | user |
| progress | GET | `/api/v1/progress/daily` | user |
| progress | GET | `/api/v1/progress/streak` | user |
| progress | GET | `/api/v1/progress/weak-sounds` | user |
| progress | GET | `/api/v1/progress/words/{word_id}` | user |
| subscriptions | GET | `/api/v1/subscriptions/me` | user |
| subscriptions | POST | `/api/v1/subscriptions/sync` | user |
| subscriptions | POST | `/api/v1/subscriptions/webhooks/revenuecat` | webhook signature |
| notifications | PUT | `/api/v1/notifications/devices` | user |
| notifications | DELETE | `/api/v1/notifications/devices/{token}` | user |
| notifications | PUT | `/api/v1/notifications/preferences` | user |
| system | GET | `/healthz` | public |
| system | GET | `/readyz` | public |
| system | GET | `/api/v1/config` | user |

Future groups slot in without disturbing these: `/api/v1/challenges`, `/api/v1/achievements`,
`/api/v1/leaderboard`, `/api/v1/conversations`.

---

## 31. Dependency Rules

### 31.1 Mobile

```mermaid
flowchart LR
    P[presentation<br/>widgets, controllers] --> D[domain<br/>entities, use cases, interfaces]
    DA[data<br/>DTOs, data sources, repo impls] --> D
    P -. forbidden .-> DA
    D -. depends on nothing .-> X[ ]
    style X fill:none,stroke:none
```

| Allowed | Forbidden |
|---------|-----------|
| `presentation` -> `domain` | `presentation` -> `data` |
| `data` -> `domain` | `domain` -> `data` or `presentation` |
| any feature -> `core` | `core` -> any feature |
| feature A -> feature B's **domain** only (rare, via DI) | feature A -> feature B's `data`/`presentation` |
| `domain` -> pure Dart only | `domain` -> Flutter, Dio, JSON, secure storage |

### 31.2 Backend

```mermaid
flowchart LR
    H[handler] --> S[service]
    S --> R[repository interface]
    S --> PT[provider port]
    R --> PG[(postgres impl)]
    PT --> AD[vendor adapter]
    H -. forbidden .-> R
    H -. forbidden .-> PG
    S -. forbidden .-> HTTP[gin.Context]
```

| Allowed | Forbidden |
|---------|-----------|
| `handler` -> `service` | `handler` -> repository, SQL, or vendor adapter |
| `service` -> repository interface, provider port, other modules' **service interfaces** | `service` -> `gin.Context`, `*pgxpool.Pool`, vendor SDK types |
| repository impl -> `database`, sqlc | repository -> business rules |
| adapter -> vendor SDK | anything outside `internal/integrations` -> vendor SDK |
| any module -> `internal/shared`, `pkg` | `internal/shared` or `pkg` -> any module |
| module A -> module B's exported service interface | module A -> module B's repository, models, or tables |

### 31.3 Enforcement

Rules that live only in a document decay. These are enforced mechanically:

- `internal/` visibility is enforced by the Go compiler.
- `.golangci.yml` includes `depguard` rules: vendor SDK imports allowed only under
  `internal/integrations/**`; `gin` imports forbidden in `service.go` files.
- Dart `analysis_options.yaml` plus an import-boundary lint keeps `domain` free of Flutter and
  keeps `presentation` out of `data`.
- Pull request review checks the cross-module rule (section 5.5), which is the one a linter cannot
  fully express.
- Circular dependencies are impossible between packages in Go by construction; where two modules
  appear to need each other, the resolution is a shared type in `internal/shared`, an interface
  owned by the consumer, or an event — never a mutual import.

---

## 32. Architecture Decision Records

Each decision below is recorded in full under `docs/architecture/adr/`, with context, alternatives,
rationale, and consequences. The table is the index; the files are the authority.

| ADR | Decision | Key alternative rejected | Primary reason |
|-----|----------|--------------------------|----------------|
| [ADR-001](adr/ADR-001-flutter-for-mobile.md) | Flutter for iOS and Android | React Native, native Kotlin + Swift | One codebase, one team, identical pronunciation UI on both platforms |
| [ADR-002](adr/ADR-002-go-for-backend.md) | Go with Gin | Node.js/NestJS, Python/FastAPI | Fast, low-memory, statically typed, trivial to deploy as one binary |
| [ADR-003](adr/ADR-003-modular-monolith.md) | Modular monolith | Microservices from day one | Matches team size and traffic; keeps extraction cheap without paying distributed-system costs now |
| [ADR-004](adr/ADR-004-postgresql.md) | PostgreSQL as the only datastore | MongoDB, MySQL, Postgres + a document store | Relational data, strong constraints, JSONB where documents help, arrays and GIN for phoneme queries |
| [ADR-005](adr/ADR-005-azure-speech.md) | Azure Speech Pronunciation Assessment as first provider | Google STT, Speechace, self-hosted models | Only mature managed API giving word- and phoneme-level scores out of the box |
| [ADR-006](adr/ADR-006-provider-abstraction.md) | All third parties behind ports we own | Direct SDK use in services | Vendor replacement, testability, and cost control depend on it |
| [ADR-007](adr/ADR-007-revenuecat.md) | RevenueCat for subscriptions | Direct StoreKit + Play Billing server integration | Removes receipt validation and lifecycle edge cases that are pure risk, no differentiation |
| [ADR-008](adr/ADR-008-rest-api.md) | REST over JSON | GraphQL, gRPC | Simple, cacheable, debuggable, well supported by Dio and Gin; no over-fetching problem at this size |
| [ADR-009](adr/ADR-009-api-versioning.md) | URL path versioning `/api/v1` | Header or query versioning, no versioning | Mobile clients cannot be force-updated; old versions must keep working |
| [ADR-010](adr/ADR-010-redis-optional.md) | Redis designed for, not deployed at MVP | Redis from day one; never | Avoids an unnecessary component while keeping the seam through `CacheStore` |
| [ADR-011](adr/ADR-011-no-microservices-initially.md) | No microservices, no Kubernetes, no Kafka at MVP | Service-per-domain now | Operational cost and debugging pain vastly exceed benefit before real scale |

---

## 33. Scalability Plan

Scaling decisions are staged by user count, with an explicit trigger for each change, so nothing is
built early and nothing is discovered late.

### Stage 1 — MVP (0 to a few hundred users)

| Aspect | State |
|--------|-------|
| API | 1 instance, single Docker container |
| Database | 1 managed PostgreSQL instance, daily backups + PITR |
| Cache | None (`CACHE_DRIVER=memory`) |
| Jobs | In-process cron, advisory-locked |
| Assessment | Synchronous, direct to Azure |
| Focus | Correctness, product-market fit, cost per assessment |

Bottleneck to watch: Azure cost per active user, not CPU.

### Stage 2 — ~1,000 users

**Triggers:** more than one API instance needed for deploys or availability; quota `COUNT` queries
appearing in slow-query logs.

| Change | Why |
|--------|-----|
| 2+ API instances behind the platform load balancer | Zero-downtime deploys and redundancy; possible because the app is stateless (section 24.4) |
| `CACHE_DRIVER=redis` (managed Redis) | Rate limits and quota counters become incorrect across instances without shared state |
| Cache content and entitlement reads (60 s TTL) | Removes the most repeated queries |
| CDN in front of reference audio | Bandwidth and latency |
| Index review with real query plans | First real data on access patterns |
| Alerting on provider latency and error rate | Vendor health becomes a business risk here |

**Unchanged:** module boundaries, API contract, schema shape, deployment model, mobile app.

### Stage 3 — ~10,000 users

**Triggers:** p95 API latency drifting; push fan-out blocking request threads; reporting queries
competing with user traffic.

| Change | Why |
|--------|-----|
| `cmd/worker` deployed from the same image, Redis-backed queue (`asynq`) | Notification fan-out, subscription reconciliation, and aggregation move off the request path |
| Read replica for progress/analytics queries | Isolates heavy reads from the write path |
| `user_phoneme_stats` rollup table maintained by a job | Weak-sound aggregation stops scanning raw phoneme rows |
| Connection pooling (PgBouncer) and pool tuning | Connection count becomes the limiting factor before CPU does |
| Distributed tracing on the existing correlation IDs | The seam from section 18.4 is finally cashed in |
| Consider partitioning `pronunciation_attempts` and `phoneme_results` by month | These two tables grow fastest and are queried by recent time ranges |

**Unchanged:** still one API codebase, still one deployable service, still one database.

### Stage 4 — 100,000+ users

**Triggers:** independent scaling profiles, or independent teams, or a deploy cadence conflict.
Not user count alone.

| Change | Why |
|--------|-----|
| Extract `pronunciation` first | Highest traffic, heaviest external I/O, most distinct scaling and cost profile |
| Extract `notification` second | Queue-shaped, bursty, unrelated to request latency |
| API gateway in front; service-to-service auth | Only now is there more than one service to route to |
| Event broker for cross-service flows | Only once services genuinely need to react to each other |
| Database split per extracted service, or schema separation | Evaluate then; shared-schema-with-clear-ownership is often still correct |

Extraction is cheap precisely because of section 5.5: `pronunciation` already talks to
`subscription` through one service interface, never through its tables. Replacing that call with an
HTTP client behind the same interface is a contained change.

### What must never change across all four stages

The provider ports (`SpeechProvider`, `PaymentProvider`, `AnalyticsProvider`,
`NotificationProvider`, `CacheStore`, `AudioStore`); the pronunciation domain model; the `/api/v1`
contract; the rule that handlers stay thin and business logic lives in services; the rule that the
backend is the source of truth for entitlement; and the mobile app's ignorance of every vendor
except the ones it must embed by nature (RevenueCat SDK, Firebase, sign-in SDKs).

---

## 34. Future Feature Integration Strategy

Each roadmap feature is listed with the change it actually requires. The point of the table is that
no row says "rewrite".

| Feature | Backend change | Mobile change | Schema change | Rewrite risk |
|---------|----------------|---------------|---------------|--------------|
| Phrase / sentence practice | New `content_type` values; `PracticeSelector` variant | New practice sub-feature reusing the record/result widgets | `phrases`/`sentences` tables; `practice_items` gains `content_type` + `content_id` | None — `SpeechProvider` already takes arbitrary reference text |
| Multiple accents (en-GB, en-AU) | Pass `accent` to the provider (already in `AssessmentInput`) | Accent picker in settings | Rows per accent in `words`; `accent` already a column | None |
| Multiple UI languages | None — feedback is already message keys | New ARB file | None | None |
| Multiple learning languages | `language` already on content and in provider input | Language picker | `word_translations` table when meanings need N languages | Low |
| IELTS / business / travel / academic sets | None | New category browsing entry point | Categories + `tags` table for multi-set membership | None — content, not code |
| Weak-sound training mode | `PracticeSelector` weak-sound strategy (data already captured) | New practice entry point | None — `target_phonemes` and `phoneme_results` exist | None |
| Adaptive difficulty / personalization | New `PracticeSelector` implementation, chosen by flag | None | Optional model/state table | None — the interface exists for this reason |
| Daily challenge, streaks freezes | New module reusing progress data | New feature folder | Small tables; `streak_freeze_count` already reserved | None |
| Achievements | New `achievements` module consuming existing events | New feature folder | `achievements`, `user_achievements` | None |
| Leaderboard | New module; Redis sorted sets | New feature folder | Optional snapshot table | None — Redis seam already defined |
| Social features | New module; public data already isolated in `profiles` | New feature folder | `follows` / `friends` | Low |
| Conversation practice / AI speaking coach | New module and a **new port** (`ConversationProvider`), parallel to `SpeechProvider` | New feature folder | Conversation/session tables | None to pronunciation — a sibling capability, not a modification |
| Audio playback of past attempts | Implement `AudioStore`, set `AUDIO_RETENTION_ENABLED=true`, add consent | Playback in history | `audio_key` column on attempts | None — seam defined in section 12.3 |
| Web app | Reuse the same `/api/v1` | New client | None | None — no API assumption is mobile-specific |
| Custom or hybrid scoring model | New `ScoringEngine` implementation, new `scoring_version` | None | None | None — versioned scores make this safe |

The recurring pattern: every future feature is a **new folder plus rows plus configuration**. That
outcome is the product of decisions made now — phoneme capture from day one, `target_phonemes` in
the schema, message keys instead of sentences, ports for vendors, `content_type` and `accent` and
`language` columns that currently hold one value each.

---

## 35. MVP vs Future Components

| Component | MVP | Later | Why deferred |
|-----------|-----|-------|--------------|
| Apple + Google sign-in | Yes | — | Store expectation, no password handling |
| Email/password auth | No | Yes | Adds reset flows, verification, and breach risk for no MVP gain (schema reserved) |
| Word practice | Yes | — | The core loop |
| Phrase/sentence practice | No | Yes | Content and UI cost; model already supports it |
| Azure assessment | Yes | — | Core value |
| Second speech provider | No | If cost/quality demands | Port exists; adding one is an adapter |
| Word + phoneme feedback | Yes | — | The differentiator |
| Weak-sound **capture** | Yes | — | History cannot be created retroactively |
| Weak-sound **screen and training mode** | No | Yes | Needs accumulated data to be meaningful |
| Streaks and daily progress | Yes | — | Retention mechanism |
| Free quota + premium tier | Yes | — | Cost control and revenue |
| Trials, restore, webhooks | Yes | — | Required for correct billing from day one |
| Push: daily + streak reminders | Yes | — | Primary retention lever |
| Rich notification campaigns | No | Yes | Needs a worker and segmentation |
| Analytics (client + server events) | Yes | — | Cannot measure retroactively |
| Redis | No | Stage 2 | Unneeded component; seam in place |
| Job queue + worker process | No | Stage 3 | Cron covers MVP jobs |
| Audio storage | No | On demand | Privacy, cost, and obligation with no MVP benefit |
| Admin CMS for content | No | Yes | Seed scripts are honest at this size |
| Read replicas, partitioning, PgBouncer | No | Stage 3 | Premature |
| Microservices, Kubernetes, Kafka | No | Stage 4 at the earliest | ADR-011 |
| Leaderboard, achievements, social | No | Yes | Post product-market fit |
| Crash reporting + structured logs | Yes | — | Cheap, and indispensable at launch |

---

## 36. Technical Risks

| # | Risk | Impact | Likelihood | Mitigation |
|---|------|--------|-----------|------------|
| 1 | **Azure per-assessment cost scales linearly with engaged users** and can outrun revenue | High | High | Quota checked before the provider call; cost per user tracked as a first-class metric; premium priced against measured cost; provider port allows switching |
| 2 | **Provider scores are unreliable for Uzbek-accented speech**, frustrating users or flattering them | High | Medium | Scores treated as a signal with a `ScoringEngine` and `scoring_version` between provider and product; confidence value; calibration possible without schema change; validate with real Uzbek speakers **before** freeze |
| 3 | **Device audio variability** (microphones, noise, codecs) depresses scores unfairly | High | High | Strict capture spec, server-side validation, min-duration rejection, silence/clipping detection feeding `confidence`; test matrix across cheap Android devices |
| 4 | **Provider latency makes the core loop feel slow** | Medium | Medium | 10 s budget, one retry, latency metric from day one, explicit in-app progress state; async submission mode only if data demands it |
| 5 | **Provider outage** blocks the only revenue-generating action | High | Low | Failed attempts persisted, quota not consumed, clear retry UX; failure-rate metric; second adapter is a known, scoped project |
| 6 | **Subscription edge cases** (refunds, grace periods, family sharing, restores) grant or revoke access wrongly | High | Medium | RevenueCat plus idempotent webhooks, append-only event log, expiry sweep, reconciliation job, server-side entitlement only |
| 7 | **Content depth insufficient** for levels and categories at launch | Medium | High | Seed dataset sized and reviewed before implementation; `frequency_rank`, CEFR, and `target_phonemes` populated from the start |
| 8 | **Modular monolith discipline erodes** into a big ball of mud, destroying the extraction path | High | Medium | `depguard` lint rules, `internal/` boundaries, cross-module rule in review, this document as the reference |
| 9 | **Refresh-token theft or replay** | High | Low | Rotation with reuse detection, hashed storage, secure device storage, revocation on logout and deletion |
| 10 | **Quota bypass via a patched client** | Medium | Medium | All enforcement server-side; client flags cosmetic only |
| 11 | **App Store / Play review rejection** (account deletion, purchase flows, permissions rationale) | Medium | Medium | Account deletion, restore purchases, and permission rationale built in from the start, not retrofitted |
| 12 | **Uzbek localization gaps** in coaching text | Medium | Medium | Message-key architecture; translation completeness checked in CI |
| 13 | **Single database is a single point of failure** | High | Low | Managed instance, PITR, and a **restore drill executed before launch** |
| 14 | **Scope creep into gamification/social before retention is proven** | Medium | High | Section 35 is the agreed line; changing it is a decision, not a drift |

---

## 37. Recommended Implementation Order

Sequenced so that each step is shippable, testable, and unblocks the next. The core loop is reached
as early as it can be honestly reached, because everything downstream depends on real assessment
data existing.

| # | Step | Delivers | Depends on |
|---|------|----------|------------|
| 0 | **Freeze this architecture** (checklist below), author `openapi.yaml`, agree the seed content plan | An agreed contract both sides build against | — |
| 1 | Repo scaffolding: monorepo layout, Makefile, Docker Compose, CI skeletons, lint and `depguard` rules | A green pipeline before any feature code | 0 |
| 2 | Backend skeleton: config, pgx pool, migrations, router, middleware chain, error envelope, `/healthz` and `/readyz` | A deployable empty service; deploy it to staging now | 1 |
| 3 | `auth` + `user`: Apple/Google verification, JWT + refresh rotation, profiles, preferences, account deletion | Real accounts | 2 |
| 4 | `word` module + content seed: categories, words, phonetics, `target_phonemes`, audio URLs | Something to practise | 2 |
| 5 | Mobile core: flavors, DI, Dio + interceptors, secure storage, routing, theme, Uzbek localization, analytics port | The app shell | 1 |
| 6 | Mobile `auth` + `home`: sign-in, session handling, guarded routes | Users can get in | 3, 5 |
| 7 | `practice` module + mobile practice feature: sessions, items, selector, word list, playback of reference audio | The loop up to the microphone | 4, 6 |
| 8 | **`pronunciation` module**: `SpeechProvider` port, mock adapter, Azure adapter + mapper with golden tests, scoring, analysis, feedback, persistence | The product's core, testable without Azure first | 7 |
| 9 | Mobile `pronunciation` feature: recording to spec, upload, result screen, phoneme breakdown, retry | The complete core loop, end to end | 8 |
| 10 | `progress` module + mobile progress: daily progress, streaks, improvement, history | Reason to come back tomorrow | 9 |
| 11 | `subscription` module: RevenueCat adapter, entitlement, `UsageLimiter`, webhooks, paywall, restore | Revenue and cost control | 9 |
| 12 | `notification` module: device registry, daily and streak reminders, scheduler jobs | Retention | 10 |
| 13 | Weak-sound service and screen (data has been accumulating since step 8) | The differentiator | 10 |
| 14 | Hardening: rate limits, upload validation edge cases, error taxonomy sweep, crash reporting, dashboards, load test, **backup restore drill** | Production readiness | 11, 12 |
| 15 | Store preparation: privacy labels, account deletion review, screenshots, TestFlight and internal testing round | Submission | 14 |
| 16 | Launch, then measure: quota pressure, conversion, retention, provider cost per user, score distributions | Data for the first real decisions | 15 |

Two sequencing choices worth stating explicitly. **Step 8 builds the mock adapter before the Azure
adapter**, so the entire pipeline, scoring, feedback, and mobile result screen can be built and
tested without spending a cent or waiting on vendor access. And **step 13 ships late but its data
starts at step 8**, which is the single most important scheduling decision in this plan.

---

## Architecture Freeze Checklist

Review and approve each item before writing production code. An unchecked box is a decision that is
still open, and open decisions are far cheaper to close now than after implementation.

### Product and scope

- [ ] MVP scope confirmed: word practice only, Uzbek UI, en-US accent, free quota plus one premium tier
- [ ] Free daily assessment limit agreed as a number, and it is a configuration value
- [ ] Premium feature list agreed (what exactly a subscriber gets beyond volume)
- [ ] Seed content plan agreed: how many words, which categories, which CEFR levels, who writes the phonetics and meanings
- [ ] Reference audio source agreed (recorded, licensed, or generated) and licensing cleared

### Core technical decisions

- [ ] Modular monolith accepted, with the cross-module rule in section 5.5 understood by everyone who will write code
- [ ] Module list frozen: `auth`, `user`, `word`, `practice`, `pronunciation`, `progress`, `subscription`, `notification`, `analytics`
- [ ] Mobile layering accepted: feature-based `data`/`domain`/`presentation`, `domain` free of Flutter
- [ ] Go stack confirmed: Gin, pgx, sqlc, golang-migrate, `log/slog`
- [ ] All eleven ADRs read and approved, or amended

### Pronunciation and AI

- [ ] `SpeechProvider` interface signature approved, with no vendor types in it
- [ ] Pronunciation domain model approved as our own, not a mirror of Azure's payload
- [ ] Azure account, region, pricing tier, and quota limits confirmed; cost per assessment known
- [ ] **Azure assessment validated against real Uzbek-accented speech samples** before freeze
- [ ] Scoring formula and weights agreed for `scoring_version = v1`
- [ ] Weak-sound thresholds agreed as configuration, with the "minimum 5 observations" rule accepted
- [ ] Phoneme normalization to IPA agreed as the storage standard

### Data

- [ ] Full schema in section 10 reviewed table by table
- [ ] JSONB for word-level results and a table for phoneme results accepted, with the reasoning understood
- [ ] `user_id` denormalization on attempts and phoneme results accepted
- [ ] Soft-delete policy accepted: `users` and `words` only
- [ ] Timezone handling for streaks and daily goals accepted
- [ ] Retention policy written: what is kept, for how long, what deletion removes

### API and contract

- [ ] Endpoint map approved; nothing critical missing for the MVP screens
- [ ] Error code list approved and agreed as the localization key set for the app
- [ ] `/api/v1` additive-only versioning policy accepted
- [ ] Idempotency behaviour on attempt submission agreed
- [ ] Owner assigned for authoring `openapi.yaml` before implementation starts

### Security and privacy

- [ ] Token model approved: 15-minute access JWT, rotating opaque refresh token with reuse detection
- [ ] Confirmed: no Azure key, RevenueCat secret, or database credential will exist in the app
- [ ] Audio limits agreed: format, sample rate, max duration, max size
- [ ] **No-audio-retention decision confirmed** for MVP, with `AudioStore` reserved
- [ ] Never-log list (section 18.4) accepted and added to the review checklist
- [ ] Account deletion behaviour approved and store-compliant
- [ ] Secret management approach agreed for each environment

### Monetization

- [ ] RevenueCat account, products, offerings, and entitlement identifiers defined
- [ ] Pricing and trial length decided
- [ ] Webhook verification method confirmed, and idempotency accepted
- [ ] Agreed and documented: the backend is the only authority on entitlement

### Operations

- [ ] Deployment option B (managed container platform plus managed Postgres) approved, or an alternative chosen
- [ ] Hosting region chosen, weighed against Azure region latency
- [ ] Three environments provisioned, with separate databases and separate secrets
- [ ] Backup schedule set and a **restore drill scheduled before launch**
- [ ] Alert thresholds agreed for error rate, p95 latency, and provider failure rate
- [ ] Analytics provider chosen and the event catalogue in section 16.3 approved
- [ ] Metric definitions in section 16.4 agreed, so launch numbers are not argued about afterwards

### Process

- [ ] Monorepo and trunk-based branching accepted
- [ ] CI gates agreed, including "CI never calls a real provider"
- [ ] Test expectations accepted, especially the five highest-value backend test suites in section 22.1
- [ ] Implementation order in section 37 accepted, or resequenced deliberately
- [ ] Owner assigned per module
- [ ] This document's location agreed as the place decisions are updated when they change

---

**When every box above is checked, the architecture is frozen and implementation begins at step 1 of
section 37.** Changes after freeze are welcome, but they arrive as an amendment to this document
plus a new ADR, so the reasoning stays recoverable.
