#!/bin/sh
# Point the backend at a mail provider that delivers to any recipient, then prove it.
#
# Usage:
#   scripts/enable-email.sh <brevo-api-key> <verified-sender-address> [test-recipient]
#
# Brevo rather than Resend, because Brevo delivers to anyone once a single sender ADDRESS
# is verified, while Resend needs a verified DOMAIN before it will send to anybody but the
# account owner. Before the product owns a domain, Brevo is the only one of the two that
# can reach a stranger's inbox.
#
# The key is written to backend/.env, which is gitignored, and is never printed.

set -eu

KEY="${1:?usage: enable-email.sh <brevo-api-key> <sender-address> [test-recipient]}"
SENDER="${2:?usage: enable-email.sh <brevo-api-key> <sender-address> [test-recipient]}"
RECIPIENT="${3:-$SENDER}"

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
ENV_FILE="$REPO_ROOT/backend/.env"
API="${VOCA_API:-http://localhost:8082/api/v1}"

case "$KEY" in
  xkeysib-*) ;;
  *) echo "Bu Brevo kalitiga o'xshamaydi, u xkeysib- bilan boshlanadi." >&2; exit 1 ;;
esac

say() { printf '\n== %s\n' "$1"; }

say "sozlama yozilmoqda"
KEY="$KEY" SENDER="$SENDER" ENV_FILE="$ENV_FILE" python3 - <<'PY'
import os, re

path = os.environ['ENV_FILE']
with open(path) as handle:
    text = handle.read()

# Brevo takes precedence over Resend in provider selection, so the old key can stay.
values = {
    'BREVO_API_KEY': os.environ['KEY'],
    'BREVO_FROM': os.environ['SENDER'],
    'BREVO_FROM_NAME': 'Voca',
}
for key, value in values.items():
    if re.search(rf'(?m)^#?{key}=', text):
        text = re.sub(rf'(?m)^#?{key}=.*$', f'{key}={value}', text)
    else:
        text = text.rstrip('\n') + f'\n{key}={value}\n'

with open(path, 'w') as handle:
    handle.write(text)
print('yozildi')
PY

say "backend qayta ishga tushirilmoqda"
lsof -ti:8082 2>/dev/null | xargs kill 2>/dev/null || true
sleep 2
(cd "$REPO_ROOT/backend" && nohup go run ./cmd/api > /tmp/voca-backend.log 2>&1 &) 
until curl -fsS -m 2 -o /dev/null "$API/config" 2>/dev/null; do sleep 2; done

if ! grep -q '"provider":"brevo"' /tmp/voca-backend.log; then
  echo "Brevo tanlanmadi. Log: /tmp/voca-backend.log" >&2
  exit 1
fi
echo "provider: brevo"

say "haqiqiy yuborish sinovi: $RECIPIENT"
CODE=$(curl -s -m 30 -o /tmp/voca-email-test.json -w '%{http_code}' \
  -X POST "$API/auth/email/start" -H 'Content-Type: application/json' \
  -d "{\"email\":\"$RECIPIENT\"}")

sleep 3
if grep -q '"provider":"brevo"' /tmp/voca-backend.log && \
   grep -q 'email_sent' /tmp/voca-backend.log; then
  printf '\nHaqiqiy xat yuborildi. %s pochtasini tekshiring.\n' "$RECIPIENT"
  exit 0
fi

echo "" >&2
echo "Yuborilmadi (HTTP $CODE). Sabab:" >&2
grep -E 'brevo_rejected_message|brevo_send_failed' /tmp/voca-backend.log | tail -1 >&2
echo "" >&2
echo "Eng keng tarqalgan sabab: jo'natuvchi manzil Brevo'da tasdiqlanmagan." >&2
echo "Settings -> Senders bo'limida $SENDER ni qo'shing va kelgan havolani bosing." >&2
exit 1
