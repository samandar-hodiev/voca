// routing: redirect guards.
//
//   authGuard     signed in
//   premiumGuard  UI-LEVEL GATING ONLY
//
// The premium guard is a UX convenience. The AUTHORITATIVE entitlement check is always the
// backend: a client can be patched, replayed, or run on a rooted device (ARCHITECTURE.md
// 4.4, 9.4).
