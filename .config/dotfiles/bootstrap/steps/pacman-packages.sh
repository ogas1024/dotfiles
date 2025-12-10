#!/usr/bin/env bash
# Arch/CachyOS：安装镜像优化、系统升级、常用软件（含 paru）
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

RUN_MIRRORS="${RUN_MIRRORS:-1}"
REFLECTOR_COUNTRY="${REFLECTOR_COUNTRY:-China}"

pacman_install() {
  sudo pacman -Sy --noconfirm --needed "$@" 2>&1 | sed 's/^/       /'
}

# 优化镜像源
if [ "$RUN_MIRRORS" = "1" ]; then
  substep "优化 Arch 镜像源"

  if need cachyos-rate-mirrors; then
    info "使用 cachyos-rate-mirrors 优化镜像..."
    sudo cachyos-rate-mirrors 2>&1 | sed 's/^/       /' || warn "cachyos-rate-mirrors 失败"
  fi

  if need reflector; then
    info "使用 reflector 更新镜像列表（国家：$REFLECTOR_COUNTRY）..."
    sudo reflector --country "$REFLECTOR_COUNTRY" --age 12 --protocol https \
      --sort rate --save /etc/pacman.d/mirrorlist 2>&1 | sed 's/^/       /' || warn "reflector 失败"
  fi

  success "镜像源优化完成"
else
  info "跳过镜像源优化"
fi

# 系统升级
substep "升级系统软件包"
sudo pacman -Syu --noconfirm 2>&1 | sed 's/^/       /'
success "系统已升级"

# 安装常用软件
substep "安装开发工具和常用软件"
info "这可能需要几分钟..."

PKGS=(
  base-devel
  git curl wget aria2
  zsh starship atuin zoxide fzf
  eza bat bat-extras fd ripgrep duf tldr
  fastfetch btop
  tmux neovim tree ncdu cloc
  7zip unzip zip
  ufw rsync rclone
  github-cli flatpak fuse2
  lua jq mise
  yazi ffmpeg imagemagick poppler resvg file
)

# 按可用性过滤（例如 unar 在部分精简仓库缺失）
AVAILABLE_PKGS=()
for p in "${PKGS[@]}" unar; do
  if pacman -Si "$p" >/dev/null 2>&1; then
    AVAILABLE_PKGS+=("$p")
  else
    warn "跳过仓库未提供的软件：$p"
  fi
done

pacman_install "${AVAILABLE_PKGS[@]}"

# paru 如果仓库没有，则从 AUR 自举
if pacman -Si paru >/dev/null 2>&1; then
  pacman_install paru
else
  if command -v paru >/dev/null 2>&1; then
    info "paru 已存在，跳过安装"
  else
    substep "从 AUR 构建 paru-bin"
    TMP_P="$(mktemp -d)"
    trap 'rm -rf "$TMP_P"' EXIT
    git clone --depth=1 https://aur.archlinux.org/paru-bin.git "$TMP_P/paru-bin" 2>&1 | sed 's/^/       /'
    pushd "$TMP_P/paru-bin" >/dev/null
    makepkg -si --noconfirm 2>&1 | sed 's/^/       /' || {
      error "paru 构建失败，请手动安装"
    }
    popd >/dev/null
  fi
fi

success "软件包安装完成"
