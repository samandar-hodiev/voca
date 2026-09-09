# Database documentation.
#
# The authoritative schema is ARCHITECTURE.md 10 (table-by-table columns, keys, indexes and
# constraints) and 29 (the entity relationship diagram and how to read it).
#
# This file is for what those cannot carry:
#   - an ERD image or mermaid diagram regenerated from the live schema after each migration
#   - migration history notes and any manual data backfills
#   - index tuning decisions taken against REAL query plans, with the reasoning
#   - the retention policy: what is kept, for how long, and what account deletion removes
#
# Two schema decisions worth restating because they are the ones most likely to be
# questioned later:
#   - word-level results are JSONB on pronunciation_attempts (always read with the attempt,
#     never aggregated across rows), while phoneme results are a real table (aggregated
#     across attempts to find weak sounds). That asymmetry is deliberate.
#   - user_id is denormalized onto pronunciation_attempts and phoneme_results so the two
#     hottest queries in the product are single-index lookups with no joins.
