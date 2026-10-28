#!/usr/bin/env zsh
set -euo pipefail

BASE_URL="${PAWCARE_API_URL:-http://localhost:8081/api/v1}"
STAMP="$(date +%s)"
EMAIL="demo.customer.${STAMP}@pawcare.test"
PASSWORD='DemoPass123!'

json_status() {
  local expected="$1"; shift
  local temp status body
  temp="$(mktemp)"
  status="$(curl -sS -o "$temp" -w '%{http_code}' "$@")"
  body="$(cat "$temp")"
  rm -f "$temp"
  if [[ "$status" != "$expected" ]]; then
    print -u2 "FAIL expected HTTP $expected, received $status"
    print -u2 "$body"
    exit 1
  fi
  print -r -- "$body"
}

print '1/6 Catalog providers'
json_status 200 "$BASE_URL/providers" >/dev/null
print 'PASS'

print '2/6 Catalog categories'
json_status 200 "$BASE_URL/categories" >/dev/null
print 'PASS'

print '3/6 Register a new customer'
json_status 201 -X POST "$BASE_URL/auth/register" -H 'Content-Type: application/json' \
  -d "{\"fullName\":\"Demo Customer $STAMP\",\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"role\":\"CUSTOMER\"}" >/dev/null
print 'PASS'

print '4/6 Login'
LOGIN="$(json_status 200 -X POST "$BASE_URL/auth/login" -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")"
TOKEN="$(print -r -- "$LOGIN" | sed -n 's/.*"accessToken":"\([^"]*\)".*/\1/p')"
if [[ -z "$TOKEN" ]]; then print -u2 'FAIL Login response does not contain accessToken'; exit 1; fi
print 'PASS'

print '5/6 Create a pet'
PET="$(json_status 200 -X POST "$BASE_URL/pets" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"name":"Milo Demo","species":"DOG","breed":"Poodle","gender":"MALE","weightKg":4.2}')"
PET_ID="$(print -r -- "$PET" | sed -n 's/.*"id":\([0-9]*\).*/\1/p')"
if [[ -z "$PET_ID" ]]; then print -u2 'FAIL Pet response does not contain id'; exit 1; fi
print 'PASS'

print '6/6 Get recommendations'
json_status 200 "$BASE_URL/recommendations?petId=$PET_ID" -H "Authorization: Bearer $TOKEN" >/dev/null
print 'PASS'

print ''
print 'Public API basic demo completed.'
print "Customer email: $EMAIL"
print "Customer password: $PASSWORD"
print "Pet ID: $PET_ID"
print "Access token: $TOKEN"
print 'Continue with docs/DEMO_TEST.md section 3 to test booking, MT6 availability and VNPAY.'
