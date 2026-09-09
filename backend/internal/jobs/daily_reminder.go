// jobs: daily practice reminder dispatch. Runs every 15 minutes.
//
// Selects users whose reminder_time has arrived in their timezone and who have not
// practised today, then calls notification.Service.
//
// Must respect: per-user preferences (server-side, not client-side), quiet hours, and the
// frequency cap of at most one reminder-class notification per user per day. The fastest
// way to lose a learner is to nag them.
//
// See ARCHITECTURE.md 17.2, 17.3.

package jobs
