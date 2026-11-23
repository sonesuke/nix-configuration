# Keep build artifacts (node_modules, .build, .venv, ...) out of iCloud Drive.
#
# Same mechanism as https://github.com/amosavian/exclude-icloud-artifacts,
# as a shell script: tagging a folder with the File Provider ignore xattr
# makes iCloud Drive stop syncing it (it stays on this Mac; an already
# uploaded copy is removed from iCloud). A LaunchAgent sweeps once at login,
# then fswatch (FSEvents) tags matching folders as they are created.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  roots = [ "${config.home.homeDirectory}/Library/Mobile Documents/com~apple~CloudDocs" ];

  # Folder names that are always excluded.
  names = [
    # Swift / Xcode
    ".build"
    "DerivedData"
    "Pods"
    # Node
    "node_modules"
    ".next"
    ".nuxt"
    ".turbo"
    ".parcel-cache"
    # Python
    ".venv"
    "__pycache__"
    ".pytest_cache"
    ".mypy_cache"
    ".ruff_cache"
    ".tox"
    # Java / Kotlin
    ".gradle"
    # Lean (Lake build output and fetched packages)
    ".lake"
    # Misc
    ".direnv"
    ".cache"
  ];
  # `target` only next to Cargo.toml (handled in the script).
  allNames = names ++ [ "target" ];

  icloud-exclude = pkgs.writeShellApplication {
    name = "icloud-exclude";
    runtimeInputs = with pkgs; [
      fswatch
      findutils
    ];
    text = ''
      attr='com.apple.fileprovider.ignore#P'
      roots=(${lib.escapeShellArgs roots})

      tag() {
        local dir=$1
        [ -d "$dir" ] && [ ! -L "$dir" ] || return 0
        if [ "''${dir##*/}" = target ] && [ ! -e "''${dir%/*}/Cargo.toml" ]; then
          return 0
        fi
        /usr/bin/xattr -p "$attr" "$dir" >/dev/null 2>&1 && return 0
        if /usr/bin/xattr -w "$attr" 1 "$dir"; then echo "$(date '+%F %T') excluded $dir"; fi
      }

      sweep() {
        { find "$@" -type d \( ${
          lib.concatMapStringsSep " -o " (n: "-name ${lib.escapeShellArg n}") allNames
        } \) -prune -print0 2>/dev/null || true; } |
          while IFS= read -r -d "" dir; do tag "$dir"; done
      }

      if [ "''${1:-}" = --sweep ]; then
        sweep "''${@:2}"
        exit 0
      fi

      echo "$(date '+%F %T') sweeping ''${roots[*]}"
      sweep "''${roots[@]}"
      echo "$(date '+%F %T') watching"
      # Only events whose path ends in an artifact folder name get through.
      fswatch -0 -r --latency 10 -E \
        --event Created --event Renamed --event MovedTo \
        -e '.*' -i ${lib.escapeShellArg "/(${lib.concatMapStringsSep "|" lib.escapeRegex allNames})$"} \
        "''${roots[@]}" |
        while IFS= read -r -d "" dir; do tag "$dir"; done
    '';
  };
in
{
  # `icloud-exclude --sweep <dir>...` tags a tree by hand.
  home.packages = [ icloud-exclude ];

  launchd.agents.icloud-exclude = {
    enable = true;
    config = {
      ProgramArguments = [ (lib.getExe icloud-exclude) ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 300;
      ProcessType = "Background";
      LowPriorityIO = true;
      Nice = 10;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/icloud-exclude.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/icloud-exclude.log";
    };
  };
}
