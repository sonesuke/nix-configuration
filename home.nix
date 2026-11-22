{ pkgs, username, ... }:
{
  imports = [
    ./docker.nix
    ./icloud-exclude.nix
    ./vim.nix
  ];

  home.username = username;
  home.homeDirectory = "/Users/${username}";
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    ripgrep
    watch
    awscli2
    # Coding agents. Updated with `nix flake update`; their own auto-updaters
    # are disabled. Settings in ~/.claude, ~/.codex and ~/.pi are left
    # unmanaged because the tools write to them.
    claude-code
    codex
    pi-coding-agent
  ];

  # Tools installed outside Nix (e.g. by their own install scripts) live here.
  home.sessionPath = [ "$HOME/.local/bin" ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    initContent = ''
      # Secrets and machine-local settings (not managed by Nix).
      [ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
    '';
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        name = "sonesuke";
        email = "iamsonesuke@gmail.com";
      };
      core.autocrlf = "input";
    };
    ignores = [ "**/.claude/settings.local.json" ];
  };

  # Also registers `gh auth git-credential` as the GitHub credential helper,
  # which is required for expiring tokens to be refreshed during git operations.
  programs.gh = {
    enable = true;
    settings = {
      # Expiring OAuth tokens (gh >= 2.103, public preview): 8h access token,
      # refreshed automatically via a refresh token stored in the keychain.
      expiring_credentials = "enabled";
    };
  };

  # Per-directory environments: `use flake` in .envrc loads a flake's devShell on cd.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
    # Don't print the long "direnv: export +AR +CC ..." line on cd.
    config.global.hide_env_diff = true;
  };

  # AWS profile switching (`assume <profile>`), replaces awsp.
  programs.granted = {
    enable = true;
    enableZshIntegration = true;
  };
}
