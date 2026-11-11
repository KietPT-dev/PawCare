#!/usr/bin/env zsh
# Requires: Public API running, mysql CLI, PAWCARE_DB_USERNAME/PASSWORD and
# PAWCARE_WALLET_WEBHOOK_TOKEN. Creates demo records only.
# Creates demo records prefixed AUTO-E2E and does not touch Bonita records.
set -euo pipefail
: "${PAWCARE_DB_USERNAME:?Set database username}"
: "${PAWCARE_DB_PASSWORD:?Set database password}"
: "${PAWCARE_WALLET_WEBHOOK_TOKEN:?Set the local webhook token}"
[[ "${PAWCARE_E2E_ALLOW_DB_SETUP:-}" == true ]] || { print -u2 'Set PAWCARE_E2E_ALLOW_DB_SETUP=true'; exit 2; }
BASE="${PAWCARE_API_URL:-http://localhost:8081/api/v1}"; STAMP="$(date +%s)"; PASS='AutoE2Epass123'
CEMAIL="auto-e2e-customer-${STAMP}@pawcare.test"; PEMAIL="auto-e2e-provider-${STAMP}@pawcare.test"
DB=(mysql --protocol=TCP -h localhost -P 3306 -u "$PAWCARE_DB_USERNAME" "-p$PAWCARE_DB_PASSWORD" -N -B pawcare)
field(){ python3 -c "import json,sys; print(json.load(sys.stdin)$1)"; }
call(){ local want="$1"; shift; local f s b; f=$(mktemp); s=$(curl -sS -o "$f" -w '%{http_code}' "$@"); b=$(cat "$f"); rm -f "$f"; [[ "$s" == "$want" ]] || { print -u2 "FAIL: expected $want, got $s: $b"; exit 1; }; print -r -- "$b"; }
ok(){ print "PASS — $1"; }
"${DB[@]}" -e 'SELECT 1' >/dev/null

P=$(call 201 -X POST "$BASE/auth/register" -H 'Content-Type: application/json' -d "{\"fullName\":\"AUTO-E2E Provider $STAMP\",\"providerName\":\"AUTO-E2E Clinic $STAMP\",\"providerType\":\"SHOP\",\"email\":\"$PEMAIL\",\"phone\":\"0900000000\",\"address\":\"Demo\",\"password\":\"$PASS\",\"role\":\"PROVIDER\"}")
PT=$(print -r -- "$P"|field "['accessToken']"); PID=$("${DB[@]}" -e "SELECT p.id FROM providers p JOIN user_profiles u ON u.id=p.owner_profile_id WHERE u.email='$PEMAIL'")
"${DB[@]}" -e "UPDATE providers SET status='APPROVED' WHERE id=$PID"
CAT=$("${DB[@]}" -e 'SELECT id FROM service_categories WHERE is_active=1 ORDER BY id LIMIT 1'); [[ -n "$CAT" ]] || { print -u2 'No active category'; exit 1; }
S=$(call 200 -X POST "$BASE/provider/services" -H "Authorization: Bearer $PT" -H 'Content-Type: application/json' -d "{\"categoryId\":$CAT,\"name\":\"AUTO-E2E Service $STAMP\",\"price\":150000,\"durationMinutes\":60,\"petTypeSupported\":\"DOG\"}")
SID=$(print -r -- "$S"|field "['id']"); T=$(call 200 -X POST "$BASE/provider/staff" -H "Authorization: Bearer $PT" -H 'Content-Type: application/json' -d "{\"fullName\":\"AUTO-E2E Staff $STAMP\",\"skills\":\"Grooming\"}")
TID=$(print -r -- "$T"|field "['id']")
call 200 -X POST "$BASE/provider/schedules" -H "Authorization: Bearer $PT" -H 'Content-Type: application/json' -d "{\"staffId\":$TID,\"startAt\":\"2026-12-20T08:00:00\",\"endAt\":\"2026-12-20T18:00:00\",\"status\":\"AVAILABLE\"}" >/dev/null
ok 'Provider, service, staff and schedule'

C=$(call 201 -X POST "$BASE/auth/register" -H 'Content-Type: application/json' -d "{\"fullName\":\"AUTO-E2E Customer $STAMP\",\"email\":\"$CEMAIL\",\"password\":\"$PASS\",\"role\":\"CUSTOMER\"}")
CT=$(print -r -- "$C"|field "['accessToken']"); call 200 "$BASE/auth/me" -H "Authorization: Bearer $CT" >/dev/null
PET=$(call 200 -X POST "$BASE/pets" -H "Authorization: Bearer $CT" -H 'Content-Type: application/json' -d '{"name":"AUTO-E2E Milo","species":"DOG","gender":"MALE"}')
PETID=$(print -r -- "$PET"|field "['id']"); TIME='2026-12-20T09:00:00'
BEFORE=$(call 200 "$BASE/availability/providers/$PID?serviceId=$SID&bookingStart=$TIME"); [[ $(print -r -- "$BEFORE"|field "['available']") == True ]] || { print -u2 'Staff should be available'; exit 1; }
call 200 "$BASE/recommendations?petId=$PETID&bookingStart=$TIME" -H "Authorization: Bearer $CT" >/dev/null
ok 'Customer JWT, pet and MT6 recommendation/availability'

B=$(call 200 -X POST "$BASE/bookings" -H "Authorization: Bearer $CT" -H 'Content-Type: application/json' -d "{\"petId\":$PETID,\"providerId\":$PID,\"serviceId\":$SID,\"staffId\":$TID,\"bookingStart\":\"$TIME\",\"paymentMethod\":\"VIETQR\"}")
BID=$(print -r -- "$B"|field "['id']"); AFTER=$(call 200 "$BASE/availability/providers/$PID?serviceId=$SID&bookingStart=$TIME"); [[ $(print -r -- "$AFTER"|field "['available']") == False ]] || { print -u2 'Booked staff must be unavailable'; exit 1; }
PCODE=$(print -r -- "$B"|field "['payment']['paymentCode']")
TX="AUTO-E2E-$STAMP"
call 200 -X POST "$BASE/payments/webhook" -H "Authorization: Apikey $PAWCARE_WALLET_WEBHOOK_TOKEN" -H 'Content-Type: application/json' -d "{\"referenceCode\":\"$TX\",\"transferAmount\":150000,\"content\":\"$PCODE\"}" >/dev/null
# Duplicate delivery must not create a second deposit/hold.
call 200 -X POST "$BASE/payments/webhook" -H "Authorization: Bearer $PAWCARE_WALLET_WEBHOOK_TOKEN" -H 'Content-Type: application/json' -d "{\"referenceCode\":\"$TX\",\"transferAmount\":150000,\"content\":\"$PCODE\"}" >/dev/null
ok 'VietQR webhook escrow hold and duplicate protection'
for X in CONFIRMED CHECKED_IN IN_SERVICE; do call 200 -X PUT "$BASE/bookings/$BID/status" -H "Authorization: Bearer $PT" -H 'Content-Type: application/json' -d "{\"status\":\"$X\"}" >/dev/null; done
call 200 -X PUT "$BASE/bookings/$BID/status" -H "Authorization: Bearer $PT" -H 'Content-Type: application/json' -d '{"status":"SERVICE_DONE","providerNote":"AUTO-E2E service done"}' >/dev/null
call 200 -X POST "$BASE/bookings/$BID/confirm-completion" -H "Authorization: Bearer $CT" -H 'Content-Type: application/json' -d '{"note":"AUTO-E2E confirmed"}' >/dev/null
call 200 -X POST "$BASE/reviews" -H "Authorization: Bearer $CT" -H 'Content-Type: application/json' -d "{\"bookingId\":$BID,\"rating\":5,\"comment\":\"AUTO-E2E\"}" >/dev/null
ok 'Two-party booking completion, payout and review'
print 'E2E PASS — Public API wallet/escrow flow. Bonita UI approval remains a manual check.'
