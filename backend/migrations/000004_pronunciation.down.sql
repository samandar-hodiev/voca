-- Dropped in reverse dependency order. phoneme_results and feedback cascade from
-- pronunciation_attempts, but they are dropped explicitly so the intent is readable.
DROP TABLE IF EXISTS feedback;
DROP TABLE IF EXISTS phoneme_results;
DROP TABLE IF EXISTS pronunciation_attempts;
