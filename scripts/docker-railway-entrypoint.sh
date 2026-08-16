#!/bin/sh
# Railway entrypoint: volumes mounted at /data may contain root-owned state
# written by older root-based images. Re-own the state directory if needed,
# then drop privileges and exec the gateway as the node user.
set -e

if [ -d /data ] && [ "$(stat -c %u /data)" != "1000" ]; then
  chown -R node:node /data
fi

# One-time: migrate legacy workspace setup state into shared SQLite state.
# Must run before the gateway starts, because the gateway holds the SQLite
# lock and the migration fails while it is running. Marker-guarded.
MARKER=/data/.openclaw/.workspace-migrated-2026.7
if [ -d /data/.openclaw ] && [ ! -f "$MARKER" ]; then
  setpriv --reuid node --regid node --init-groups \
    env HOME=/home/node openclaw doctor --fix --yes --non-interactive || true
  touch "$MARKER"
  chown node:node "$MARKER" 2>/dev/null || true
fi

exec setpriv --reuid node --regid node --init-groups \
  env HOME=/home/node node /app/openclaw.mjs gateway "$@"
