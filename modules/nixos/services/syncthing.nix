{
  config,
  lib,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.syncthing.enable {
      services.syncthing = {
        enable = true;
        openDefaultPorts = true;
        # port is 8384
        settings = {
          folders = {
            "music" = {
              path = "/home/osbm/Music";
              devices = [
                "wallfacer"
                "pochita"
                "ymir"
                "tartarus"
                "luoji"
              ];
            };
          };
          devices = {
            wallfacer = {
              id = "WALLFACER-DEVICE-ID"; # Replace with actual ID from wallfacer
            };
            pochita = {
              id = "POCHITA-DEVICE-ID"; # Replace with actual ID from pochita
            };
            luoji = {
              id = "54O4Q42-GXACXO6-BK7TF4Q-NVBW6OF-ODPPVWO-WLW43CV-ZZEZXQD-JUAF7AY";
            };
            ymir = {
              id = "YMIR-DEVICE-ID"; # Replace with actual ID from ymir
            };
            tartarus = {
              id = "TARTARUS-DEVICE-ID"; # Replace with actual ID from tartarus
            };
          };
        };
      };
    })
  ];
}
