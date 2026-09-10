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
