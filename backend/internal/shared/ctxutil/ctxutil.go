// shared/ctxutil: typed accessors for values carried in context.Context.
//
// Currently the authenticated user ID and the request ID. Typed keys prevent the collisions
// and stringly-typed lookups that context misuse invites.

package ctxutil
