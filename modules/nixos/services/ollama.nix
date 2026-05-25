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
        # CUDA libraries pulled in by ollama-cuda / vllm.
        # (shared CUDA libs like cuda_cudart, libcublas, etc. come from hardware/nvidia.nix)
        "libcusolver" # dense linear solvers
        "cuda_nvtx" # NVIDIA Tools Extension (profiling markers)
        "libcufile" # GPUDirect Storage
        "cuda_cupti" # CUDA Profiling Tools Interface
        "cuda_nvml_dev" # NVIDIA Management Library (headers)
        "libcusparse_lt" # sparse matrix multiply (Lt)
        "cuda_profiler_api" # CUDA profiler API
        "cuda_compat" # forward-compat driver shim
        "cuda_cuobjdump" # CUDA object file dumper
        "cuda_nvdisasm" # CUDA disassembler
        "libcutensor" # tensor primitives
        "libnvshmem" # NVIDIA OpenSHMEM (multi-GPU)
      ];

      environment.defaultPackages = with pkgs; [
        vllm
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
