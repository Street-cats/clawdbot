#!/bin/sh
# Railway entrypoint: volumes mounted at /data may contain root-owned state
# written by older root-based images. Re-own the state directory, then drop
# privileges and exec the gateway as the node user.
set -e

if [ -d /data ] && [ "$(stat -c %u /data)" != "1000" ]; then
  chown -R node:node /data
fi

# One-time migration: restore the full pre-downgrade config (written by
# 2026.7.x) over the trimmed 2026.2.9-compatible config, then run doctor to
# migrate the state database. Guarded by a marker file; runs only once.
CFG=/data/.openclaw/openclaw.json
BAK=/data/.openclaw/openclaw.json.pre-doctor-fix.bak
MARKER=/data/.openclaw/.config-restored-2026.7
if [ -f "$BAK" ] && [ ! -f "$MARKER" ]; then
  cp "$CFG" "$CFG.pre-restore.bak" 2>/dev/null || true
  cp "$BAK" "$CFG"
  setpriv --reuid node --regid node --init-groups \
    env HOME=/home/node openclaw doctor --fix --yes --non-interactive || true
  touch "$MARKER"
  chown node:node "$CFG" "$MARKER" 2>/dev/null || true
fi

exec setpriv --reuid node --regid node --init-groups \
  env HOME=/home/node node /app/openclaw.mjs gateway "$@"
