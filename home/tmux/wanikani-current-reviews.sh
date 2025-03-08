#!/usr/bin/env bash
#!nix-shell -i bash -p jq curl

get_wanikani()
{
    wanikani_reviews=$(curl -s -H "Authorization: Bearer 2da24e4a-ba89-4c4a-9047-d08f21e9dd01" "https://api.wanikani.com/v2/assignments?immediately_available_for_review=true" | jq '.total_count')
    wanikani_lessons=$(curl -s -H "Authorization: Bearer 2da24e4a-ba89-4c4a-9047-d08f21e9dd01" "https://api.wanikani.com/v2/assignments?immediately_available_for_lessons=true" | jq '.total_count')

    echo "$wanikani_lessons lessons $wanikani_reviews reviews"
}

main()
{
    get_wanikani
    # sleep for 10 minutes
    sleep 600
}

main

