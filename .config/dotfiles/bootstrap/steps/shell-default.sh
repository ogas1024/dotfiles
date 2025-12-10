#!/usr/bin/env bash
# 设置 zsh 为默认 shell
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

ensure_shell
