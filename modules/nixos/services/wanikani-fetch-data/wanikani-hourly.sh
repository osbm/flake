#!/usr/bin/env bash
# Hourly WaniKani snapshot: FULL assignments + review_statistics each run
# (self-contained files — no delta chains; a lost hour loses only that hour).
# Dead hours (no data change) write a tiny stub instead of a 2MB duplicate.
# The big subjects.json stays with the daily 02:00 job.
API_TOKEN="${WANIKANI_API_TOKEN:?WANIKANI_API_TOKEN is not set}"

base="/var/lib/wanikani-logs/hourly"
mkdir -p "$base"

# hibernation: nothing changes while frozen — succeed quietly
probe=$(curl -s -m 15 -H "Authorization: Bearer $API_TOKEN" "https://api.wanikani.com/v2/user")
if echo "$probe" | grep -q "hibernating"; then
  echo "account hibernating — skipping"
  exit 0
fi

now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
day=$(date -u +%Y-%m-%d)
hour=$(date -u +%H)
mkdir -p "$base/$day"
out="$base/$day/$hour.json"

fetch_full() {
  local topic="$1"
  local next="https://api.wanikani.com/v2/$topic"
  local pages=()
  local counter=0
  while [[ -n "$next" ]]; do
    local page
    page=$(mktemp)
    curl -s -m 30 "$next" \
      -H "Wanikani-Revision: 20170710" \
      -H "Authorization: Bearer $API_TOKEN" -o "$page"
    pages+=("$page")
    next=$(jq -r '.pages.next_url // empty' "$page")
    counter=$((counter + 1))
    [[ $counter -gt 40 ]] && break
  done
  jq -cs '{object: .[0].object, total_count: .[0].total_count,
           data_updated_at: .[0].data_updated_at,
           data: (map(.data[]))}' "${pages[@]}"
  rm -f "${pages[@]}"
}

# cheap change probe: the endpoints report data_updated_at on a 1-page HEAD-ish call
stamp() {
  curl -s -m 30 "https://api.wanikani.com/v2/$1?page_after_id=99999999" \
    -H "Wanikani-Revision: 20170710" \
    -H "Authorization: Bearer $API_TOKEN" | jq -r '.data_updated_at // empty'
}
a_stamp=$(stamp assignments)
s_stamp=$(stamp review_statistics)

prev=$(find "$base" -name "*.json" -not -name "$hour.json" | sort | tail -1)
if [ -n "$prev" ]; then
  prev_a=$(jq -r '.stamps.assignments // empty' "$prev" 2>/dev/null)
  prev_s=$(jq -r '.stamps.review_statistics // empty' "$prev" 2>/dev/null)
  if [ "$a_stamp" = "$prev_a" ] && [ "$s_stamp" = "$prev_s" ]; then
    jq -cn --arg t "$now" --arg a "$a_stamp" --arg s "$s_stamp" \
      '{fetched_at:$t, unchanged:true, stamps:{assignments:$a, review_statistics:$s}}' > "$out"
    echo "no activity — stub written"
    exit 0
  fi
fi

assignments=$(fetch_full assignments)
stats=$(fetch_full review_statistics)
summary=$(curl -s -m 30 "https://api.wanikani.com/v2/summary" \
  -H "Wanikani-Revision: 20170710" -H "Authorization: Bearer $API_TOKEN")

jq -cn \
  --arg t "$now" --arg a "$a_stamp" --arg s "$s_stamp" \
  --argjson assignments "$assignments" \
  --argjson review_statistics "$stats" \
  --argjson summary "$summary" \
  '{fetched_at: $t, unchanged: false,
    stamps: {assignments: $a, review_statistics: $s},
    summary: {reviews_pending: ($summary.data.reviews[0].subject_ids | length),
              lessons_pending: ($summary.data.lessons[0].subject_ids | length)},
    assignments: $assignments, review_statistics: $review_statistics}' \
  > "$out"

echo "full snapshot $day/$hour.json ($(stat -c%s "$out") bytes)"
