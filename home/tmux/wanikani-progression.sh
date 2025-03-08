#!/usr/bin/env bash
#!nix-shell -i bash -p jq curl python312

get_wanikani()
{
    all_subjects=$(curl -s -H "Authorization: Bearer 2da24e4a-ba89-4c4a-9047-d08f21e9dd01" "https://api.wanikani.com/v2/subjects")
    total_subjects=$(echo $all_subjects | jq '.total_count')

    total=0
    for i in {0..9}
    do
        srs_level=$(curl -s -H "Authorization: Bearer 2da24e4a-ba89-4c4a-9047-d08f21e9dd01" "https://api.wanikani.com/v2/assignments?srs_stages=$i" | jq '.total_count')
        # echo "SRS level $i: $srs_level"
        multiplied=$((srs_level * (i + 1)))
        # echo "SRS level $i multiplied: $multiplied"
        total=$((total + multiplied))
        # echo "Total: $total"
    done

    # now i need the percentage of (total/(total_subjects*10))
    # python will be used for this and i need the result to be %23.234
    python_command="python3 -c 'print(f\"{$total/$total_subjects*10:.3f}\")'"
    # echo "Python command: $python_command"
    percentage=$(nix-shell -p python312 --run "$python_command")
    echo "%$percentage"
}

main()
{
    get_wanikani
    # sleep for 1 hour
    sleep 3600
}

main

