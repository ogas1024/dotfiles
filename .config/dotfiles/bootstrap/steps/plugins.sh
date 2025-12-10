#!/usr/bin/env bash
# 安装 TPM、触发 zinit、同步 Neovim 插件
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

echo "[plugins] TPM & Zinit & Neovim"
install_plugins
