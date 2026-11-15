{ username, ... }:
{
  # Determinate Nix manages the Nix installation and daemon itself.
  nix.enable = false;

  nixpkgs.hostPlatform = "aarch64-darwin";

  system.primaryUser = username;
  users.users.${username}.home = "/Users/${username}";

  # Creates /etc/zshrc etc. so Nix paths are available in every shell.
  programs.zsh.enable = true;

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
