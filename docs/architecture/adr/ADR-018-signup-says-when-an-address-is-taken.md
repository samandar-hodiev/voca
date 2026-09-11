# ADR-018: Sign-up says when an address already has an account

- **Status:** Accepted
- **Date:** 2026-09-11
- **Related:** [ADR-017](ADR-017-email-delivery-requires-a-verified-domain.md)

## Context

`POST /auth/email/start` originally answered identically whether or not the address had an
account. That is the textbook defence against address enumeration: if the response never
differs, nobody can use the endpoint to walk a list of addresses and learn who is a
customer.

It also produced this, repeatedly, with real people:

> The app says a code has been sent. Nothing arrives. There is no way to tell a forgotten
> account from a broken product, so the person concludes the product is broken.

Softening it by emailing the address instead was tried first. It is better than silence,
but it only helps somebody who thinks to check an inbox they are already staring at, and it
does nothing at all while delivery is restricted.

The security value being defended is also smaller than it first appears. Sign-in and
password reset already reveal nothing, and an attacker who wants to know whether an address
is registered has other signals. What enumeration actually needs is volume: the attack is
only worth running against thousands of addresses.

## Decision

Sign-up answers honestly. An address that already has an account returns
`409 EMAIL_ALREADY_EXISTS`, and the app offers to sign in instead.

Volume is what is defended against, not the single answer. Every `/auth` endpoint is behind
a per-client rate limit, defaulting to twenty requests a minute
(`RATE_LIMIT_AUTH_PER_MIN`). At that rate, testing a million addresses from one client
takes over a month.

The address is still emailed as well, so somebody who did not attempt the sign-up learns
that an attempt was made. That message carries no code and no sign-in link, because
whoever typed the address may not own it.

## Consequences

**Sign-up stops being a dead end.** The person is told what happened and handed the way
out, which is the single biggest cause of abandoned sign-ups this flow had.

**Address enumeration becomes possible but slow.** Anybody may now learn, one address at a
time and at twenty a minute, whether an address is registered. This is accepted.

**The rate limit is now load-bearing, not a nicety.** It was an unimplemented placeholder
before this decision; it is now the only thing standing between the honest answer and a
bulk enumeration. It must not be quietly disabled, and when a second API instance runs the
in-memory counters stop being correct, which is the trigger for moving them to Redis.

**Sign-in and password reset keep their silence.** They reveal nothing, because there the
useful answer costs nothing: a wrong password is a wrong password whether or not the
account exists, and a reset that quietly does nothing is not a dead end in the same way.

## Alternatives considered

**Stay silent and rely on the email.** Rejected: it does not help while delivery is
restricted, and it asks the person to check an inbox to find out why their inbox is empty.

**Reveal it only after a CAPTCHA.** A real option later. Rejected for now because it adds a
vendor and a second failure mode to the most fragile screen in the product, to defend
against an attack nobody has attempted.
