// shared/httpx: the standard response envelope.
//
//   success: {"data": ..., "meta": ...}
//   error:   {"error": {"code", "message", "details", "request_id"}}
//
// code is a STABLE machine-readable string the app switches on. The app localizes by CODE,
// not by message — which is why message can stay English and why a second UI language costs
// no backend work (ARCHITECTURE.md 19.1).
//
// Also holds cursor pagination helpers (ARCHITECTURE.md 11.1).

package httpx
