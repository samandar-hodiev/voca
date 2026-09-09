// practice/domain: starts a session via POST /api/v1/practice/sessions. Items arrive WITH their words embedded so the screen never issues N+1 requests and works when connectivity is poor mid-session.
//
// Layer rules: ARCHITECTURE.md 4.2 (what belongs in each layer), 31.1 (dependencies).
