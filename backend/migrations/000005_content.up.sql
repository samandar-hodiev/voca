-- Content and practice sessions.
--
-- The word list is the product's raw material, and until now it lived hardcoded in the
-- Flutter app: six words, the same six for everybody. ARCHITECTURE.md 13.4 is explicit
-- that no word list may be compiled into the app, because changing content would then
-- mean a store review.
--
-- Columns follow ARCHITECTURE.md 10.2 and 10.3 exactly. Two things are worth calling out:
--
--   * `status` is here from the start, on the instruction of section 41.5: an editorial
--     workflow arrives later, and adding a status column to a populated content table
--     under pressure is worse than carrying an unused default now. It is separate from
--     `is_active`, which is operational rather than editorial.
--
--   * enums are text + CHECK rather than native enum types, because we will add practice
--     types and statuses and extending a check constraint does not lock the table
--     (ARCHITECTURE.md 10).

CREATE TABLE categories (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    slug            text UNIQUE NOT NULL,

    -- i18n keys rather than text: the app owns the wording, in whichever language the
    -- learner reads, the same way feedback message keys work.
    name_key        text NOT NULL,
    description_key text,

    icon            text,
    sort_order      integer NOT NULL DEFAULT 0,
    is_active       boolean NOT NULL DEFAULT true,

    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE words (
    id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    text                 text NOT NULL,

    language             text NOT NULL DEFAULT 'en',
    accent               text NOT NULL DEFAULT 'en-US',

    phonetic_ipa         text,
    phonetic_respelling  text,

    -- The sounds this word exercises, in IPA. A real array with a GIN index because the
    -- weak-sound service asks "which words drill θ" on every recommendation.
    target_phonemes      text[] NOT NULL DEFAULT '{}',

    audio_url            text,
    category_id          uuid REFERENCES categories (id),

    difficulty_level     text NOT NULL
                         CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced')),
    cefr_level           text CHECK (cefr_level IN ('A1', 'A2', 'B1', 'B2', 'C1', 'C2')),

    part_of_speech       text,
    meaning_uz           text,
    example_sentence     text,

    -- Lower is more common. Nullable on purpose: a word whose frequency we do not know
    -- must not pretend to be rare, and "common words first" simply puts it last.
    frequency_rank       integer,

    -- Editorial state (section 41.5) versus operational state (is_active). A draft row is
    -- not ready to be seen; an inactive row was withdrawn without orphaning attempts.
    status               text NOT NULL DEFAULT 'published'
                         CHECK (status IN ('draft', 'published', 'archived')),
    is_active            boolean NOT NULL DEFAULT true,

    created_at           timestamptz NOT NULL DEFAULT now(),
    updated_at           timestamptz NOT NULL DEFAULT now(),

    -- The same word in another accent is a different row, not a duplicate.
    UNIQUE (text, language, accent)
);

CREATE INDEX words_lookup_idx    ON words (language, accent, is_active);
CREATE INDEX words_category_idx  ON words (category_id);
CREATE INDEX words_difficulty_idx ON words (difficulty_level);
CREATE INDEX words_cefr_idx      ON words (cefr_level);
CREATE INDEX words_frequency_idx ON words (frequency_rank);
CREATE INDEX words_phonemes_idx  ON words USING gin (target_phonemes);
CREATE INDEX words_text_idx      ON words (lower(text));

-- A day's practice is a session. There is no separate "daily list" table: the daily set
-- IS a session with session_type = 'daily', which is what ARCHITECTURE.md 13.1 already
-- describes, and it carries the average this product locks the next day behind.
CREATE TABLE practice_sessions (
    id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id              uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,

    session_type         text NOT NULL
                         CHECK (session_type IN ('daily', 'random', 'targeted',
                                                 'weak_sound', 'category')),
    content_type         text NOT NULL DEFAULT 'word'
                         CHECK (content_type IN ('word', 'phrase', 'sentence')),
    status               text NOT NULL
                         CHECK (status IN ('in_progress', 'completed', 'abandoned')),

    item_count           integer NOT NULL,
    completed_item_count integer NOT NULL DEFAULT 0,
    average_score        numeric(5,2),

    -- Which local day this session belongs to. Stored as a plain date, decided in the
    -- learner's own timezone, so "one daily session per day" is a constraint the database
    -- can enforce rather than a rule the code hopes it followed.
    practice_day         date,

    started_at           timestamptz NOT NULL DEFAULT now(),
    completed_at         timestamptz,
    created_at           timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX practice_sessions_user_idx   ON practice_sessions (user_id, started_at DESC);
CREATE INDEX practice_sessions_status_idx ON practice_sessions (user_id, status);

-- One daily session per learner per day. Partial, so the other session types are free to
-- repeat as often as somebody likes.
CREATE UNIQUE INDEX practice_sessions_daily_idx
    ON practice_sessions (user_id, practice_day)
    WHERE session_type = 'daily';

CREATE TABLE practice_items (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      uuid NOT NULL REFERENCES practice_sessions (id) ON DELETE CASCADE,

    -- RESTRICT, not CASCADE: deleting a word must not silently rewrite somebody's history.
    word_id         uuid NOT NULL REFERENCES words (id) ON DELETE RESTRICT,

    position        integer NOT NULL,
    status          text NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'attempted', 'completed', 'skipped')),

    -- A deliberate denormalization: the result and progress screens ask "how did this item
    -- end up" constantly, and recomputing a maximum across attempts each time is wasteful.
    best_attempt_id uuid REFERENCES pronunciation_attempts (id) ON DELETE SET NULL,
    best_score      numeric(5,2),
    attempt_count   integer NOT NULL DEFAULT 0,

    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),

    UNIQUE (session_id, position)
);

CREATE INDEX practice_items_session_idx ON practice_items (session_id);
CREATE INDEX practice_items_word_idx    ON practice_items (word_id);
