-- Identity, profile and onboarding preferences.
--
-- Follows the conventions in ARCHITECTURE.md section 10: UUID primary keys, timestamptz
-- everywhere, and text columns with CHECK constraints instead of native enum types,
-- because adding a value to a check constraint is trivial while altering a native enum
-- is a locking migration. We will add practice types, goals and statuses.

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

-- ---------------------------------------------------------------------------
-- users: identity and credentials
-- ---------------------------------------------------------------------------
CREATE TABLE users (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    -- How this person signs in. 'guest' is a real provider: a guest is a full user row
    -- with no credential, so upgrading to a real account later is an UPDATE rather than a
    -- migration of their practice history onto a different row.
    auth_provider     text NOT NULL CHECK (auth_provider IN ('email', 'apple', 'google', 'guest')),

    -- Provider subject for Apple/Google. Null for email and guest.
    external_auth_id  text,

    -- Null for guests. Apple may return a private relay address.
    email             citext,
    email_verified    boolean NOT NULL DEFAULT false,

    -- Argon2id encoded hash. Null for guest and for social sign-in.
    password_hash     text,

    status            text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'deleted')),
    last_login_at     timestamptz,

    created_at        timestamptz NOT NULL DEFAULT now(),
    updated_at        timestamptz NOT NULL DEFAULT now(),
    deleted_at        timestamptz
);

-- The real identity key for social sign-in.
CREATE UNIQUE INDEX users_provider_subject_key
    ON users (auth_provider, external_auth_id)
    WHERE external_auth_id IS NOT NULL;

-- One live account per address. Deleted rows are excluded so an address can be reused
-- after account deletion.
CREATE UNIQUE INDEX users_email_key
    ON users (email)
    WHERE email IS NOT NULL AND deleted_at IS NULL;

CREATE INDEX users_status_idx ON users (status);

-- ---------------------------------------------------------------------------
-- profiles: display identity
-- ---------------------------------------------------------------------------
-- Kept separate from users so a future public profile feature cannot accidentally expose
-- a credential row, and so adding a display field never touches identity.
CREATE TABLE profiles (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      uuid NOT NULL UNIQUE REFERENCES users (id) ON DELETE CASCADE,
    first_name   text,
    last_name    text,
    phone        text,
    avatar_url   text,
    created_at   timestamptz NOT NULL DEFAULT now(),
    updated_at   timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- user_preferences: learning settings, including the onboarding answers
-- ---------------------------------------------------------------------------
CREATE TABLE user_preferences (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           uuid NOT NULL UNIQUE REFERENCES users (id) ON DELETE CASCADE,

    -- Onboarding answers. Stable identifiers, never localized display text.
    cefr_level        text CHECK (cefr_level IN ('A1', 'A2', 'B1', 'B2', 'C1')),
    learning_goal     text CHECK (learning_goal IN (
                          'pronunciation', 'confidence', 'ielts',
                          'vocabulary', 'work', 'everyday')),
    daily_goal_words  integer NOT NULL DEFAULT 10 CHECK (daily_goal_words BETWEEN 1 AND 200),

    ui_language       text NOT NULL DEFAULT 'uz',
    learning_language text NOT NULL DEFAULT 'en',
    accent            text NOT NULL DEFAULT 'en-US',

    -- Streaks and daily goals are meaningless without knowing when the person's day ends.
    timezone          text NOT NULL DEFAULT 'Asia/Tashkent',

    onboarding_completed_at timestamptz,

    created_at        timestamptz NOT NULL DEFAULT now(),
    updated_at        timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- email_verifications: one-time codes for sign-up and password reset
-- ---------------------------------------------------------------------------
-- One table for both purposes: the security rules are identical, and two tables would be
-- two places to get expiry, attempt limits and single-use wrong.
CREATE TABLE email_verifications (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email         citext NOT NULL,
    purpose       text NOT NULL CHECK (purpose IN ('signup', 'password_reset')),

    -- The code is stored HASHED. A database dump must not hand out live codes, exactly as
    -- it must not hand out passwords.
    code_hash     text NOT NULL,

    attempts      integer NOT NULL DEFAULT 0,
    max_attempts  integer NOT NULL DEFAULT 5,

    expires_at    timestamptz NOT NULL,
    consumed_at   timestamptz,

    -- Set once the code is verified, so registration can prove the address was checked
    -- without re-sending a code.
    verified_at   timestamptz,

    created_at    timestamptz NOT NULL DEFAULT now()
);

-- The lookup on every verify: newest live challenge for this address and purpose.
CREATE INDEX email_verifications_lookup_idx
    ON email_verifications (email, purpose, created_at DESC);

-- Supports the cleanup job and the resend rate limit.
CREATE INDEX email_verifications_expiry_idx ON email_verifications (expires_at);

-- ---------------------------------------------------------------------------
-- refresh_tokens: revocable sessions
-- ---------------------------------------------------------------------------
-- Opaque and hashed rather than a JWT, because a JWT refresh token cannot be invalidated
-- before it expires without exactly this table (ARCHITECTURE.md section 8.2).
CREATE TABLE refresh_tokens (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token_hash    text NOT NULL UNIQUE,

    -- Rotation chain. Presenting an already-rotated token means the token was stolen, so
    -- the whole family is revoked.
    rotated_from  uuid REFERENCES refresh_tokens (id) ON DELETE SET NULL,

    user_agent    text,
    expires_at    timestamptz NOT NULL,
    revoked_at    timestamptz,
    created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX refresh_tokens_user_idx ON refresh_tokens (user_id, expires_at DESC);
