# ADR-019: Firebase authenticates, the Go backend authorises

- **Status:** Accepted
- **Date:** 2026-09-11
- **Related:** [ADR-006](ADR-006-ports-and-adapters.md)

## Context

Sign in with Google needs something to check that a Google account really belongs to the
person holding the phone. Two shapes were available.

**Raw Google ID tokens.** The app asks Google directly, forwards the ID token, and the
backend validates it against Google's keys for a specific OAuth client ID. This was built
first. It works, but every platform needs its own OAuth client registered and listed as an
accepted audience, and the same wiring has to be repeated for Apple later.

**Firebase Authentication.** The app hands the Google credential to Firebase and receives a
Firebase ID token instead. One project covers every platform and every future provider, and
Firebase has already done the exchange with Google by the time the backend sees anything.

The risk with the second shape is the obvious one: Firebase brings a whole backend with it,
and it is easy to drift into letting a Firebase UID become the application's identity. That
would put the source of truth for users and sessions outside PostgreSQL, where none of the
product's rules live.

## Decision

Firebase Authentication is the identity provider and nothing else.

```
app -> Google picker -> Firebase credential -> Firebase ID token
     -> POST /api/v1/auth/google -> verified server-side
     -> PostgreSQL user -> Voca access and refresh tokens -> Home
```

Three rules hold this in place:

1. **A Firebase UID is never a session.** It is stored as `users.external_auth_id` and used
   to recognise a returning person, nothing more. The app runs on Voca's own tokens.
2. **The backend trusts only signed claims.** The name and picture come from the token, not
   from the request body. A client may send anything and is believed about nothing.
3. **No service account key exists.** Verifying an ID token needs the project ID and
   Google's public certificates, so there is no private key to store, leak or rotate.

The verifier lives behind `auth.GoogleTokenVerifier`, the port the auth module already
owned, so the service does not know Firebase exists.

## Consequences

**One project covers every platform.** Apple sign-in and any later provider arrive as the
same Firebase ID token against the same endpoint, and the backend changes nothing.

**The app gains a hard dependency on Firebase starting.** Without the platform
configuration file Firebase does not initialise, so the app reports Google sign-in as
unavailable and greys the button out. Every other way in keeps working, and the launch
never fails because of it.

**Two sessions now have to be ended on sign-out.** Clearing the Voca session alone leaves
the Google account selected, and the next sign-in silently reuses it. On a shared phone that
hands the app to the wrong person, so sign-out ends both.

**Account linking stays the backend's rule.** A person who signed up by email and later taps
Google is matched on the verified address and linked to the account they already have,
rather than being given a second one that splits their history.

## Alternatives considered

**Keep raw Google ID tokens.** Rejected: it needs one OAuth client per platform registered
as an accepted audience, and the whole arrangement repeats for the next provider. The code
was written and worked; it is replaced because Firebase collapses that into one project.

**Use Firebase as the product's backend.** Rejected outright. Users, sessions, progress and
every business rule belong in PostgreSQL behind the Go service, and moving identity out of
it would split the source of truth in two.
