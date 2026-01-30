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
                "ares"
                "artemis"
              ];
            };
          };
          devices = {
            wallfacer = {
              id = "LNPYIG4-LG2TCG5-IFCUQ7B-BVPGGR3-2C7TRI5-PN2DNYJ-EIXGINX-LUAUPQE";
            };
            pochita = {
              id = "5YCBKWJ-A33M6MH-XY6E6HO-QNDQE7N-PEVRL5I-6SQPQMX-563J5JN-C5FAPAU";
            };
            luoji = {
              id = "54O4Q42-GXACXO6-BK7TF4Q-NVBW6OF-ODPPVWO-WLW43CV-ZZEZXQD-JUAF7AY";
            };
            ymir = {
              id = "UOSJBAN-6NIGBJT-WBISUVW-BIGDPDM-OFZPMDQ-WDXUQPM-QB33OPH-3KG7MQV";
            };
            tartarus = {
              id = "TARTARUS-DEVICE-ID"; # Replace with actual ID from tartarus
            };
            ares = {
              id = "ARES-DEVICE-ID"; # Replace with actual ID from ares
            };
            artemis = {
              id = "ARTEMIS-DEVICE-ID"; # Replace with actual ID from artemis
            };
            atreus = {
              id = "ATREUS-DEVICE-ID"; # Replace with actual ID from atreus
            };
          };
        };
      };
    })
  ];
}
