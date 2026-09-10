#!/bin/sh
# Drive the four ways into the product on a simulator, against the real backend.
#
# What this proves, and why each piece is here:
#
#   * Guest      needs nothing but a running backend.
#   * Login      needs an account that already exists, so one is created first over HTTP.
#   * Signup     needs the six-digit code, which only exists in the recipient's inbox. The
#                app asks for a fresh code the moment the address is submitted, so the
#                code has to be read DURING the run. A small helper on localhost serves it
#                out of the development outbox; the app is never given the ability to read
#                the outbox itself.
#
# The backend must be running on :8082 with EMAIL_OUTBOX_DIR set. Nothing here writes to
# the repository or to the simulator's other apps.

set -eu

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
API="${VOCA_API:-http://localhost:8082/api/v1}"
OUTBOX="${VOCA_OUTBOX:-$REPO_ROOT/backend/tmp/mail}"
RUN_DIR="${VOCA_MOBILE_RUN_DIR:-/tmp/voca-run/mobile}"
CODE_PORT="${VOCA_CODE_PORT:-8099}"

say() { printf '\n== %s\n' "$1"; }

say "backend tekshirilmoqda"
if ! curl -fsS -m 5 -o /dev/null "$API/config"; then
  echo "backend $API manzilida javob bermayapti" >&2
  exit 1
fi

say "simulyator tanlanmoqda"
UDID=$(xcrun simctl list devices booted -j | python3 -c "
import sys, json
devices = json.load(sys.stdin)['devices']
booted = [d for v in devices.values() for d in v]
print(booted[0]['udid'] if booted else '')
")
if [ -z "$UDID" ]; then
  echo "yoqilgan simulyator topilmadi" >&2
  exit 1
fi

stamp=$(date +%s)
LOGIN_EMAIL="e2e.login.$stamp@example.com"
LOGIN_PASSWORD="ParolE2E123!"
SIGNUP_EMAIL="e2e.signup.$stamp@example.com"

post() {
  curl -fsS -m 15 -X POST "$API/$1" -H 'Content-Type: application/json' -d "$2"
}

# The outbox keeps a recipient usable as a file name by replacing everything outside
# [A-Za-z0-9.-] with an underscore, so only the "@" changes and the dots survive.
outbox_name() {
  printf '%s' "$1" | tr -c 'A-Za-z0-9.-' '_'
}

# Reads the code out of the newest matching outbox file. The provider writes the code on
# a "code = ######" line, so nothing has to parse the prose around it.
read_code() {
  file=$(ls -t "$OUTBOX"/*"$1"* 2>/dev/null | head -1)
  if [ -z "$file" ]; then
    echo "outbox faylida $1 uchun xabar topilmadi ($OUTBOX)" >&2
    exit 1
  fi
  awk '/code = /{print $3; exit}' "$file"
}

say "login testi uchun akkaunt yaratilmoqda"
post "auth/email/start" "{\"email\":\"$LOGIN_EMAIL\"}" >/dev/null
sleep 1
LOGIN_CODE=$(read_code "$(outbox_name "$LOGIN_EMAIL")")
post "auth/email/verify" "{\"email\":\"$LOGIN_EMAIL\",\"code\":\"$LOGIN_CODE\"}" >/dev/null
post "auth/register" "{\"email\":\"$LOGIN_EMAIL\",\"password\":\"$LOGIN_PASSWORD\",\
\"first_name\":\"E2E\",\"last_name\":\"Login\",\"cefr_level\":\"A2\",\
\"learning_goal\":\"confidence\",\"daily_goal_words\":10}" >/dev/null
echo "akkaunt tayyor: $LOGIN_EMAIL"

say "kod yordamchisi ishga tushmoqda"
python3 "$REPO_ROOT/scripts/e2e-code-server.py" "$OUTBOX" "$CODE_PORT" &
CODE_SERVER_PID=$!
trap 'kill "$CODE_SERVER_PID" 2>/dev/null || true' EXIT INT TERM
sleep 1
if ! kill -0 "$CODE_SERVER_PID" 2>/dev/null; then
  echo "kod yordamchisi ishga tushmadi" >&2
  exit 1
fi

# The signup code is deliberately NOT fetched here. Submitting the address inside the app
# makes the backend issue a new one, so anything read now would already be stale. The test
# reads the outbox itself at the moment the code screen appears.

say "manbalar sinxronlanmoqda"
make -C "$REPO_ROOT" mobile-sync >/dev/null

# Each scenario runs in its own process. Pumping a second app into a process that already
# has one leaves the first router, its timers and its provider scope alive, and the app
# dies part way through the second scenario. One process per flow also means a failure
# names exactly which way in is broken.
cd "$RUN_DIR"
FAILED=""

run_flow() {
  say "$1"
  if flutter test integration_test/auth_flows_test.dart -d "$UDID" \
      --plain-name "$2" \
      --dart-define=E2E_LOGIN_EMAIL="$LOGIN_EMAIL" \
      --dart-define=E2E_LOGIN_PASSWORD="$LOGIN_PASSWORD" \
      --dart-define=E2E_SIGNUP_EMAIL="$SIGNUP_EMAIL" \
      --dart-define=E2E_CODE_SERVER="http://127.0.0.1:$CODE_PORT/code"; then
    echo "OK: $1"
  else
    echo "YIQILDI: $1" >&2
    FAILED="$FAILED
  - $1"
  fi
}

run_flow "mehmon sifatida kirish" "guest sign-in"
run_flow "mavjud akkauntga kirish" "signing in to an existing account"
run_flow "email bilan akkaunt yaratish" "creating an account with email"

if [ -n "$FAILED" ]; then
  printf '\nYiqilgan oqimlar:%s\n' "$FAILED" >&2
  exit 1
fi

printf '\nBarcha kirish yo\047llari ishlayapti.\n'
