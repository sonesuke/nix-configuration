# nix-configuration

Declarative setup for my Mac (`Air`, Apple Silicon) using
[nix-darwin](https://github.com/nix-darwin/nix-darwin) and
[home-manager](https://github.com/nix-community/home-manager), on top of
[Determinate Nix](https://determinate.systems/).

## What lives where

| Layer | Managed by | Contents |
| --- | --- | --- |
| CLI tools, shell, dotfiles | home-manager (`home.nix`, `docker.nix`, `vim.nix`) | git, gh, ripgrep, watch, awscli2, granted, Claude Code, Codex, Pi, docker CLI, colima, lima, vim, zsh |
| System settings | nix-darwin (`darwin.nix`) | `/etc/zshrc` etc., Homebrew bundle |
| GUI apps | Homebrew casks, declared in `darwin.nix` | espanso, zed |
| Nix itself | Determinate Nix (`nix.enable = false`) | nix daemon, `/etc/nix/nix.conf` |
| Not managed by Nix | — | Claude Code / Codex / Pi settings (`~/.claude`, `~/.codex`, `~/.pi`), fonts, App Store apps |
| Secrets / credentials | — (never put them in this repo) | `~/.zshrc.local`, `~/.aws`, `~/.gnupg`, `~/.config/gcloud`, `~/.config/gh/hosts.yml` |

## Layout

```
flake.nix    # inputs (nixpkgs-unstable, nix-darwin, home-manager) and the "Air" host
darwin.nix   # system-level config + Homebrew casks
home.nix     # user packages, zsh, git, gh, granted
docker.nix   # docker CLI + plugins, Colima (docker engine), Lima (generic VMs)
vim.nix      # vim with a small set of plugins; set as $EDITOR
statix.toml  # linter config
scripts/     # fmt.sh (format) and lint.sh (format check + linters), also used by CI
.envrc       # `use flake` -> direnv loads the dev shell
.github/workflows/ci.yml  # CI: format check, lint, build on macOS (arm64)
```

## Bootstrap on a fresh Mac

1. Install Determinate Nix:

   ```sh
   curl -fsSL https://install.determinate.systems/nix | sh -s -- install
   ```

2. Install Homebrew (only used as a backend for casks):

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

3. Clone this repo to `~/Desktop/nix-configuration`.

4. Move away the `/etc` files nix-darwin wants to own, then do the first switch:

   ```sh
   sudo mv /etc/zshrc   /etc/zshrc.before-nix-darwin
   sudo mv /etc/zprofile /etc/zprofile.before-nix-darwin
   sudo mv /etc/zshenv  /etc/zshenv.before-nix-darwin
   sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/Desktop/nix-configuration#Air
   ```

   Existing dotfiles that home-manager takes over are renamed with the
   `.before-home-manager` suffix instead of failing.

5. Open a new terminal.

## Daily use

Apply changes after editing any `.nix` file:

```sh
sudo darwin-rebuild switch --flake ~/Desktop/nix-configuration
```

The `#Air` suffix can be omitted because it matches the machine's
`LocalHostName`.

Update all inputs (nixpkgs, nix-darwin, home-manager), then switch:

```sh
nix flake update --flake ~/Desktop/nix-configuration
sudo darwin-rebuild switch --flake ~/Desktop/nix-configuration
```

Roll back to the previous generation:

```sh
sudo darwin-rebuild --rollback
```

Try a package without installing it:

```sh
nix shell nixpkgs#coreutils
```

> Flakes only see files tracked by git. After adding a new `.nix` file,
> run `git add` before switching.

### Adding things

- **CLI tool** — add it to `home.packages` in `home.nix`.
- **GUI app** — add the cask name to `homebrew.casks` in `darwin.nix`.

> **Warning:** `homebrew.onActivation.cleanup = "zap"` is enabled. Any
> Homebrew formula or cask *not* declared in `darwin.nix` is uninstalled,
> including its app data, on every switch. Do not use `brew install`
> directly. `brew` is intentionally not on `PATH`; use
> `/opt/homebrew/bin/brew` if you really need it.

## Editing this repo

A dev shell with `nixfmt`, `statix`, `deadnix`, `actionlint` and `nil`
(language server) is
defined in `flake.nix`. With direnv + nix-direnv (configured in `home.nix`), it
is loaded automatically when you `cd` into the repo; run `direnv allow` once.
Without direnv, use `nix develop`.

```sh
scripts/fmt.sh     # format all .nix files (nix fmt / nixfmt-tree)
scripts/lint.sh    # nixfmt --check, statix, deadnix, actionlint
```

`repeated_keys` is disabled in `statix.toml`.

CI (`.github/workflows/ci.yml`) runs `scripts/lint.sh`, then
builds `darwinConfigurations.Air.system` on an Apple Silicon macOS runner
(build only, nothing is activated).

Any other repo can use the same mechanism by adding an `.envrc` containing
`use flake`.

## Shell

- zsh is configured by home-manager (`programs.zsh`).
- `~/.local/bin` is on `PATH` (for tools installed by their own install
  scripts).
- `~/.zshrc.local` is sourced if it exists. Put API keys and other
  machine-local settings there; it is not managed by Nix and must never be
  committed.

## Git / GitHub

- `programs.git` writes `~/.config/git/config` (user, `core.autocrlf`,
  git-lfs, global ignores).
- `programs.gh` registers `gh auth git-credential` as the credential helper
  for github.com. Authentication itself lives in `~/.config/gh/hosts.yml`
  (run `gh auth login` on a new machine).

## AWS

- `awscli2` and [Granted](https://www.granted.dev/) are installed.
- Switch profiles with `assume <profile>` (or `assume` to pick from a list);
  `assume -c <profile>` opens the AWS console.
- Profiles and credentials stay in `~/.aws/config` and `~/.aws/credentials`
  and are not managed by Nix. Granted creates `~/.granted/config` on first
  run.

## Docker and Linux VMs

Docker runs inside a [Colima](https://github.com/abiosoft/colima) VM
(vz, virtiofs, Rosetta enabled; 4 CPUs / 6 GiB / 60 GiB). It does **not**
start at login.

```sh
colima start                 # once after each boot
docker run --rm hello-world
colima stop                  # free the VM's memory when done
```

- CPU is a limit, not a reservation. Memory grows with use and is only
  released by `colima stop`. The disk image grows on demand up to 60 GiB and
  does not shrink by itself (`colima delete` + `colima start` recreates it).
- `linux/amd64` images work through Rosetta.
- `~/.docker/config.json` is intentionally left writable (for
  `docker login` and docker contexts); only the `buildx` and `compose`
  plugin links are managed.
- To start the VM at login, set `isService = true` in `docker.nix`.

General-purpose Linux VMs use [Lima](https://lima-vm.io/) directly:

```sh
limactl start --name=ubuntu template:ubuntu
limactl shell ubuntu
limactl stop ubuntu
```

Colima keeps its VMs under `~/.colima`, Lima under `~/.lima`, so they do
not interfere.

## Vim

`vim.nix` installs Vim 9.2 with vim-sensible, vim-nix, vim-commentary and
vim-surround, and sets it as `$EDITOR` / `$VISUAL`. The vimrc is built into
the wrapped `vim` package, so there is no `~/.vimrc`; edit `vim.nix`
instead.

## Notes

- `nix.enable = false` because Determinate Nix manages the Nix installation.
  Nix settings go in `/etc/nix/nix.custom.conf`, not in this repo.
- Claude Code, Codex and Pi (`pi-coding-agent`) come from nixpkgs
  (`home.packages`). Their built-in auto-updaters / version checks are off; update them with `nix flake update` + switch
  (nixpkgs usually trails upstream by a day or two). `claude-code` is unfree
  and is allowed by name in `darwin.nix`.
- `NIX_SSL_CERT_FILE` is also exported to GUI apps via launchd
  (`launchd.user.envVariables` in `darwin.nix`), so agents launched from GUI
  apps such as T3 Code can verify TLS. Log out and back in (or restart the
  app) after the first switch.
- Their settings in `~/.claude`, `~/.codex` and `~/.pi` are not managed here because
  the tools write to them (e.g. project trust, permissions).
