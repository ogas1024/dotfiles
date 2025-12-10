#!/usr/bin/env bash
# Arch/CachyOS：mihomo 原生部署（要求已有配置文件）
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

if [ "$MIHOMO_SETUP" != "1" ]; then
  echo "[mihomo][pacman] 已跳过（MIHOMO_SETUP!=1）"
  exit 0
fi

echo "[mihomo][pacman] 校验配置"
require_mihomo_config

echo "[mihomo][pacman] 安装 mihomo-bin（paru）"
if ! need mihomo; then
  if need paru; then
    paru -S --needed --noconfirm mihomo-bin
  else
    echo "ERROR: paru 未安装，无法安装 mihomo-bin" >&2
    exit 1
  fi
fi

echo "[mihomo][pacman] 准备目录与配置"
sudo install -d -o "$MIHOMO_USER" -g "$MIHOMO_USER" -m 750 /etc/mihomo /etc/mihomo/providers /etc/mihomo/rules
sudo install -o "$MIHOMO_USER" -g "$MIHOMO_USER" -m 640 "$MIHOMO_CONFIG" /etc/mihomo/config.yaml

if [ "$MIHOMO_DOWNLOAD_GEODATA" = "1" ]; then
  for f in geoip.dat geosite.dat country.mmdb; do
    url="$MIHOMO_GEO_BASE/$f"
    echo "  - 下载 $f"
    sudo curl -fsSL "$url" -o "/etc/mihomo/$f"
    sudo chown "$MIHOMO_USER:$MIHOMO_USER" "/etc/mihomo/$f"
    sudo chmod 640 "/etc/mihomo/$f"
  done
fi

sudo chown "$MIHOMO_USER:$MIHOMO_USER" /etc/mihomo /etc/mihomo/providers /etc/mihomo/rules

if [ "$MIHOMO_ENABLE_SERVICE" = "1" ]; then
  sudo systemctl enable --now mihomo.service
else
  echo "[mihomo][pacman] 已部署但未启动，设 MIHOMO_ENABLE_SERVICE=1 可自动启动"
fi
