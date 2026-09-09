# Every feature follows the same three-layer shape (ARCHITECTURE.md 4.2):
#
#   domain/        Pure Dart. Entities, repository INTERFACES, use cases, failures.
#                  Depends on NOTHING. A domain file importing flutter, dio, or a JSON
#                  codec is a bug.
#
#   data/          DTOs with fromJson and toDomain, remote and local data sources,
#                  repository IMPLEMENTATIONS, mappers. Depends on domain.
#
#   presentation/  Pages, feature-local widgets, Riverpod controllers, UI state.
#                  Depends on domain. MUST NOT import data.
#
# Call direction: widget -> controller -> use case -> repository interface. Nothing skips a
# step, and dependencies only ever point inward toward domain.
#
# Why DTOs are separate from entities: when the API adds, renames, or nests a field, only
# the DTO and its mapper change. The entity, the use cases, and every widget stay untouched.
#
# Adding a feature is a new folder plus one route line. Removing one is deleting a folder
# plus one route line. That is what feature isolation has to mean for the roadmap in
# ARCHITECTURE.md 34 to be affordable.
