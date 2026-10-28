#!/bin/zsh
# Starts the PawCare Public API for local development on its one fixed port:
# http://127.0.0.1:8081/api/v1
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API_DIR="$ROOT/public-api"

if lsof -iTCP:8081 -sTCP:LISTEN >/dev/null 2>&1; then
  echo 'PawCare Public API is already running on http://127.0.0.1:8081.'
  exit 0
fi

# Optional local database/JWT values, deliberately excluded from Git.
[ -f "$ROOT/.env.local" ] && source "$ROOT/.env.local"
export PAWCARE_JWT_SECRET="${PAWCARE_JWT_SECRET:-$(openssl rand -base64 48)}"
export PAWCARE_JWT_ISSUER="${PAWCARE_JWT_ISSUER:-pawcare-public-api}"
export VNPAY_ENABLED="${VNPAY_ENABLED:-false}"

echo 'Starting PawCare Public API at http://127.0.0.1:8081/api/v1 ...'
cd "$API_DIR"
exec mvn spring-boot:run
