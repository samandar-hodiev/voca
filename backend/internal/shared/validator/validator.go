// shared/validator: request validation built on go-playground/validator.
//
// Declarative struct tags on DTOs, enforced in the handler layer ONLY. Unknown fields
// rejected, strict types, length caps on every string.
//
// See ARCHITECTURE.md 18.2, 5.3.

package validator
