#!/bin/zsh
# One-command local development launcher for PawCare Provider Web.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API_DIR="$ROOT/public-api"
WEB_DIR="$ROOT/pawcare-provider-web"
JAR="$API_DIR/target/pawcare-public-api-0.1.0.jar"

# Optional local overrides, deliberately ignored by Git.
[ -f "$ROOT/.env.local" ] && source "$ROOT/.env.local"
export PAWCARE_JWT_SECRET="${PAWCARE_JWT_SECRET:-$(openssl rand -base64 48)}"
export PAWCARE_JWT_ISSUER="${PAWCARE_JWT_ISSUER:-pawcare-public-api}"
export VNPAY_ENABLED="${VNPAY_ENABLED:-false}"

if [ ! -f "$JAR" ] || find "$API_DIR/src" -type f -newer "$JAR" -print -quit | grep -q .; then
  echo 'Building Public API...'
  (cd "$API_DIR" && mvn -DskipTests package)
fi

if ! lsof -i :8081 -sTCP:LISTEN >/dev/null 2>&1; then
  echo 'Starting Public API at http://localhost:8081 ...'
  (cd "$API_DIR" && java -jar "$JAR") > /tmp/pawcare-public-api.log 2>&1 &
  API_PID=$!
  trap 'kill $API_PID 2>/dev/null || true' EXIT INT TERM
  sleep 2
fi

echo 'Starting Provider Web. Open the Local address printed by Vite.'
cd "$WEB_DIR"
exec npm run dev
