// pronunciation/domain: THE CORE USE CASE. Uploads audio to POST /api/v1/pronunciation/attempts with an Idempotency-Key so a repeated submit returns the original result instead of consuming quota twice (ARCHITECTURE.md 6.5).
//
// Layer rules: ARCHITECTURE.md 4.2 (what belongs in each layer), 31.1 (dependencies).
