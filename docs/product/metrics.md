# Metric definitions — agreed BEFORE launch so the first numbers are not argued about
# afterwards.
#
# Full definitions: ARCHITECTURE.md 16.4.
#
#   DAU / WAU / MAU              distinct users with app_opened in 1 / 7 / 30 days
#   D1 / D7 / D30 retention      returned on day 1 / 7 / 30 after signup
#   practice completion rate     session_completed / practice_started
#   average pronunciation score  mean overall_score, by cohort and over time
#   retry rate                   retry_clicked / assessment_completed
#   free-to-premium conversion   subscription_started / users reaching premium_viewed
#   trial conversion             trials converting to paid
#   churn / subscription retention
#   limit pressure               usage_limit_reached per free user — the leading indicator
#                                for pricing decisions
#
# Score-related metrics are computed from OUR database, not from the analytics vendor:
# that data is authoritative, queryable, and not subject to vendor sampling or retention.
#
# Also track, from ARCHITECTURE.md 18.4 and 24.5: assessment end-to-end latency, provider
# latency and error rate, and COST PER ACTIVE USER — the dominant runtime cost driver and
# the number that decides pricing.
