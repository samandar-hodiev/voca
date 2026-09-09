// auth: business logic / use cases. Identity token verification, user creation, JWT issuance, refresh rotation.
//
// Responsibility: all business rules for this module, resource-ownership checks,
// orchestration across repositories and provider ports, and transaction boundaries.
//
// This is the module's PUBLIC SURFACE. Other modules may call this service interface and
// nothing else — never this module's repository, models, or tables (ARCHITECTURE.md 5.5).
//
// MUST NOT import: gin, pgx or sql types, or any vendor SDK.
//
// See ARCHITECTURE.md 8, 5.3, 5.5.

package auth
