#!/usr/bin/env bash
# 创建密钥文件模板
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

ensure_secrets_file
