# ADR-016: Curated content plus reviewed AI candidates

- **Status:** Proposed
- **Date:** 2026-09-09
- **Related:** [ADR-004](ADR-004-postgresql.md), [ADR-015](ADR-015-ai-provider-abstraction.md)

## Context

Voca needs a lot of learning content: words with accurate IPA transcriptions, target
phonemes, CEFR ratings, Uzbek meanings, example sentences and reference audio. Producing
this by hand is slow. A language model can produce it in bulk, which raises the question of
how much of the product's content should be generated, and when.

## Decision

A hybrid pipeline. Content is stored in PostgreSQL and owned by the backend. AI may
**propose** candidates; those candidates pass automatic validation, then human review in the
admin, and only content with status `published` is ever served to a learner.

Statuses: `draft`, `pending_review`, `approved`, `published`, `rejected`, `unpublished`.

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| **Generate content at request time from the model** | Makes the product non-deterministic: two learners at the same level get different material, and nobody can reproduce a bug. Adds model latency and per-request cost to the core loop. Nothing can be reviewed, corrected, or guaranteed. A wrong IPA transcription would teach a learner to mispronounce a word, with no record of where it came from |
| **Fully curated, no AI** | Safest and the slowest. Content depth is a launch risk already (section 36, risk 7). Refusing AI assistance for the first draft trades a manageable risk for a schedule problem |
| **Generate in bulk and publish without review** | Removes the only safeguard that matters. A model produces confident, well-formed, wrong output, and phonetics is exactly the domain where wrong is invisible to a non-expert |

## Rationale

**A language model is not a database.** It is a drafting tool. The product's guarantee to a
learner is that what they are taught is correct, and that guarantee requires a human name
attached to it.

The pipeline puts AI where it is strong, producing a first draft at volume, and puts people
where they are irreplaceable, judging correctness. Automatic validation between the two
removes the obvious failures cheaply, so review time is spent on judgement rather than on
catching malformed rows.

Provenance is recorded for every generated row: provider, model, prompt version, timestamp,
and approving admin. Two reasons. If a model turns out to produce subtly wrong phonetics, we
must be able to find every row it touched. And an approval with nobody's name on it is not
accountability.

## Consequences

**Positive:** content stays reviewable, correctable and reproducible; the learner experience
is deterministic; a bad generation run is contained in a queue rather than in the product;
content can be produced far faster than by hand alone.

**Negative:** review is a human bottleneck and needs someone's time; the moderation queue is
an admin feature that must exist before generation is useful; extra status and provenance
columns; a rejected batch is wasted spend.

**Not implemented:** no moderation tables, no status columns, no generation. MVP content
comes from seed scripts (section 13.4). This record exists so the seed schema is designed
with the status column it will need, rather than migrated under pressure later.
