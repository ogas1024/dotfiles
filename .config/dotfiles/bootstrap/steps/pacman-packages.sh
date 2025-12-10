#!/usr/bin/env bash
# Arch/CachyOS：安装镜像优化、系统升级、常用软件（含 paru）
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

RUN_MIRRORS="${RUN_MIRRORS:-1}"
REFLECTOR_COUNTRY="${REFLECTOR_COUNTRY:-China}"

pacman_install() { sudo pacman -Sy --noconfirm --needed "$@"; }

echo "[packages][pacman] 可选：优化镜像源"
if [ "$RUN_MIRRORS" = "1" ]; then
  if need cachyos-rate-mirrors; then sudo cachyos-rate-mirrors || true; fi
  if need reflector; then sudo reflector --country "$REFLECTOR_COUNTRY" --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist || true; fi
fi

echo "[packages][pacman] 系统升级"
sudo pacman -Syu --noconfirm

echo "[packages][pacman] 安装常用软件"
pacman_install \
  base-devel \
  git curl wget aria2 \
  zsh starship atuin zoxide fzf \
  eza bat bat-extras fd ripgrep duf tldr \
  fastfetch btop \
  tmux neovim tree ncdu cloc \
  7zip unzip zip unar \
  ufw rsync rclone \
  github-cli flatpak fuse2 \
  lua jq mise \
  yazi ffmpeg imagemagick poppler resvg file \
  paru
