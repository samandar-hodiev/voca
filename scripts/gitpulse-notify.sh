#!/bin/sh
# Tell GitPulse about a commit that has just landed on the remote.
#
# Why this exists. The intended path is GitHub -> webhook -> ngrok -> GitPulse. On a free
# ngrok plan the public URL changes every restart, so the URL registered in the GitHub
# repository settings goes stale and pushes stop arriving. This script is the local path:
# it builds the same payload GitHub would send, signs it with the same secret, and posts
# it straight to GitPulse. Both paths can be active at once; GitPulse treats them
# identically.
#
# The secret is read from GitPulse's own .env and is never printed or logged.
#
# Usage: scripts/gitpulse-notify.sh <commit-sha>

set -eu

SHA="${1:?usage: gitpulse-notify.sh <commit-sha>}"

GITPULSE_DIR="${GITPULSE_DIR:-$HOME/Desktop/gitpulse/gitpulse}"
GITPULSE_URL="${GITPULSE_URL:-http://localhost:8080/webhook/github}"
GITPULSE_HEALTH="${GITPULSE_HEALTH:-http://localhost:8080/health}"
ENV_FILE="$GITPULSE_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "gitpulse-notify: $ENV_FILE topilmadi, xabar yuborilmadi" >&2
  exit 0
fi

SECRET=$(grep '^GITHUB_WEBHOOK_SECRET=' "$ENV_FILE" | cut -d= -f2-)
if [ -z "$SECRET" ]; then
  echo "gitpulse-notify: GITHUB_WEBHOOK_SECRET bo'sh, xabar yuborilmadi" >&2
  exit 0
fi

# GitPulse must be running locally. If it is not, say so and exit cleanly: a notification
# failure must never turn a successful push into an error.
if ! curl -fsS -m 3 -o /dev/null "$GITPULSE_HEALTH" 2>/dev/null; then
  echo "gitpulse-notify: GitPulse javob bermayapti, xabar yuborilmadi" >&2
  exit 0
fi

REPO_URL=$(git config --get remote.origin.url | sed 's#\.git$##')
REPO_NAME=$(basename "$REPO_URL")
BRANCH=$(git rev-parse --abbrev-ref HEAD)

PAYLOAD=$(
  SHA="$SHA" REPO_URL="$REPO_URL" REPO_NAME="$REPO_NAME" BRANCH="$BRANCH" \
  python3 - <<'PY'
import json, os, subprocess

sha = os.environ["SHA"]

def git(*args):
    return subprocess.run(["git", *args], capture_output=True, text=True).stdout.strip()

added, modified, removed = [], [], []
for line in git("show", "--name-status", "--pretty=", sha).splitlines():
    parts = line.split("\t")
    if len(parts) < 2:
        continue
    status, path = parts[0][:1], parts[-1]
    {"A": added, "M": modified, "D": removed}.get(status, modified).append(path)

payload = {
    "ref": f"refs/heads/{os.environ['BRANCH']}",
    "repository": {
        "name": os.environ["REPO_NAME"],
        "html_url": os.environ["REPO_URL"],
    },
    "head_commit": {
        "id": sha,
        "message": git("log", "-1", "--pretty=%B", sha),
        "timestamp": git("log", "-1", "--date=iso-strict", "--pretty=%ad", sha),
        "url": f"{os.environ['REPO_URL']}/commit/{sha}",
        "author": {
            "name": git("log", "-1", "--pretty=%an", sha),
            "email": git("log", "-1", "--pretty=%ae", sha),
        },
        "added": added,
        "modified": modified,
        "removed": removed,
    },
}
print(json.dumps(payload))
PY
)

SIG="sha256=$(printf '%s' "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" -hex | awk '{print $2}')"

CODE=$(printf '%s' "$PAYLOAD" | curl -s -m 15 -o /dev/null -w '%{http_code}' \
  -X POST "$GITPULSE_URL" \
  -H 'Content-Type: application/json' \
  -H 'X-GitHub-Event: push' \
  -H "X-Hub-Signature-256: $SIG" \
  --data-binary @-)

if [ "$CODE" = "200" ]; then
  echo "gitpulse-notify: Telegramga yuborildi ($(printf '%s' "$SHA" | cut -c1-7))"
else
  echo "gitpulse-notify: GitPulse $CODE qaytardi" >&2
fi
