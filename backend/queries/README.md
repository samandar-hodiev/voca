# Hand-written SQL consumed by sqlc, which generates type-safe Go into
# internal/database/sqlc.
#
# Why sqlc and not an ORM (ADR-002): the developer writes REAL SQL, can read the query
# plan, and still gets compile-time safety. There is no hidden query generation to debug
# under load.
#
# One file per module, mirroring internal/: auth.sql, user.sql, word.sql, practice.sql,
# pronunciation.sql, progress.sql, subscription.sql, notification.sql.
#
# All queries are parameterized. STRING-CONCATENATED SQL IS BANNED (ARCHITECTURE.md 18.2).
