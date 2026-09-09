# ADR-015: A separate AIProvider port alongside SpeechProvider

- **Status:** Proposed
- **Date:** 2026-09-09
- **Related:** [ADR-005](ADR-005-azure-speech.md), [ADR-006](ADR-006-provider-abstraction.md), [ADR-016](ADR-016-hybrid-content-pipeline.md)

## Context

Voca uses AI for two unrelated jobs. Pronunciation assessment scores a recording against a
reference text, and is already abstracted as `SpeechProvider` (ADR-005, ADR-006). Content
generation and learning recommendation ask a language model to produce or rank material.

These look similar from a distance and behave nothing alike.

## Decision

Define a second port, `AIProvider`, owned by the content and recommendation services, with
adapters under `internal/integrations/ai/<vendor>/` and a mock implementation. Selection is
by configuration, exactly as for every other provider.

`SpeechProvider` stays untouched and unmerged.

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| **One combined `AIProvider` covering both** | Different vendors, different cost models, different latency budgets, different failure behaviour, different tests. A combined interface forces every implementation to answer calls it has no business answering, and Azure Speech would have to stub out content generation |
| **Call the vendor SDK directly from the content service** | Contradicts ADR-006, makes tests require network and spend, and lets vendor vocabulary into the domain |
| **No abstraction until the feature is built** | The point of deciding now is that the content schema and the moderation pipeline are being designed now. Deciding later means designing them twice |

## Rationale

The two capabilities fail in fundamentally different ways, and that difference is what
justifies two ports. A speech assessment returns numbers that may be miscalibrated. A
language model returns text that is confident, well-formed, and sometimes simply wrong.
Different guardrails follow, and they belong in different places.

The rules specific to generative AI, stated in section 40.3, exist because of that
difference: output is always a candidate rather than published content, every response is
schema-validated inside the adapter, generation never runs on the learner request path, cost
and tokens are recorded per call, prompts are versioned like `scoring_version`, and no
personal data is ever placed in a prompt.

## Consequences

**Positive:** vendors are replaceable per capability; tests and CI never call a real model
and never spend money; cost is measurable per call before it becomes a surprise; the
pronunciation path is entirely unaffected by anything that happens in generation.

**Negative:** two provider abstractions to understand and maintain; a genuinely unified
future vendor would be adapted twice; prompt versioning adds bookkeeping.

**Not implemented:** there is no AI adapter, no generation endpoint, and no prompt in the
repository. This record defines the shape so adding it later is an adapter plus a service.
