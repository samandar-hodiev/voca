# ADR-013: Next.js with TypeScript and Tailwind for the admin dashboard

- **Status:** Proposed
- **Date:** 2026-09-09
- **Related:** [ADR-001](ADR-001-flutter-for-mobile.md), [ADR-014](ADR-014-admin-uses-backend-api-only.md)

## Context

The owner needs a web application to moderate content, inspect learners, read analytics and
watch system health. It is an internal tool with a handful of users and a heavy data-display
workload: wide tables, filters, charts, forms, keyboard use.

Flutter is already in the repository, so reusing it is the obvious instinct.

## Decision

Build the admin as a separate Next.js application using TypeScript and Tailwind CSS, in
`admin/`, sharing no UI code with the Flutter app.

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| **Flutter Web** | Tempting because the team already knows Flutter, and wrong for this workload. Flutter Web renders to a canvas, which fights the things a data tool needs most: text selection, copy and paste, browser find, printing, screen readers, deep linking, and large scrollable tables. Initial bundle size is poor for a tool opened occasionally. The supposed code reuse is largely illusory: a moderation queue shares nothing real with a pronunciation practice screen |
| **Plain React SPA (Vite)** | Perfectly workable and lighter than Next.js. Next.js is chosen for routing, server components, and a deployment story that comes free, without needing to assemble a router, a build config and a hosting setup by hand |
| **Server-rendered Go templates in the existing backend** | No new toolchain, no second deployment. But it couples the admin's release cycle to the API, mixes presentation into a service that should stay a pure API, and makes an interactive data tool considerably harder to build |
| **An off-the-shelf admin panel (Retool, Forest, Directus)** | Fast to start. It typically wants direct database access, which ADR-014 forbids, and the interesting screens here are pronunciation and phoneme analytics, which no generic panel understands |

## Rationale

The admin's job is displaying dense data in a browser, and React with Tailwind is the
best-supported way to do that. TypeScript gives compile-time safety on the API boundary, and
types can be generated from the OpenAPI contract, so a backend field rename breaks the admin
build rather than a production screen.

Accepting a second language and toolchain is a real cost, and it is paid deliberately: the
alternative is fighting a canvas renderer for the lifetime of the tool.

## Consequences

**Positive:** the right tool for data-dense web UI; generated types close the contract gap; a
large component ecosystem; independent deployment as a static or edge-rendered bundle;
independent release cadence.

**Negative:** a second language, toolchain and dependency tree to maintain and patch; the
team must know both Dart and TypeScript; design tokens must be kept consistent across two
implementations by discipline rather than by a compiler (section 44).

**Deliberately not done now:** no project is initialized. `admin/` holds a structural
scaffold only; `create-next-app` generates the configuration when implementation begins
(section 38.7).
