#!/bin/sh
# Publishes one project with POST /api/v1/projects and prints its shippedby link.
#
#   sh publish.sh --title "..." --tagline "..." --description "..." --live-url "https://..." \
#     [--repo-url "https://..."] [--tags "a, b"] --screenshot /path/to/image.png
#
# Text fields go as --form-string, so a value that starts with @ or < is sent as text, never read as a file.
# The token goes to curl on stdin, so it never shows up in the process list.
set -eu

BASE="${SHIPPEDBY_API_BASE:-https://shippedby.app}"
BASE="${BASE%/}"

title="" tagline="" description="" live_url="" repo_url="" tags="" screenshot=""
while [ $# -gt 0 ]; do
  case "$1" in
    --title) title="$2" ;;
    --tagline) tagline="$2" ;;
    --description) description="$2" ;;
    --live-url) live_url="$2" ;;
    --repo-url) repo_url="$2" ;;
    --tags) tags="$2" ;;
    --screenshot) screenshot="$2" ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
  shift 2
done

if [ -z "${SHIPPEDBY_TOKEN:-}" ]; then
  echo "SHIPPEDBY_TOKEN is not set. Create a token at https://shippedby.app/settings (API tokens), then: export SHIPPEDBY_TOKEN=..." >&2
  exit 2
fi
if [ -z "$screenshot" ] || [ ! -f "$screenshot" ]; then
  echo "No screenshot file at: ${screenshot:-(none given)}" >&2
  exit 2
fi

case "$screenshot" in
  *.png|*.PNG) type="image/png" ;;
  *.jpg|*.jpeg|*.JPG|*.JPEG) type="image/jpeg" ;;
  *.webp|*.WEBP) type="image/webp" ;;
  *) type="application/octet-stream" ;;
esac

set -- --form-string "title=$title" --form-string "tagline=$tagline" --form-string "description=$description" \
  --form-string "live_url=$live_url" --form-string "tags=$tags" -F "screenshot=@$screenshot;type=$type"
if [ -n "$repo_url" ]; then set -- "$@" --form-string "repo_url=$repo_url"; fi

out=$(printf 'header = "Authorization: Bearer %s"\n' "$SHIPPEDBY_TOKEN" |
  curl -sS -K - --max-time 60 -w '\n%{http_code}' "$@" "$BASE/api/v1/projects") || {
  echo "Could not reach $BASE." >&2
  exit 1
}
status=$(printf '%s' "$out" | tail -n 1)
body=$(printf '%s' "$out" | sed '$d')

printf '%s' "$body" | STATUS="$status" node -e '
  let s = ""; process.stdin.on("data", (d) => (s += d)).on("end", () => {
    let j = {};
    try { j = JSON.parse(s); } catch { j = { error: s.trim() || "no answer" }; }
    if (process.env.STATUS === "201") {
      console.log(`Published: ${j.url}`);
      if (j.note) console.log(j.note);
      return;
    }
    console.error(`shippedby answered ${process.env.STATUS}: ${j.error || s}`);
    process.exit(1);
  });'
