#!/usr/bin/env bash
# Debian/Ubuntu：系统升级 + 常用软件
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

echo "[packages][apt] apt 更新与系统升级"
sudo apt-get update -y
sudo apt-get full-upgrade -y

echo "[packages][apt] 安装常用软件"
sudo apt-get install -y --no-install-recommends \
  build-essential \
  git curl wget aria2 \
  zsh starship zoxide fzf \
  eza bat fd-find ripgrep duf tldr \
  btop tmux neovim tree ncdu cloc \
  p7zip-full unzip zip unar \
  ufw rsync rclone \
  flatpak fuse3 \
  lua5.4 jq \
  ffmpeg imagemagick poppler-utils file
