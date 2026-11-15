#!/usr/bin/env bash
# Format Nix files.
set -euo pipefail
cd "$(dirname "$0")/.."

nix fmt
