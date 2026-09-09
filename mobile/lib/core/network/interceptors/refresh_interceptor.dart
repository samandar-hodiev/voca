// core/network: token refresh on 401 TOKEN_EXPIRED.
//
// Performs ONE refresh, retries the original request once, and QUEUES concurrent requests
// during the refresh so a burst does not trigger several refreshes.
//
// On refresh failure: clear secure storage and route to sign-in via the GoRouter auth guard.
//
// See ARCHITECTURE.md 8.3.
