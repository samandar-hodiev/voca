# Running Voca locally

Three applications. Only the backend needs infrastructure; both clients need nothing but a
reachable API.

```
backend   cd backend && make run                 # :8082
admin     cd admin && npm run dev                # :3000
mobile    cd mobile && flutter run -d <device>    # see the blocker below
```

Verify each:

```
curl http://localhost:8082/health     # {"data":{"status":"ok"},...}
curl -I http://localhost:3000/        # 200
```

---

## Blocker: iOS builds fail on an iCloud-synced Desktop

**Symptom.** `flutter run` and `flutter build ios` fail with an unhelpful message:

```
Failed to build iOS app
Uncategorized (Xcode): Exited with status code 255
```

Only `-v` reveals the real cause:

```
Failed to codesign .../Flutter.framework/Flutter with identity -
.../Flutter: resource fork, Finder information, or similar detritus not allowed
```

**Cause.** This repository lives at `~/Desktop`, and this Mac has iCloud Drive's
"Desktop & Documents" sync enabled. iCloud's file provider stamps directories with
`com.apple.FinderInfo`, and `codesign` refuses to sign a bundle carrying it.

Confirmed by three observations:

| Test | Result |
|------|--------|
| `xcodebuild` run directly on the Xcode project | **BUILD SUCCEEDED** |
| `codesign` on a manually copied framework, same directory | succeeds |
| `flutter build ios` from a copy of the project under `/tmp` | **succeeds** |

So neither the Xcode project nor the Flutter code is at fault. The location is.

Clearing the attribute does not hold: iCloud re-applies it, and `xattr -cr` cannot remove
`com.apple.provenance` at all. Note that `com.apple.provenance` alone is harmless here;
`com.apple.FinderInfo` on the framework **directory** is what breaks the signature.

**Fix.** Move the repository off the synced Desktop, for example to `~/Developer/voca`.
Android, the backend, the admin and all tests are unaffected either way.

**Workaround, if the repository must stay put.** Build from a copy outside iCloud:

```
rsync -a --exclude build --exclude .dart_tool <repo>/mobile/ /tmp/voca-run/mobile/
cd /tmp/voca-run/mobile && flutter pub get && flutter run -d <simulator>
```

That runs the app but is not a development loop: edits in the repository are not picked up.

---

## Second symptom of the same location problem

`flutter analyze` crashes on this machine:

```
Unhandled exception: FormatException: Unexpected end of input
LspByteStreamServerChannel._readMessage
```

The directory name contains an en dash (`–` in "Voca – English Pronunciation Coach"), and
the analysis server's LSP channel mishandles the non-ASCII path.

**Use `dart analyze` instead** — it works correctly and covers the same rules. CI is
unaffected, since the checkout path there is ASCII.

Moving the repository to a plain ASCII path fixes this too.

---

## Android

Not usable on this machine yet: SDK licences are unaccepted and no AVD exists.

```
flutter doctor --android-licenses     # a legal agreement; accept it yourself
flutter emulators --create
```

Android does not codesign, so it is immune to the iCloud problem above.

## Reading a verification code during development

Signup and password reset both send a six-digit code by email. There are no mail
credentials on a development machine, and the default `log` email provider deliberately
never prints the code, so by default a signup cannot be completed by hand.

Set `EMAIL_OUTBOX_DIR` in `backend/.env` to turn on a local mail catcher:

```
EMAIL_OUTBOX_DIR=tmp/mail
```

Every message the backend sends is then written to that directory as a plain text file
instead of being delivered. Read the newest one:

```sh
cat "$(ls -t backend/tmp/mail/*signup_code* | head -1)"
```

The directory is gitignored, created `0700`, and each message is written `0600`.

The provider refuses to start when `APP_ENV=production`, so a deployment that forgets to
configure a real email provider fails at startup instead of quietly writing customer
verification codes to a server disk. The code still never reaches a log line, an HTTP
response, or a terminal.

## Getting a Telegram message on every push

The intended path is GitHub -> webhook -> ngrok -> GitPulse -> Telegram. It needs the
ngrok URL currently registered in the repository's webhook settings to be reachable, so
it breaks whenever that URL changes.

The local path does not depend on GitHub at all:

```sh
make gitpulse-hook
```

That installs `.git/hooks/pre-push`. After a push lands, the hook confirms the remote
really has the commit, then posts a GitHub-shaped, correctly signed payload straight to
GitPulse on `localhost:8080`. A rejected push sends nothing, and a notification failure
never fails the push.

GitPulse must be running for this to do anything:

```sh
cd ~/Desktop/gitpulse/gitpulse && go run .
```

To send a notification by hand for a commit that was already pushed:

```sh
scripts/gitpulse-notify.sh <commit-sha>
```

The webhook secret is read from GitPulse's own `.env` and is never printed.

## Sending the verification code to a real inbox

The outbox above is for reading a code without credentials. To make the code actually
arrive at a Gmail address, configure SMTP in `backend/.env`:

```
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=you@gmail.com
SMTP_PASSWORD=<16-character app password>
SMTP_FROM=you@gmail.com
SMTP_FROM_NAME=Voca
```

Gmail rejects an ordinary account password over SMTP. Turn on two-factor authentication,
then create an app password at Google Account -> Security -> App passwords, and paste
that. `SMTP_FROM` should match `SMTP_USERNAME`, because most providers reject a sender
that is not the authenticated account.

Restart the backend. The startup log line `email_provider_selected provider=smtp` confirms
the choice. Provider selection is most capable first:

| Configuration | Provider | Where the code goes |
|---|---|---|
| `SMTP_HOST` + `SMTP_FROM` set | smtp | a real inbox |
| `EMAIL_OUTBOX_DIR` set, no SMTP | outbox | a file on disk |
| neither | log | nowhere; the log says a message would have been sent |

The connection is always encrypted. Port 465 opens in TLS, everything else must offer
STARTTLS or the send fails rather than crossing the network in plain text.

## Enabling Google sign-in

The button renders disabled until the backend reports the capability, and the backend
reports it only when at least one OAuth client ID is configured. Create the client IDs in
the Google Cloud console under APIs & Services -> Credentials, then set them in
`backend/.env`:

```
GOOGLE_IOS_CLIENT_ID=...apps.googleusercontent.com
GOOGLE_ANDROID_CLIENT_ID=...apps.googleusercontent.com
GOOGLE_WEB_CLIENT_ID=...apps.googleusercontent.com
```

Each configured ID becomes an accepted audience, so a token minted for the iOS app is
accepted only if the iOS client ID is listed. Check it took effect:

```sh
curl -s localhost:8082/api/v1/config
```

`google_sign_in` flips to `true` and the app enables the button on its next launch.

### Creating the iOS client ID, step by step

1. Open <https://console.cloud.google.com> and sign in with the Google account that
   should own the app.
2. Top left, next to the Google Cloud logo, click the project picker, then **New
   project**. Name it `Voca` and click **Create**. Wait for it to be selected.
3. In the search bar type `OAuth consent screen` and open it.
   - User type: **External**, then **Create**.
   - App name `Voca`, support email your own address, developer contact your own
     address. **Save and continue** through the remaining steps, then **Back to
     dashboard**.
   - While the app is in Testing, only accounts listed under **Test users** can sign in.
     Add your own Gmail address there.
4. Search for `Credentials`, open it, then **Create credentials** ->
   **OAuth client ID**.
5. Application type **iOS**.
   - Name: `Voca iOS`
   - Bundle ID: `com.voca.voca` (it must match exactly, or Google rejects the token)
   - **Create**.
6. The dialog now shows two values. Copy both:
   - **Client ID**, which looks like `123456789-abc123.apps.googleusercontent.com`
   - **iOS URL scheme**, the same thing reversed:
     `com.googleusercontent.apps.123456789-abc123`

Then wire them in:

```
# backend/.env
GOOGLE_IOS_CLIENT_ID=123456789-abc123.apps.googleusercontent.com
```

```xml
<!-- mobile/ios/Runner/Info.plist, inside the top-level <dict> -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.123456789-abc123</string>
    </array>
  </dict>
</array>
```

Without the URL scheme the Google sheet opens and never returns, because the browser has
no way to hand the result back to the app.

Restart the backend, rebuild the app, and the button enables itself.

For Android later, repeat step 4 with application type **Android**, package name
`com.voca.voca`, and the SHA-1 of the signing certificate, then set
`GOOGLE_ANDROID_CLIENT_ID`.

## Getting a Gmail app password

1. Open <https://myaccount.google.com/security>.
2. Turn on **2-Step Verification** if it is not already on. App passwords do not exist
   without it.
3. Go to <https://myaccount.google.com/apppasswords>.
4. Type a name such as `Voca backend` and click **Create**.
5. Google shows a 16-character password in four groups. Copy it. The spaces do not
   matter; they can be removed.

Put it in `backend/.env` as `SMTP_PASSWORD` and restart the backend. The password is only
shown once, so store it somewhere safe. It grants access to sending mail as that account,
so it never belongs in a commit.

## Checking that the ways in still work

`flutter test` covers widgets in isolation. It cannot tell you that tapping a button
produces a session, because nothing real is on the other end of it. That is what the
end-to-end suite is for:

```sh
make e2e
```

It needs a booted simulator and a backend running on :8082 with `EMAIL_OUTBOX_DIR` set.
It drives the real app and talks to the real backend, and it covers three flows:

| Flow | What it proves |
|---|---|
| Mehmon sifatida kirish | a guest session is created and the product opens |
| Akkauntingiz bormi? Kirish | an existing account signs in with its password |
| Email bilan kirish | address, code, profile, account created, product opens |

Sign in with Google is not covered. It cannot be driven from a test without a real Google
account and a real consent screen.

Three details of the setup are worth knowing, because each one caused a failure that
looked like a broken app:

* **The signup code is fetched while the test runs, not before it.** Submitting the
  address makes the backend issue a fresh code, so anything read earlier is already
  stale. `scripts/e2e-code-server.py` serves the current one from the outbox over
  localhost. The app is never given the ability to read the outbox.
* **Each flow runs in its own process.** Pumping a second app into a process that already
  has one leaves the first router and its timers alive, and the app dies part way through
  the second flow.
* **`pumpAndSettle` is never used.** The liquid background animates forever, so there is
  never a frame with nothing scheduled, and `pumpAndSettle` would wait until it times out.

## When SMTP is blocked

On many networks, including a lot of consumer ISPs, outbound ports 587 and 465 are
blocked to keep spam off the line. Check before assuming a credential is wrong:

```sh
nc -z -G 6 smtp.gmail.com 587 || echo blocked
```

If it is blocked, no SMTP configuration will ever work from that connection: the TCP
connection never completes, and the backend reports `dial mail server: i/o timeout`.

Use the HTTP mail API instead. It speaks HTTPS on 443, which is always open:

```
RESEND_API_KEY=re_...
RESEND_FROM=onboarding@resend.dev
RESEND_FROM_NAME=Voca
```

Create the key at <https://resend.com> (the free tier needs no card). Until a domain is
verified there, Resend only accepts `onboarding@resend.dev` as the sender and only
delivers to the address the account was registered with, which is enough to test the
flow end to end.

Provider selection is most capable first, so setting the key is all that is needed:

| Configuration | Provider | Where the code goes |
|---|---|---|
| `RESEND_API_KEY` + `RESEND_FROM` | resend | a real inbox, over HTTPS |
| `SMTP_HOST` + `SMTP_FROM` | smtp | a real inbox, if the ports are open |
| `EMAIL_OUTBOX_DIR` only | outbox | a file, readable with `make code` |
| none of the above | log | nowhere |

## Getting the code onto the phone when SMTP is blocked

The outbox works but lives on the developer's disk, which means leaving the phone to read
a terminal. On a network that blocks the SMTP ports and with no mail API key yet, the
development bot is the fastest way to close that gap:

```
EMAIL_VIA_TELEGRAM=true
TELEGRAM_BOT_TOKEN=...
TELEGRAM_CHAT_ID=...
```

Every message the backend would have emailed is posted to that chat instead, with the
intended recipient named at the top so it is never mistaken for the reader's own code.
Telegram's API is HTTPS on 443, which is open where 587 and 465 are not.

This is development only. The provider refuses to start when `APP_ENV=production`,
because a deployment that reached it would be sending every customer's verification code
to one person's chat. Real delivery is `RESEND_API_KEY`.

Provider selection, most capable first:

| Configuration | Provider | Where the code goes |
|---|---|---|
| `RESEND_API_KEY` + `RESEND_FROM` | resend | a real inbox, over HTTPS |
| `SMTP_HOST` + `SMTP_FROM` | smtp | a real inbox, if the ports are open |
| `EMAIL_VIA_TELEGRAM=true` | telegram-dev | the development chat |
| `EMAIL_OUTBOX_DIR` | outbox | a file, readable with `make code` |
| none | log | nowhere |
