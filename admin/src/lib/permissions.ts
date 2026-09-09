// Client-side permission helpers for rendering.
//
// Maps a role (admin, owner, and any later role) to which navigation entries and controls are
// visible.
//
// THIS IS COSMETIC ONLY. It exists so an admin is not shown buttons that would fail. The
// authoritative check lives in the backend's RequireRole middleware (ARCHITECTURE.md 39).
