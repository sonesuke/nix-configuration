{ pkgs, ... }:
{
  home.packages = with pkgs; [
    docker-client
    docker-buildx
    docker-compose
    # General-purpose Linux VMs: `limactl start template:ubuntu` etc.
    lima
  ];

  # Docker CLI plugins (`docker buildx`, `docker compose`).
  # Only the plugin links are managed, so ~/.docker/config.json stays writable
  # for `docker login` and for Colima switching the docker context.
  home.file.".docker/cli-plugins/docker-buildx".source =
    "${pkgs.docker-buildx}/libexec/docker/cli-plugins/docker-buildx";
  home.file.".docker/cli-plugins/docker-compose".source =
    "${pkgs.docker-compose}/libexec/docker/cli-plugins/docker-compose";

  # Docker engine: Colima (a Lima VM running dockerd).
  # Start/stop manually with `colima start` / `colima stop`.
  services.colima = {
    enable = true;
    profiles.default = {
      isActive = true; # make the `colima` docker context the current one
      isService = false; # set to true to start the VM at login
      # Keep colima.yaml writable: a manual `colima start` may rewrite it.
      # Values below still win on every activation.
      mutableSettings = true;
      settings = {
        cpu = 4;
        memory = 6;
        disk = 60;
        arch = "host";
        runtime = "docker";
        vmType = "vz";
        mountType = "virtiofs";
        rosetta = true; # run linux/amd64 images fast on Apple Silicon
        autoActivate = true;
      };
    };
  };
}
