# Speech provider outage runbook.
#
# Azure Speech is a single point of failure for the only revenue-generating action in the
# product (ARCHITECTURE.md 36, risk 5).
#
# Designed behaviour during an outage:
#   - failed attempts are persisted with status=failed
#   - THE FREE QUOTA IS NOT CONSUMED — we do not charge users for our outages
#   - a streak is NOT broken by a failed attempt
#   - the app shows a clear retry state, not a generic error
#
# To fill in:
#   - how to confirm the outage is the provider (provider latency and error-rate metrics)
#   - the status page and support contact
#   - how to switch SPEECH_PROVIDER once a second adapter exists
#   - user communication threshold
