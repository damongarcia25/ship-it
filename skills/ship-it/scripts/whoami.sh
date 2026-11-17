#!/bin/sh
# Checks SHIPPEDBY_TOKEN against GET /api/v1/me. Prints the username and profile link, or the error.
# The token goes to curl on stdin, so it never shows up in the process list.
set -eu

BASE="${SHIPPEDBY_API_BASE:-https://shippedby.app}"
BASE="${BASE%/}"

if [ -z "${SHIPPEDBY_TOKEN:-}" ]; then
  echo "SHIPPEDBY_TOKEN is not set. Create a token at https://shippedby.app/settings (API tokens), then: export SHIPPEDBY_TOKEN=..." >&2
  exit 2
fi

out=$(printf 'header = "Authorization: Bearer %s"\n' "$SHIPPEDBY_TOKEN" |
  curl -sS -K - --max-time 20 -w '\n%{http_code}' "$BASE/api/v1/me") || {
  echo "Could not reach $BASE." >&2
  exit 1
}
status=$(printf '%s' "$out" | tail -n 1)
body=$(printf '%s' "$out" | sed '$d')

if [ "$status" = "200" ]; then
  printf '%s' "$body" | node -e '
    let s = ""; process.stdin.on("data", (d) => (s += d)).on("end", () => {
      const j = JSON.parse(s);
      console.log(`username: ${j.username}`);
      console.log(`profile_url: ${j.profile_url}`);
    });'
  exit 0
fi

msg=$(printf '%s' "$body" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{console.log(JSON.parse(s).error||s)}catch{console.log(s)}})' 2>/dev/null || printf '%s' "$body")
echo "shippedby answered $status: $msg" >&2
exit 1
