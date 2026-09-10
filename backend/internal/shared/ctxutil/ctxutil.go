// Package ctxutil provides typed accessors for values carried in the request context.
//
// Typed keys prevent the collisions and stringly-typed lookups that context misuse
// invites, and they keep the set of things stored in a context small and visible.
package ctxutil

import "context"

type contextKey string

const (
	requestIDKey contextKey = "voca.request_id"
	userIDKey    contextKey = "voca.user_id"
)

// WithRequestID returns a context carrying the request correlation ID.
func WithRequestID(ctx context.Context, id string) context.Context {
	return context.WithValue(ctx, requestIDKey, id)
}

// RequestID returns the request correlation ID, or an empty string.
func RequestID(ctx context.Context) string {
	id, _ := ctx.Value(requestIDKey).(string)
	return id
}

// WithUserID returns a context carrying the authenticated user's ID.
//
// Only authentication middleware may call this. A handler that needs to know who is
// calling reads it; it never sets it.
func WithUserID(ctx context.Context, id string) context.Context {
	return context.WithValue(ctx, userIDKey, id)
}

// UserID returns the authenticated user's ID and whether one is present.
func UserID(ctx context.Context) (string, bool) {
	id, ok := ctx.Value(userIDKey).(string)
	return id, ok && id != ""
}
