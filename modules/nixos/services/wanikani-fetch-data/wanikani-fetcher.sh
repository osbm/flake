#!/usr/bin/env bash
shopt -s nullglob
# provided via systemd EnvironmentFile (age secret)
API_TOKEN="${WANIKANI_API_TOKEN:?WANIKANI_API_TOKEN is not set}"
date=$(date +%Y-%m-%d)

# check if todays date is already in the logs folder
if [ -d "/var/lib/wanikani-logs/wanikani_data_$date" ] || [ -f "/var/lib/wanikani-logs/wanikani_data_$date.zip" ]; then
  echo "Data for today already exists. Exiting..."
  exit 0
fi

tmp_dir=$(mktemp -d)
echo "Temporary directory created at $tmp_dir"

mkdir "$tmp_dir/data"
mkdir -p "/var/lib/wanikani-logs"

fetch_and_merge() {
  local topic="$1"
  local counter=0
  local url="https://api.wanikani.com/v2/$topic"
  local output_file="$tmp_dir/data/$topic.json"
  local next_url="$url"

  echo "Fetching from $url..."

  while [[ -n "$next_url" ]]; do
    local resp_file="$tmp_dir/$topic-page-$counter.json"
    curl -s "$next_url" \
      -H "Wanikani-Revision: 20170710" \
      -H "Authorization: Bearer $API_TOKEN" \
      -o "$resp_file"

    echo -e "\n--- Page $((counter + 1)) (First 20 lines) ---"
    head -n 20 <(jq . "$resp_file")
    # jq . "$resp_file" 2>/dev/null | head -n 20

    next_url=$(jq -r '.pages.next_url // empty' "$resp_file")
    counter=$((counter + 1))
  done

  echo "Merging data..."

  local meta
  meta=$(jq '{object, total_count, data_updated_at}' "$resp_file")
  local files=("$tmp_dir/$topic-page-"*.json)
  jq -cn \
    --argjson meta "$meta" \
    --slurpfile data <(jq -s '[.[] | .data[]]' "${files[@]}") \
    '$meta + {data: $data[0]}' > "$output_file"


  echo "Saved to $output_file"
}

fetch_and_merge assignments
fetch_and_merge level_progressions
fetch_and_merge resets
fetch_and_merge reviews
fetch_and_merge review_statistics
fetch_and_merge spaced_repetition_systems
fetch_and_merge study_materials
fetch_and_merge subjects

# subjects.json is large and WaniKani edits its content (mnemonics, audio,
# meanings) almost daily, so it doesn't go into the daily zip and raw copies
# aren't archived. Keep a single current copy, plus a dated level-map
# snapshot ({id, level, hidden}) only when levels/membership actually change
# (e.g. lessons moved between levels).
current_subjects="/var/lib/wanikani-logs/subjects.json"
new_subjects="$tmp_dir/data/subjects.json"
mkdir -p "/var/lib/wanikani-logs/subjects-changes"

level_map() {
  jq -c '[.data[] | {id, level: .data.level, hidden: (.data.hidden_at != null)}] | sort_by(.id)' "$1"
}

proj_old=""
if [ -f "$current_subjects" ]; then
  proj_old=$(level_map "$current_subjects")
fi
proj_new=$(level_map "$new_subjects")
if [ "$proj_new" != "$proj_old" ]; then
  echo "subject levels/membership changed, archiving level snapshot"
  echo "$proj_new" > "/var/lib/wanikani-logs/subjects-changes/levels_$date.json"
fi
mv "$new_subjects" "$current_subjects"

curl -s "https://api.wanikani.com/v2/summary" \
  -H "Wanikani-Revision: 20170710" \
  -H "Authorization: Bearer $API_TOKEN" \
  -o "$tmp_dir/data/summary.json"

curl -s "https://api.wanikani.com/v2/user" \
  -H "Wanikani-Revision: 20170710" \
  -H "Authorization: Bearer $API_TOKEN" \
  -o "$tmp_dir/data/user.json"


# plain daily folder: directly readable json, ZFS zstd handles compression
mv "$tmp_dir/data" "/var/lib/wanikani-logs/wanikani_data_$date"
chmod 755 "/var/lib/wanikani-logs/wanikani_data_$date"
echo "Data saved to /var/lib/wanikani-logs/wanikani_data_$date"

echo "Cleaning up temporary files..."
rm -r "$tmp_dir"

