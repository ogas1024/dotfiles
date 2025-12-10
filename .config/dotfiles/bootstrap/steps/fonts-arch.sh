#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

echo "[fonts][arch] 使用 paru 安装常用字体（AUR 包含）"
if need paru; then
  paru -S --needed --noconfirm \
    ttf-foundertype-sc-fonts \
    noto-fonts-cjk \
    adobe-source-han-sans-cn-fonts \
    adobe-source-han-serif-cn-fonts \
    ttf-jetbrains-mono-git \
    wqy-zenhei wqy-microhei \
    ttf-arphic-uming ttf-arphic-ukai \
    ttf-wps-fonts ttf-ms-fonts \
    otf-apple-pingfang apple-fonts
else
  echo "ERROR: 需要 paru 安装上述 AUR 字体包" >&2
  exit 1
fi

echo "[fonts][arch] 如需额外字体，请手动下载后放入 ~/.local/share/fonts 并运行 fc-cache -fv"
echo "[fonts][arch] 完成。"
