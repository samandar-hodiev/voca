// jobs: in-process scheduler.
//
// MVP has NO queue, NO broker, and NO separate worker fleet. The few periodic tasks run
// inside the API binary on a cron scheduler, guarded by a PostgreSQL ADVISORY LOCK so that
// running two instances never double-executes a job.
//
//   type Job interface {
//       Name() string
//       Run(ctx context.Context) error
//   }
//
// A job holds NO business logic — it is a thin trigger over an existing service. That single
// rule gives three properties: jobs are unit-testable without a scheduler; the same logic
// can be triggered by cron today, a queue tomorrow, and an admin endpoint for debugging;
// and moving to a real queue changes HOW Run is invoked, not the work itself.
//
// Stage 3 replaces this with a Redis-backed queue consumed by cmd/worker — the same image,
// a different entrypoint (ARCHITECTURE.md 21.3, 33).

package jobs
