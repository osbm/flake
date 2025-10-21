{
  lib,
  config,
  pkgs,
  ...
}:
let
  waniKani-bypass-lessons = pkgs.writeShellApplication {
    name = "wanikani-bypass-lessons";
    runtimeInputs = with pkgs; [
      curl
      jq
    ];
    text = ''
      #!/usr/bin/env bash

      # this token that starts with "2da24" is read only so i am keeping it public, i have nothing secret on my wanikani account
      # but i need a write token for the second part of this script

      # i am going to read it from /persist/wanikani

      [ ! -e /persist/wanikani ] && echo "/persist/wanikani doesnt exist here :(" && exit 1

      WANIKANI_TOKEN=$(< /persist/wanikani)

      # Maximum number of reviews to maintain
      MAX_REVIEWS=200

      echo "=== Checking current reviews ==="

      # Get current reviews (SRS stages 0-4)
      current_reviews=0
      for i in {0..4}; do
          stage_count=$(curl -s -H "Authorization: Bearer 2da24e4a-ba89-4c4a-9047-d08f21e9dd01" "https://api.wanikani.com/v2/assignments?srs_stages=$i" | jq '.total_count')
          current_reviews=$((current_reviews + stage_count))
          echo "SRS stage $i: $stage_count items"
      done

      echo "Current total reviews: $current_reviews"
      echo "Maximum reviews target: $MAX_REVIEWS"

      if [ "$current_reviews" -ge "$MAX_REVIEWS" ]; then
          echo "Reviews ($current_reviews) >= max ($MAX_REVIEWS). No lessons to bypass."
          sleep 3600
          exit 0
      fi

      lessons_to_bypass=$((MAX_REVIEWS - current_reviews))
      echo "Need to bypass $lessons_to_bypass lessons to reach $MAX_REVIEWS total"

      # Get available lessons (limited to what we need)
      ASSIGNMENT_IDS=$(curl -s -H "Authorization: Bearer 2da24e4a-ba89-4c4a-9047-d08f21e9dd01" "https://api.wanikani.com/v2/assignments?immediately_available_for_lessons=true" | jq -r ".data[] | .id" | head -n "$lessons_to_bypass")

      available_lessons=$(echo "$ASSIGNMENT_IDS" | wc -l)
      echo "Available lessons: $available_lessons"

      if [ "$available_lessons" -eq 0 ]; then
          echo "No lessons available to bypass."
          sleep 3600
          exit 0
      fi

      # Limit to what we actually need
      actual_bypass=$(echo "$ASSIGNMENT_IDS" | wc -l)
      echo "Will bypass $actual_bypass lessons"

      # "2017-09-05T23:41:28.980679Z" i need to create this from current time

      TIME_STRING=$(date -u +"%Y-%m-%dT%H:%M:%S.%6NZ")
      echo "Current time: $TIME_STRING"

      echo "=== Starting assignments ==="
      for assignment_id in $ASSIGNMENT_IDS; do
          echo "Starting assignment $assignment_id"
          curl -s "https://api.wanikani.com/v2/assignments/$assignment_id/start" \
              -X "PUT" \
              -H "Wanikani-Revision: 20170710" \
              -H "Content-Type: application/json; charset=utf-8" \
              -H "Authorization: Bearer $WANIKANI_TOKEN" \
              -d "{\"assignment\": {\"started_at\": \"$TIME_STRING\" }}"
          echo
          sleep 1
      done

      echo "Successfully bypassed $actual_bypass lessons"
      echo "New total should be approximately: $((current_reviews + actual_bypass))"
      sleep 3600
    '';
  };
in
{
  options.services.wanikani-bypass-lessons.enable = lib.mkEnableOption {
    description = "Enable WaniKani Bypass Lessons";
    default = config.osbmModules.services.wanikani-bypass-lessons.enable or false;
  };

  config = lib.mkIf config.services.wanikani-bypass-lessons.enable {
    systemd.services.wanikani-bypass-lessons = {
      description = "WaniKani Bypass Lessons";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe waniKani-bypass-lessons}";
        Restart = "always";
        RestartSec = 60 * 60;
      };
    };
  };
}
