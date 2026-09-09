// Admin session handling.
//
// Sign-in, sign-out, session refresh, and reading the current admin's role.
//
// IMPORTANT: the role returned here drives what the UI SHOWS. It is not a security boundary.
// Every privileged action is authorized again by the backend, because a browser can be
// modified and a hidden button is not an access control (ARCHITECTURE.md 39.3).
