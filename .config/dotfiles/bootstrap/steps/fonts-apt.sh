#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

echo "[fonts][apt] 安装常用字体（无 AUR，使用可用替代）"
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends \
  fonts-noto-cjk \
  fonts-noto-mono \
  fonts-wqy-zenhei fonts-wqy-microhei \
  fonts-dejavu \
  fonts-freefont-ttf

echo "[fonts][apt] JetBrains Mono 可用官方 .ttf 手动放入 ~/.local/share/fonts 后运行 fc-cache -fv"
echo "[fonts][apt] 如需其他商用字体，请自行准备文件并刷新缓存。"
