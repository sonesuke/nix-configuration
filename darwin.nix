{ lib, username, ... }:
{
  # Determinate Nix manages the Nix installation and daemon itself.
  nix.enable = false;

  nixpkgs.hostPlatform = "aarch64-darwin";
  # Unfree packages are allowed one by one (home-manager shares these pkgs).
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "claude-code" ];

  system.primaryUser = username;
  users.users.${username}.home = "/Users/${username}";

  # Creates /etc/zshrc etc. so Nix paths are available in every shell.
  programs.zsh.enable = true;

  # GUI apps (e.g. T3 Code) don't get /etc/zshrc's env, so set it via launchd.
  launchd.user.envVariables = {
    # Without this, Nix-built tools they launch (claude-code, codex) can't find
    # the CA bundle and TLS fails with UNABLE_TO_GET_ISSUER_CERT_LOCALLY.
    NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
    # T3 Code: opt out of usage telemetry (PostHog) and self-updates.
    T3CODE_TELEMETRY_ENABLED = "false";
    T3CODE_DISABLE_AUTO_UPDATE = "1";
  };

  # GUI apps stay as Homebrew casks, but the list is declared here.
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      # Anything not declared here is uninstalled (with its app data).
      cleanup = "zap";
    };
    casks = [
      "espanso"
      "zed"
    ];
  };

  system.stateVersion = 6;
}
