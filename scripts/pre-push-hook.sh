#!/bin/sh
# pre-push: notify GitPulse once the commits actually land on the remote.
#
# Install with: make gitpulse-hook
#
# Git has no post-push hook, so this one starts a background watcher instead of sending
# straight away. The watcher polls the remote until it reports the pushed SHA, and only
# then notifies. A push that is rejected therefore produces no Telegram message.
#
# The hook always exits 0. A notification problem must never block a push.

set -u

REPO_ROOT=$(git rev-parse --show-toplevel)
NOTIFY="$REPO_ROOT/scripts/gitpulse-notify.sh"
[ -x "$NOTIFY" ] || exit 0

REMOTE_NAME="${1:-origin}"

while read -r _local_ref local_sha remote_ref _remote_sha; do
  # Skip a missing SHA, and skip an all-zero one: that means the ref is being deleted,
  # so there is no commit to announce.
  [ -n "$local_sha" ] || continue
  [ -n "$remote_ref" ] || continue
  case "$local_sha" in
    *[!0]*) ;;      # contains a non-zero character, so it is a real commit
    *) continue ;;  # all zeros: a deletion
  esac

  (
    # Give the push time to complete, then confirm the remote really has this commit.
    i=0
    while [ "$i" -lt 20 ]; do
      sleep 1
      actual=$(git ls-remote "$REMOTE_NAME" "$remote_ref" 2>/dev/null | awk '{print $1}')
      if [ "$actual" = "$local_sha" ]; then
        "$NOTIFY" "$local_sha" || true
        exit 0
      fi
      i=$((i + 1))
    done
  ) >/dev/null 2>&1 &
done

exit 0
