{lib, config, pkgs, ...}: let

  waniKani-bypass-lessons = pkgs.writeShellApplication{

    name = "wanikani-bypass-lessons";
    runtimeInputs = with pkgs; [ curl jq ];
    text = ''
    #!/usr/bin/env bash

    # this token that starts with "2da24" is read only so i am keeping it public, i have nothing secret on my wanikani account
    # but i need a write token for the second part of this script

    # i am going to read it from /persist/wanikani

    [ ! -e /persist/wanikani ] && echo "/persist/wanikani doesnt exist here :("

    WANIKANI_TOKEN=$(< /persist/wanikani)

    ASSIGNMENT_IDS=$(curl -s -H "Authorization: Bearer 2da24e4a-ba89-4c4a-9047-d08f21e9dd01" "https://api.wanikani.com/v2/assignments?immediately_available_for_lessons=true" | jq ".data[] | .id" )

    echo "number of assignments: $(echo "$ASSIGNMENT_IDS" | wc -l)"

    # "2017-09-05T23:41:28.980679Z" i need to create this from current time

    TIME_STRING=$(date -u +"%Y-%m-%dT%H:%M:%S.%6NZ")
    echo "Current time:"
    echo "$TIME_STRING"

    # echo Starting assignments:
    for assignment_id in $ASSIGNMENT_IDS; do
        echo "Starting assignment $assignment_id"
        curl "https://api.wanikani.com/v2/assignments/$assignment_id/start" \
            -X "PUT" \
            -H "Wanikani-Revision: 20170710" \
            -H "Content-Type: application/json; charset=utf-8" \
            -H "Authorization: Bearer $WANIKANI_TOKEN" \
            -d "{\"assignment\": {\"started_at\": \"$TIME_STRING\" }}"
        echo
        sleep 1
    done
  '';
  };
in

 {
  options.services.wanikani-bypass-lessons.enable = lib.mkEnableOption {
    description = "Enable WaniKani Bypass Lessons";
    default = false;
  };

  config = lib.mkIf config.services.wanikani-bypass-lessons.enable {
    systemd.services.wanikani-bypass-lessons = {
      description = "WaniKani Bypass Lessons";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe waniKani-bypass-lessons}";
        Restart = "always";
        RestartSec = 60;
      };
    };
  };
 }
