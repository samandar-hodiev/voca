-- Pronunciation attempts, phoneme results and feedback.
--
-- Follows the conventions in 000001: UUID keys, timestamptz, text + CHECK instead of
-- native enums, because widening a CHECK is trivial while altering an enum locks.
--
-- The asymmetry between word results and phoneme results is deliberate (docs/database/erd.md):
-- word-level results are read only ever together with their attempt, so they live as JSONB
-- on the attempt; phoneme results are aggregated ACROSS attempts to find weak sounds, so
-- they are a real table with a real index.
--
-- user_id is denormalized onto phoneme_results and feedback so the two hottest queries in
-- the product — "my history" and "my weak sounds" — are single-index lookups with no join.

-- ---------------------------------------------------------------------------
-- pronunciation_attempts: one recording, assessed
-- ---------------------------------------------------------------------------
CREATE TABLE pronunciation_attempts (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,

    -- What the learner was asked to say, and in which language it was assessed.
    reference_text  text NOT NULL,
    language        text NOT NULL DEFAULT 'en-US',

    -- Which provider produced the signal, and which scoring policy turned it into our
    -- numbers. Both are recorded so old rows stay interpretable after either changes.
    provider        text NOT NULL,
    scoring_version text NOT NULL,

    status          text NOT NULL CHECK (status IN ('scored', 'failed')),

    -- Our scores, 0-100. Null on a failed attempt.
    accuracy_score      numeric(5,2),
    fluency_score       numeric(5,2),
    completeness_score  numeric(5,2),
    overall_score       numeric(5,2),

    -- What the provider heard, and the per-word breakdown as it was at the time.
    recognized_text text,
    word_results    jsonb NOT NULL DEFAULT '[]'::jsonb,

    audio_duration_ms integer,

    created_at      timestamptz NOT NULL DEFAULT now()
);

-- "My history", newest first.
CREATE INDEX pronunciation_attempts_user_idx
    ON pronunciation_attempts (user_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- phoneme_results: the rows the weak-sound service aggregates
-- ---------------------------------------------------------------------------
CREATE TABLE phoneme_results (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id     uuid NOT NULL REFERENCES pronunciation_attempts (id) ON DELETE CASCADE,
    user_id        uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,

    -- The IPA symbol and the word it was heard in.
    phoneme        text NOT NULL,
    word           text NOT NULL,
    accuracy_score numeric(5,2) NOT NULL,

    created_at     timestamptz NOT NULL DEFAULT now()
);

-- "My weak sounds": every row this person has ever produced for a given phoneme.
CREATE INDEX phoneme_results_user_phoneme_idx
    ON phoneme_results (user_id, phoneme);

CREATE INDEX phoneme_results_attempt_idx ON phoneme_results (attempt_id);

-- ---------------------------------------------------------------------------
-- feedback: what the learner is told, and why
-- ---------------------------------------------------------------------------
-- Message KEYS, never finished sentences: the Uzbek and Russian text lives in the app's
-- ARB files, so adding a language is a translation task rather than a backend change.
--
-- Persisted rather than regenerated, so improving the rules later does not retroactively
-- rewrite what a learner was told last week.
CREATE TABLE feedback (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id   uuid NOT NULL REFERENCES pronunciation_attempts (id) ON DELETE CASCADE,
    user_id      uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,

    message_key  text NOT NULL,
    tip_key      text,

    -- What the advice is about. Either may be null: some advice is about the utterance.
    word         text,
    phoneme      text,

    -- Lower sorts first on screen.
    priority     integer NOT NULL DEFAULT 100,

    created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX feedback_attempt_idx ON feedback (attempt_id, priority);
