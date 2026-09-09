# ADR-005: Azure Speech Pronunciation Assessment as the first provider

- **Status:** Proposed
- **Date:** 2026-09-09
- **Related:** [ADR-006](ADR-006-provider-abstraction.md)

## Context

The product's core promise is telling a learner not just *that* their pronunciation was wrong but
*which sound* was wrong and how to fix it. That requires word-level and phoneme-level scoring, not
transcription. Building this ourselves would mean acoustic models, forced alignment, and a training
pipeline, which is a research programme rather than an MVP.

## Decision

Use **Microsoft Azure Speech Pronunciation Assessment** as the initial `SpeechProvider`
implementation, accessed server-side only, behind the interface defined in ADR-006.

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| **Google Cloud Speech-to-Text** | Excellent transcription, but no first-class pronunciation assessment with accuracy, fluency, completeness, and per-phoneme scores. We would have to derive scores ourselves from alignment and confidence, which is precisely the hard part |
| **Speechace / ELSA-style specialist APIs** | Purpose-built and strong at exactly this task; kept as a serious alternative. Azure wins initially on pricing transparency, regional availability, documentation, and enterprise stability. This is a decision to revisit with real cost and quality data |
| **Self-hosted (Kaldi, Whisper + forced alignment, wav2vec2)** | No per-assessment cost and full control, but requires GPU infrastructure, ML expertise, and calibration work before it produces a usable score. Wrong stage entirely |
| **On-device assessment** | Attractive for cost and privacy, but current on-device quality for phoneme-level scoring is insufficient, and it would put our scoring logic in a client we cannot update quickly |

## Rationale

Azure returns exactly the shape the product needs (overall, accuracy, fluency, completeness, plus
word and phoneme detail) from a managed API with predictable pricing, so the MVP can focus on the
learning experience rather than on speech science.

Two constraints are attached to this decision. First, Azure is called **only from the backend**;
the key never exists in the app. Second, its output is treated as an **assessment signal, not
ground truth** — the `ScoringEngine` sits between Azure and the product precisely because a model
tuned on other speakers may not judge Uzbek learners fairly.

## Consequences

**Positive:** phoneme-level feedback available immediately; no ML infrastructure; predictable
per-call cost; mature SDK and documentation.

**Negative:** per-assessment cost scales with engagement and is the dominant runtime cost driver;
we depend on a vendor's availability, latency, and pricing; scoring quality for Uzbek-accented
English is unproven until we test it; assessment requires network connectivity.

**Mitigations:** quota enforced before the provider call; provider latency and error rate tracked
from day one; `scoring_version` on every stored attempt; and the provider port (ADR-006) keeps a
switch to Google or a specialist vendor to an adapter-sized project.

**Open item before freeze:** validate assessment quality against recorded Uzbek-accented speech.
