#!/usr/bin/env bash
# Hourly WaniKani activity snapshot: small delta fetches with updated_after,
# giving hour-resolution review activity (the /v2/reviews endpoint is dead
# upstream, so per-hour history is reconstructed from assignment/statistic
# deltas). The big subjects.json stays with the daily 02:00 job.
API_TOKEN="${WANIKANI_API_TOKEN:?WANIKANI_API_TOKEN is not set}"

base="/var/lib/wanikani-logs/hourly"
state="$base/.last"
mkdir -p "$base"

# hibernation: nothing changes while frozen — succeed quietly
probe=$(curl -s -m 15 -H "Authorization: Bearer $API_TOKEN" "https://api.wanikani.com/v2/user")
if echo "$probe" | grep -q "hibernating"; then
  echo "account hibernating — skipping"
  exit 0
fi

now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
last=$(cat "$state" 2>/dev/null || date -u -d '-1 hour' +%Y-%m-%dT%H:%M:%SZ)

fetch_delta() {
  local topic="$1"
  local next="https://api.wanikani.com/v2/$topic?updated_after=$last"
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
    [[ $counter -gt 20 ]] && break
  done
  jq -cs '{total: (map(.data | length) | add), data: (map(.data[]) )}' "${pages[@]}"
  rm -f "${pages[@]}"
}

assignments=$(fetch_delta assignments)
stats=$(fetch_delta review_statistics)
summary=$(curl -s -m 30 "https://api.wanikani.com/v2/summary" \
  -H "Wanikani-Revision: 20170710" -H "Authorization: Bearer $API_TOKEN")

day=$(date -u +%Y-%m-%d)
hour=$(date -u +%H)
mkdir -p "$base/$day"
jq -cn \
  --arg fetched_at "$now" --arg since "$last" \
  --argjson assignments "$assignments" \
  --argjson review_statistics "$stats" \
  --argjson summary "$summary" \
  '{fetched_at: $fetched_at, since: $since,
    assignments: $assignments, review_statistics: $review_statistics,
    summary: {reviews_pending: ($summary.data.reviews[0].subject_ids | length),
              lessons_pending: ($summary.data.lessons[0].subject_ids | length)}}' \
  > "$base/$day/$hour.json"

echo "$now" > "$state"
touched=$(jq -r '.assignments.total // 0' "$base/$day/$hour.json")
echo "hourly snapshot $day/$hour: $touched assignments updated since $last"
