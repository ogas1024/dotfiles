#!/usr/bin/env bash
# 创建忽略的密钥文件（仅本机）
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

echo "[secrets] 创建密钥文件（已忽略）"
ensure_secrets_file
