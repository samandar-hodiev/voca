#!/bin/sh
# Turn on Sign in with Google, then prove the app will offer it.
#
# Usage:
#   scripts/enable-google.sh <ios-client-id>
#
# The client ID looks like 123456789-abc123.apps.googleusercontent.com and comes from
# Google Cloud console -> APIs & Services -> Credentials -> Create OAuth client ID, with
# application type iOS and bundle ID com.voca.voca. The bundle ID must match exactly or
# Google refuses the token.
#
# Two things are wired, and both are required:
#
#   * The backend accepts tokens minted for this client ID, which is what lets it trust a
#     sign-in. Without it the API reports the method as unavailable and the app greys the
#     button out.
#   * The app registers the REVERSED client ID as a URL scheme. Without that the Google
#     sheet opens and never comes back, because the browser has no way to hand the result
#     to the app.

set -eu

CLIENT_ID="${1:?usage: enable-google.sh <ios-client-id>}"

case "$CLIENT_ID" in
  *.apps.googleusercontent.com) ;;
  *) echo "Bu Google client ID ga o'xshamaydi. U .apps.googleusercontent.com bilan tugaydi." >&2
     exit 1 ;;
esac

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
ENV_FILE="$REPO_ROOT/backend/.env"
PLIST="$REPO_ROOT/mobile/ios/Runner/Info.plist"
API="${VOCA_API:-http://localhost:8082/api/v1}"

# The URL scheme is the client ID with its two halves swapped.
PREFIX=${CLIENT_ID%%.apps.googleusercontent.com}
SCHEME="com.googleusercontent.apps.$PREFIX"

say() { printf '\n== %s\n' "$1"; }

say "backend sozlanmoqda"
CLIENT_ID="$CLIENT_ID" ENV_FILE="$ENV_FILE" python3 - <<'PY'
import os, re
path = os.environ['ENV_FILE']
with open(path) as handle:
    text = handle.read()
key, value = 'GOOGLE_IOS_CLIENT_ID', os.environ['CLIENT_ID']
if re.search(rf'(?m)^#?{key}=', text):
    text = re.sub(rf'(?m)^#?{key}=.*$', f'{key}={value}', text)
else:
    text = text.rstrip('\n') + f'\n{key}={value}\n'
with open(path, 'w') as handle:
    handle.write(text)
print('yozildi')
PY

say "iOS URL sxemasi qo'shilmoqda"
SCHEME="$SCHEME" PLIST="$PLIST" python3 - <<'PY'
import os, plistlib

path = os.environ['PLIST']
scheme = os.environ['SCHEME']

with open(path, 'rb') as handle:
    plist = plistlib.load(handle)

types = plist.setdefault('CFBundleURLTypes', [])
existing = {s for entry in types for s in entry.get('CFBundleURLSchemes', [])}

# Replace any previous Google scheme rather than accumulating dead ones.
types = [
    entry for entry in types
    if not any(s.startswith('com.googleusercontent.apps.')
               for s in entry.get('CFBundleURLSchemes', []))
]

if scheme not in existing or True:
    types.append({'CFBundleURLSchemes': [scheme]})

plist['CFBundleURLTypes'] = types
with open(path, 'wb') as handle:
    plistlib.dump(handle, plist)
print('qo\'shildi')
PY

say "backend qayta ishga tushirilmoqda"
lsof -ti:8082 2>/dev/null | xargs kill 2>/dev/null || true
sleep 2
(cd "$REPO_ROOT/backend" && nohup go run ./cmd/api > /tmp/voca-backend.log 2>&1 &)
until curl -fsS -m 2 -o /dev/null "$API/config" 2>/dev/null; do sleep 2; done

say "tekshiruv"
if curl -fsS -m 5 "$API/config" | grep -q '"google_sign_in":true'; then
  echo "backend Google kirishni yoqdi"
else
  echo "backend hali google_sign_in: false qaytaryapti. Log: /tmp/voca-backend.log" >&2
  exit 1
fi

printf '\nEndi ilovani qayta quring:\n  make mobile-sync && cd /tmp/voca-run/mobile && flutter build ios --simulator --debug\n'
