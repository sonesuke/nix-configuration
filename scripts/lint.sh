#!/usr/bin/env bash
# Check formatting and run linters for Nix files and GitHub Actions workflows.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> nixfmt"
git ls-files -z '*.nix' | xargs -0 nixfmt --check

echo "==> statix"
statix check .

echo "==> deadnix"
deadnix --fail .

echo "==> actionlint"
actionlint
