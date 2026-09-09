// The single HTTP client for the admin application.
//
// Responsibilities:
//   - prefix every request with the configured API base URL
//   - attach the admin session credential
//   - refresh or redirect to sign-in on 401
//   - translate the backend error envelope {"error":{code,message,details}} into typed errors
//   - surface the request ID so an admin can quote it in a bug report
//
// Every feature's api.ts goes through here. No component calls fetch directly.
//
// The admin talks ONLY to the Go backend over /api/v1/admin. It has no database driver, no
// vendor SDK, and no business rule of its own (ARCHITECTURE.md 38.4, ADR-014).
