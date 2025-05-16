#!/usr/bin/env bash
shopt -s nullglob
API_TOKEN="2da24e4a-ba89-4c4a-9047-d08f21e9dd01"

tmp_dir=$(mktemp -d)
echo "Temporary directory created at $tmp_dir"

mkdir "$tmp_dir/data"

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
    cat "$resp_file" | jq | head -n 20

    next_url=$(jq -r '.pages.next_url // empty' "$resp_file")
    ((counter++))
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

curl -s "https://api.wanikani.com/v2/summary" \
  -H "Wanikani-Revision: 20170710" \
  -H "Authorization: Bearer $API_TOKEN" \
  -o "$tmp_dir/data/summary.json"

curl -s "https://api.wanikani.com/v2/user" \
  -H "Wanikani-Revision: 20170710" \
  -H "Authorization: Bearer $API_TOKEN" \
  -o "$tmp_dir/data/user.json"


# get the date as a variable and use it to zip the data folder
date=$(date +%Y-%m-%d)
zip -r "$tmp_dir/wanikani_data_$date.zip" "$tmp_dir/data"
echo "Data zipped to $tmp_dir/wanikani_data_$date.zip"

echo "$tmp_dir"
# rm -r "$tmp_dir"