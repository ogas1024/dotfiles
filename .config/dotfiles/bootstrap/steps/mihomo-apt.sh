#!/usr/bin/env bash
# Debian/Ubuntu：mihomo 原生部署（从上游 tarball 安装）
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

if [ "$MIHOMO_SETUP" != "1" ]; then
  echo "[mihomo][apt] 已跳过（MIHOMO_SETUP!=1）"
  exit 0
fi

echo "[mihomo][apt] 校验配置"
require_mihomo_config

if ! id "$MIHOMO_USER" >/dev/null 2>&1; then
  sudo useradd -r -s /usr/sbin/nologin -d /etc/mihomo "$MIHOMO_USER"
fi

tmpdir="$(mktemp -d)"
echo "[mihomo][apt] 下载 mihomo 二进制 $MIHOMO_TGZ_URL"
curl -fsSL "$MIHOMO_TGZ_URL" -o "$tmpdir/mihomo.tgz"
tar -xzf "$tmpdir/mihomo.tgz" -C "$tmpdir"
if [ ! -f "$tmpdir/mihomo" ]; then
  echo "ERROR: 未找到解压后的 mihomo 可执行文件" >&2
  exit 1
fi
sudo install -m755 "$tmpdir/mihomo" /usr/local/bin/mihomo

echo "[mihomo][apt] 准备目录与配置"
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

sudo tee /etc/systemd/system/mihomo.service >/dev/null <<'UNIT'
[Unit]
Description=mihomo service
After=network.target

[Service]
User=mihomo
Group=mihomo
ExecStart=/usr/local/bin/mihomo -d /etc/mihomo -f /etc/mihomo/config.yaml
Restart=on-failure
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
UNIT

sudo systemctl daemon-reload
if [ "$MIHOMO_ENABLE_SERVICE" = "1" ]; then
  sudo systemctl enable --now mihomo.service
else
  echo "[mihomo][apt] 已部署但未启动，设 MIHOMO_ENABLE_SERVICE=1 可自动启动"
fi
