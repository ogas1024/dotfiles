#!/usr/bin/env bash
# 设置默认 shell -> zsh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

echo "[shell] 设置默认 shell -> zsh"
ensure_shell
