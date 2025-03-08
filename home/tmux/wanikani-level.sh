#!/usr/bin/env bash
#!nix-shell -i bash -p jq curl

get_wanikani()
{
    wanikani_level_data=$(curl -s -H "Authorization: Bearer 2da24e4a-ba89-4c4a-9047-d08f21e9dd01" "https://api.wanikani.com/v2/level_progressions")
    wanikani_level=$(echo $wanikani_level_data | jq '.data[-1].data.level')
    wanikani_level_start_date_string=$(echo $wanikani_level_data | jq '.data[-1].data.started_at')
    wanikani_level_start_timestamp=$(date -d "${wanikani_level_start_date_string//\"/}" +%s)

    current_timestamp=$(date +%s)
    difference=$((current_timestamp - wanikani_level_start_timestamp))
    wanikani_level_creation_date=$((difference / 86400))
    echo "At $wanikani_level for $wanikani_level_creation_date days"
}

main()
{
    get_wanikani
    # sleep for 1 hour
    sleep 3600
}

main

