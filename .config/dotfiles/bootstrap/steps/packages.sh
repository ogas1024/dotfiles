#!/usr/bin/env bash
# 步骤：安装系统软件包
# 重要性：CRITICAL（关键步骤，必须成功）
# 依赖：无

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# ============================================================================
# 步骤描述：向用户说明这一步做什么
# ============================================================================
step_packages_describe() {
  cat << 'EOF'
📦 系统软件包安装

将要执行的操作：
  1. 检测系统发行版（Arch/Debian）
  2. 优化软件源镜像（可选，仅 Arch）
  3. 升级系统现有软件包
  4. 安装开发工具和常用软件

安装的软件包括：
  • 开发工具: base-devel, git, curl, wget
  • Shell工具: zsh, starship, fzf, zoxide, atuin
  • 编辑器: neovim, tmux
  • 实用工具: eza, bat, fd, ripgrep, btop
  • 文件管理: yazi, 7zip, unzip
  • 其他: lua, jq, mise

风险提示：
  ⚠ 会升级系统中已安装的软件包，可能需要重启某些服务
  ⚠ 首次运行可能需要 5-15 分钟，取决于网络速度
  ℹ 如果某些软件包不可用，会自动跳过

为什么需要这一步：
  这些是后续配置的基础依赖，特别是 zsh, tmux, nvim 是核心工具
EOF
}

# ============================================================================
# 检查：判断是否需要执行
# ============================================================================
step_packages_check() {
  # 检查关键软件是否已安装
  local required=(git zsh tmux nvim)
  local missing=()

  for pkg in "${required[@]}"; do
    if ! command -v "$pkg" >/dev/null 2>&1; then
      missing+=("$pkg")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    info "缺少以下关键软件：${missing[*]}"
    return 1  # 需要执行
  fi

  info "关键软件已安装"
  return 0  # 无需执行
}

# ============================================================================
# 执行：实际安装软件包
# ============================================================================
step_packages_run() {
  # 检测发行版
  if command -v pacman >/dev/null 2>&1; then
    step_packages_run_arch
  elif command -v apt-get >/dev/null 2>&1; then
    step_packages_run_debian
  else
    error "不支持的发行版"
    return 1
  fi
}

# Arch/CachyOS 安装
step_packages_run_arch() {
  local RUN_MIRRORS="${RUN_MIRRORS:-1}"
  local REFLECTOR_COUNTRY="${REFLECTOR_COUNTRY:-China}"

  # 1. 优化镜像源
  if [ "$RUN_MIRRORS" = "1" ]; then
    substep "优化 Arch 镜像源"

    if command -v cachyos-rate-mirrors >/dev/null 2>&1; then
      info "使用 cachyos-rate-mirrors..."
      if sudo cachyos-rate-mirrors 2>&1 | sed 's/^/       /'; then
        success "cachyos-rate-mirrors 完成"
      else
        warn "cachyos-rate-mirrors 失败，将使用默认镜像"
      fi
    fi

    if command -v reflector >/dev/null 2>&1; then
      info "使用 reflector 更新镜像列表（国家：$REFLECTOR_COUNTRY）..."
      if sudo reflector --country "$REFLECTOR_COUNTRY" --age 12 \
        --protocol https --sort rate \
        --save /etc/pacman.d/mirrorlist 2>&1 | sed 's/^/       /'; then
        success "reflector 完成"
      else
        warn "reflector 失败，将使用默认镜像"
      fi
    fi
  else
    info "跳过镜像源优化"
  fi

  # 2. 系统升级
  substep "升级系统软件包"
  info "这可能需要几分钟..."

  if sudo pacman -Syu --noconfirm 2>&1 | sed 's/^/       /'; then
    success "系统升级完成"
  else
    error "系统升级失败"
    return 1
  fi

  # 3. 安装软件包
  substep "安装常用软件"
  info "安装列表中的软件包..."

  local packages=(
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

  # 过滤可用的软件包
  local available=()
  local unavailable=()

  for pkg in "${packages[@]}" unar; do
    if pacman -Si "$pkg" >/dev/null 2>&1; then
      available+=("$pkg")
    else
      unavailable+=("$pkg")
    fi
  done

  if [ ${#unavailable[@]} -gt 0 ]; then
    warn "以下软件包在仓库中不可用，将跳过："
    printf '       - %s\n' "${unavailable[@]}"
  fi

  # 安装
  if [ ${#available[@]} -gt 0 ]; then
    if sudo pacman -S --noconfirm --needed "${available[@]}" 2>&1 | sed 's/^/       /'; then
      success "软件包安装完成（${#available[@]}/${#packages[@]}）"
    else
      error "软件包安装失败"
      return 1
    fi
  fi

  # 4. 安装 paru（AUR 助手）
  substep "安装 paru (AUR 助手)"

  if command -v paru >/dev/null 2>&1; then
    info "paru 已存在"
  elif pacman -Si paru >/dev/null 2>&1; then
    info "从官方仓库安装 paru..."
    sudo pacman -S --noconfirm paru 2>&1 | sed 's/^/       /'
    success "paru 安装完成"
  else
    info "从 AUR 构建 paru-bin..."
    local tmp_dir=$(mktemp -d)
    trap 'rm -rf "$tmp_dir"' EXIT

    if git clone --depth=1 https://aur.archlinux.org/paru-bin.git "$tmp_dir/paru-bin" 2>&1 | sed 's/^/       /'; then
      pushd "$tmp_dir/paru-bin" >/dev/null
      if makepkg -si --noconfirm 2>&1 | sed 's/^/       /'; then
        popd >/dev/null
        success "paru 构建成功"
      else
        popd >/dev/null
        warn "paru 构建失败，可以稍后手动安装"
      fi
    else
      warn "克隆 paru-bin 失败"
    fi
  fi

  return 0
}

# Debian/Ubuntu 安装
step_packages_run_debian() {
  substep "更新软件包索引"
  if sudo apt-get update 2>&1 | sed 's/^/       /'; then
    success "软件包索引更新完成"
  else
    error "apt-get update 失败"
    return 1
  fi

  substep "升级系统软件包"
  info "这可能需要几分钟..."
  if sudo apt-get upgrade -y 2>&1 | sed 's/^/       /'; then
    success "系统升级完成"
  else
    error "系统升级失败"
    return 1
  fi

  substep "安装常用软件"
  local packages=(
    build-essential
    git curl wget aria2
    zsh fzf
    neovim tmux tree ncdu
    unzip zip p7zip-full
    ufw rsync rclone
    gh flatpak
    lua5.4 jq
  )

  info "安装软件包..."
  if sudo apt-get install -y "${packages[@]}" 2>&1 | sed 's/^/       /'; then
    success "软件包安装完成"
  else
    error "软件包安装失败"
    return 1
  fi

  # 安装一些通过其他方式的工具
  substep "安装额外工具"

  # starship
  if ! command -v starship >/dev/null 2>&1; then
    info "安装 starship..."
    if curl -sS https://starship.rs/install.sh | sh -s -- -y 2>&1 | sed 's/^/       /'; then
      success "starship 安装完成"
    else
      warn "starship 安装失败"
    fi
  fi

  return 0
}

# ============================================================================
# 验证：检查是否成功
# ============================================================================
step_packages_verify() {
  local required=(git zsh tmux nvim)
  local missing=()

  for cmd in "${required[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    error "验证失败：以下命令不可用："
    printf '  - %s\n' "${missing[@]}"
    return 1
  fi

  success "验证通过：所有关键软件已安装"
  return 0
}

# ============================================================================
# 后续提示：告诉用户接下来要做什么
# ============================================================================
step_packages_after() {
  info "后续步骤："
  echo "  ✓ 基础软件已安装"
  echo "  → 接下来将部署 dotfiles 配置"
}

# ============================================================================
# 主入口（如果直接运行此脚本）
# ============================================================================
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  # 加载步骤框架
  source "$SCRIPT_DIR/lib/steps.sh"

  # 执行步骤
  step_execute "packages"
fi
