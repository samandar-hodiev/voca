// auth: request and response shapes for the HTTP API.
//
// Kept separate from domain models on purpose: the wire contract and the domain evolve
// independently. Field names are snake_case per ARCHITECTURE.md 11.1. Validation tags are
// declared here and enforced in handler.go.
//
// See ARCHITECTURE.md 11.2.

package auth
