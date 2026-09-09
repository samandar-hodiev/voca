# Database restore runbook.
#
# AN UNTESTED BACKUP IS NOT A BACKUP. A restore drill is a REQUIRED pre-launch item on the
# Architecture Freeze Checklist and in implementation step 14 (ARCHITECTURE.md 24.4, 37).
#
# To fill in:
#   - where backups live, schedule, and retention
#   - exact point-in-time recovery procedure for the managed database
#   - how to verify a restore is complete and correct
#   - measured recovery time and recovery point objectives, from an actual drill
#   - what to do about subscription state that moved during the restored window — replay
#     from subscription_events, which is append-only for exactly this reason
