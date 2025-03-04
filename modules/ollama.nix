{
  lib,
  config,
  ...
}: {
  options = {
    myModules = {
      enableOllama = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Ollama services.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.myModules.enableOllama {
      services.ollama = {
        enable = true;
        acceleration = "cuda";
        loadModels = ["deepseek-r1:7b" "deepseek-r1:14b"];
      };

      services.open-webui = {
        enable = true;
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
