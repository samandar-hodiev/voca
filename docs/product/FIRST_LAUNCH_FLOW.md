# First launch, onboarding and account entry

The implemented flow from opening the app to reaching the product.

## Startup

The splash is shown on **every** launch. Only what follows it changes, and the decision
lives in `splash_controller.dart`, not in a widget.

```
                    Splash (1.6s minimum, initialization runs alongside)
                              │
              ┌───────────────┴───────────────┐
     onboarding not done                onboarding done
              │                               │
         Onboarding 1-3                ┌──────┴──────┐
              │                    no session     session
     Level → Goal → Daily goal         │             │
              │                    Auth entry       Home
         Auth entry
```

Onboarding, level, goal and daily goal never reappear once completed. Skipping onboarding
skips the slides, not the questions: the answers shape every later screen.

## Screens

| Screen | Route | Purpose |
|--------|-------|---------|
| Splash | `/` | Startup work and the routing decision |
| Onboarding | `/onboarding` | Three slides, swipe or button, skip at top |
| Level | `/setup/level` | A1 to C1, code plus a plain-language label |
| Goal | `/setup/goal` | Six goals, stable identifiers |
| Daily goal | `/setup/daily-goal` | 5, 10, 15, 20 words; 10 recommended and pre-selected |
| Auth entry | `/auth` | Email, guest, or sign in |
| Email | `/auth/email` | Address to send a code to |
| Verify | `/auth/email/verify` | Six-digit code, resend with cooldown |
| Profile | `/auth/profile` | Name, optional phone, password |
| Login | `/auth/login` | Email and password |
| Forgot | `/auth/forgot` | Address for a reset code |
| Verify reset | `/auth/forgot/verify` | Six-digit code |
| New password | `/auth/forgot/password` | Set and sign in |

## API

| Method | Path | Notes |
|--------|------|-------|
| POST | `/api/v1/auth/email/start` | Same answer whether or not the address is registered |
| POST | `/api/v1/auth/email/verify` | Counts the attempt before reporting failure |
| POST | `/api/v1/auth/email/resend` | Rate limited: 5 per 15 minutes |
| POST | `/api/v1/auth/register` | Requires a verified address; returns a session |
| POST | `/api/v1/auth/login` | One answer for wrong password and unknown address |
| POST | `/api/v1/auth/guest` | Anonymous session, keeps the setup answers |
| POST | `/api/v1/auth/refresh` | Rotates; reuse revokes every session |
| POST | `/api/v1/auth/logout` | Forgiving of an unknown token |
| POST | `/api/v1/auth/password/forgot` | Silent about whether the address exists |
| POST | `/api/v1/auth/password/verify` | |
| POST | `/api/v1/auth/password/reset` | Revokes every session, then signs in |
| GET/PUT | `/api/v1/users/me/preferences` | Level, goal, daily goal. Requires a token |

Errors use the standard envelope. The app switches on the `code`, never the message, which
is why the API answers in English and the app speaks Uzbek.

## Security

- Codes are six digits, live ten minutes, allow five attempts, and are stored hashed.
  The protection is the expiry and the cap, not the alphabet.
- Codes are never logged, never returned by an endpoint, and exist only in memory and in
  the recipient's inbox.
- Passwords are Argon2id. Minimum eight characters, counted in runes.
- Tokens live in the Keychain and the Android Keystore, never in shared preferences.
- Refresh tokens rotate. A replayed token is treated as stolen and ends every session.
- Registration writes user, profile and preferences in one transaction.

## Guest accounts

A guest is a full user row with `auth_provider = 'guest'` and no credential. Their level,
goal and daily goal are stored exactly like anyone else's.

Upgrading a guest to a real account is therefore an `UPDATE` on that row rather than a
migration of their history onto a different one. **The upgrade flow itself is not built**;
the data model is what makes it cheap to add.

## Not implemented

- **Apple sign-in.** Designed for, deliberately absent. It needs an Apple Developer
  account and a Sign in with Apple configuration that does not exist yet, and a button
  that cannot work is worse than no button. Adding it later means one adapter behind the
  existing provider abstraction, plus a button on the auth entry screen.
- **Guest-to-account upgrade UI.**
- **Avatar upload.** The field exists in the schema and the API; there is no picker.
- **Email delivery.** The development provider reports that a message would have been
  sent and deliberately does not log the code. A real provider is one adapter behind
  `EmailProvider`.

## Local development

Reading a verification code without an email provider:

```
psql voca_dev -c "SELECT email, purpose, expires_at FROM email_verifications ORDER BY created_at DESC LIMIT 1"
```

The code itself is hashed and cannot be read back, which is the point. For end-to-end
testing, either configure a real provider or add a development adapter that writes codes
to a file outside the log.
