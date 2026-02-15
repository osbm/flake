{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.ollama.enable {
      osbmModules.nixSettings.allowedUnfreePackages = [
        "open-webui"
      ];

      services.ollama = {
        enable = true;
        package = pkgs.ollama-cuda;
        # loadModels = [
        #   "deepseek-r1:7b"
        #   "deepseek-r1:14b"
        # ];
      };

      services.open-webui = {
        enable = false; # TODO gives error fix later
        port = 7070;
        host = "0.0.0.0";
        openFirewall = true;
        environment = {
          SCARF_NO_ANALYTICS = "True";
          DO_NOT_TRACK = "True";
          ANONYMIZED_TELEMETRY = "False";
          WEBUI_AUTH = "False";
          ENABLE_LOGIN_FORM = "False";
        };
      };
    })
  ];
}
