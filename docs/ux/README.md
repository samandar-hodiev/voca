# UX documentation

User journeys, flows, and screen-level intent for both applications. Written before UI
implementation so that screens are built against an agreed flow rather than invented
during coding.

| File | Covers |
|------|--------|
| `mobile-flows.md` | Onboarding, the practice loop, results and retry, progress, paywall |
| `admin-flows.md` | Admin sign-in, content moderation queue, user inspection, system health |
| `edge-states.md` | Offline, permission denied, quota reached, provider failure, empty states |

Nothing here is written yet.

The core mobile loop this documentation must serve is in `ARCHITECTURE.md` section 2.1.
Edge states matter disproportionately in Voca: microphone permission refusal, no network
during assessment, a failed provider call, and a reached free quota are all common and all
need a defined, non-generic screen.
