#!/bin/sh
# Railway entrypoint: volumes mounted at /data may contain root-owned state
# written by older root-based images. Re-own the state directory, then drop
# privileges and exec the gateway as the node user.
set -e

if [ -d /data ] && [ "$(stat -c %u /data)" != "1000" ]; then
  chown -R node:node /data
fi

exec setpriv --reuid node --regid node --init-groups \
  env HOME=/home/node node /app/openclaw.mjs gateway "$@"
