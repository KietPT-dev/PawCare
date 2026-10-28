#!/bin/zsh
# Stops only the local PawCare Public API on port 8081, then starts a fresh build.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PIDS=$(lsof -tiTCP:8081 -sTCP:LISTEN 2>/dev/null || true)
if [ -n "$PIDS" ]; then
  echo 'Stopping the previous Public API on port 8081...'
  kill $PIDS 2>/dev/null || true
  sleep 1
fi
exec "$ROOT/scripts/start-provider-demo.sh"
