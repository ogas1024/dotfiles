#!/usr/bin/env bash
# Sync mihomo config from $HOME into /etc/mihomo with proper ownership/perms.
# Non-root config stays in ~/.config/mihomo/config.yaml (ignored by git); this script installs it for mihomo service.
#
# Env overrides:
#   SRC_CONFIG=~/.config/mihomo/config.yaml  # prefer this; falls back to config.example.yaml
#   TARGET=/etc/mihomo/config.yaml
#   MIHOMO_USER=mihomo
#   DOWNLOAD_GEODATA=1|0   # fetch geoip/geosite/mmdb
#   GEO_BASE=https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release
#   ENABLE_SERVICE=1|0     # enable & start mihomo.service
#
# Usage:
#   bash ~/.config/dotfiles/bootstrap/mihomo-sync.sh
#   DOWNLOAD_GEODATA=0 ENABLE_SERVICE=0 bash ~/.config/dotfiles/bootstrap/mihomo-sync.sh

set -euo pipefail

SRC_CONFIG="${SRC_CONFIG:-$HOME/.config/mihomo/config.yaml}"
EXAMPLE_CONFIG="${EXAMPLE_CONFIG:-$HOME/.config/mihomo/config.example.yaml}"
TARGET="${TARGET:-/etc/mihomo/config.yaml}"
MIHOMO_USER="${MIHOMO_USER:-mihomo}"
DOWNLOAD_GEODATA="${DOWNLOAD_GEODATA:-1}"
GEO_BASE="${GEO_BASE:-https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release}"
ENABLE_SERVICE="${ENABLE_SERVICE:-0}"

need() { command -v "$1" >/dev/null 2>&1; }

echo "[1/6] 选择配置源"
if [ -f "$SRC_CONFIG" ]; then
  CONFIG_SRC="$SRC_CONFIG"
elif [ -f "$EXAMPLE_CONFIG" ]; then
  CONFIG_SRC="$EXAMPLE_CONFIG"
  echo "WARN: 使用示例配置 $EXAMPLE_CONFIG，记得填写订阅 URL 后重跑。" >&2
else
  echo "ERROR: 找不到配置文件。请创建 $SRC_CONFIG 或 $EXAMPLE_CONFIG" >&2
  exit 1
fi

echo "[2/6] 准备 /etc/mihomo 目录与权限"
sudo install -d -o "$MIHOMO_USER" -g "$MIHOMO_USER" -m 750 /etc/mihomo
sudo install -d -o "$MIHOMO_USER" -g "$MIHOMO_USER" -m 750 /etc/mihomo/providers
sudo install -d -o "$MIHOMO_USER" -g "$MIHOMO_USER" -m 750 /etc/mihomo/rules

echo "[3/6] 安装配置文件 -> $TARGET"
sudo install -o "$MIHOMO_USER" -g "$MIHOMO_USER" -m 640 "$CONFIG_SRC" "$TARGET"

echo "[4/6] 可选：下载 geodata (geoip/geosite/country.mmdb)"
if [ "$DOWNLOAD_GEODATA" = "1" ]; then
  for f in geoip.dat geosite.dat country.mmdb; do
    url="$GEO_BASE/$f"
    echo "  - $f from $url"
    sudo curl -fsSL "$url" -o "/etc/mihomo/$f"
    sudo chown "$MIHOMO_USER:$MIHOMO_USER" "/etc/mihomo/$f"
    sudo chmod 640 "/etc/mihomo/$f"
  done
fi

echo "[5/6] 权限检查"
sudo chown "$MIHOMO_USER:$MIHOMO_USER" /etc/mihomo /etc/mihomo/providers /etc/mihomo/rules

echo "[6/6] 可选：启用/启动服务"
if [ "$ENABLE_SERVICE" = "1" ]; then
  if need systemctl; then
    sudo systemctl enable --now mihomo.service
  else
    echo "systemctl 不可用，跳过启用服务" >&2
  fi
else
  echo "未自动启动服务，设置 ENABLE_SERVICE=1 可启用。"
fi

echo "Done. 配置来源: $CONFIG_SRC -> $TARGET"
