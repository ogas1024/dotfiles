#!/usr/bin/env bash
# 步骤：安装字体
# 重要性：OPTIONAL（可选步骤）
# 依赖：packages

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# ============================================================================
# 步骤描述
# ============================================================================
step_fonts_describe() {
  cat << 'EOF'
🔤 字体安装

将要执行的操作：
  1. 检测系统发行版
  2. 安装常用编程字体
  3. 更新字体缓存

字体列表：
  • Nerd Fonts（包含图标的编程字体）
  • Noto Fonts（Google 开源字体，支持多语言）
  • 文泉驿字体（中文字体）
  • 思源字体（Adobe 开源中文字体）

风险提示：
  ℹ 某些字体可能需要从 AUR 安装（Arch）
  ℹ 字体安装较大，可能需要 100-500MB 空间
  ⚠ 如果某些字体不可用，会自动跳过

为什么需要这一步：
  • 终端和编辑器需要支持图标和特殊字符的字体
  • 中文显示需要合适的字体
  • 更好的视觉体验
EOF
}

# ============================================================================
# 检查：判断是否需要执行
# ============================================================================
step_fonts_check() {
  # 检查一些关键字体是否已安装
  local font_dirs=(
    "/usr/share/fonts"
    "$HOME/.local/share/fonts"
  )

  local found_fonts=0
  for dir in "${font_dirs[@]}"; do
    if [ -d "$dir" ]; then
      # 检查是否有 Nerd Fonts 或 Noto 字体
      if find "$dir" -name "*Nerd*" -o -name "*Noto*" 2>/dev/null | grep -q .; then
        found_fonts=1
        break
      fi
    fi
  done

  if [ $found_fonts -eq 1 ]; then
    info "检测到已安装的字体"
    return 0  # 可以跳过，但用户可能想更新
  fi

  return 1  # 需要执行
}

# ============================================================================
# 执行：安装字体
# ============================================================================
step_fonts_run() {
  if [ "$DISTRO" = "arch" ]; then
    step_fonts_run_arch
  elif [ "$DISTRO" = "debian" ]; then
    step_fonts_run_debian
  else
    error "不支持的发行版"
    return 1
  fi
}

# Arch/CachyOS 安装
step_fonts_run_arch() {
  substep "安装官方仓库字体"

  local fonts=(
    ttf-nerd-fonts-symbols
    ttf-nerd-fonts-symbols-mono
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    wqy-zenhei
    wqy-microhei
  )

  local available=()
  for font in "${fonts[@]}"; do
    if pacman -Si "$font" >/dev/null 2>&1; then
      available+=("$font")
    else
      info "跳过不可用的字体：$font"
    fi
  done

  if [ ${#available[@]} -gt 0 ]; then
    if sudo pacman -S --noconfirm --needed "${available[@]}" 2>&1 | sed 's/^/       /'; then
      success "官方仓库字体安装完成"
    else
      warn "部分字体安装失败"
    fi
  fi

  # 安装 AUR 字体（如果 paru 可用）
  if command -v paru >/dev/null 2>&1; then
    substep "安装 AUR 字体（可选）"
    info "从 AUR 安装额外字体..."

    local aur_fonts=(
      ttf-meslo-nerd
      ttf-jetbrains-mono-nerd
    )

    for font in "${aur_fonts[@]}"; do
      info "安装 $font..."
      if paru -S --noconfirm --needed "$font" 2>&1 | sed 's/^/       /'; then
        success "$font 安装完成"
      else
        warn "$font 安装失败，跳过"
      fi
    done
  else
    info "paru 不可用，跳过 AUR 字体"
  fi

  # 更新字体缓存
  substep "更新字体缓存"
  if fc-cache -fv 2>&1 | sed 's/^/       /'; then
    success "字体缓存已更新"
  else
    warn "字体缓存更新失败"
  fi

  return 0
}

# Debian/Ubuntu 安装
step_fonts_run_debian() {
  substep "安装字体"

  local fonts=(
    fonts-noto
    fonts-noto-cjk
    fonts-noto-color-emoji
    fonts-wqy-zenhei
    fonts-wqy-microhei
    fonts-liberation
    fonts-dejavu
  )

  if sudo apt-get install -y "${fonts[@]}" 2>&1 | sed 's/^/       /'; then
    success "字体安装完成"
  else
    warn "部分字体安装失败"
  fi

  # 更新字体缓存
  substep "更新字体缓存"
  if fc-cache -fv 2>&1 | sed 's/^/       /'; then
    success "字体缓存已更新"
  else
    warn "字体缓存更新失败"
  fi

  # 提示手动安装 Nerd Fonts
  info "提示：Nerd Fonts 需要手动安装"
  echo "  访问：https://www.nerdfonts.com/font-downloads"
  echo "  或运行：curl -fLo \"$HOME/.local/share/fonts/MesloLGS NF Regular.ttf\" \\"
  echo "    https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/S/Regular/MesloLGSNerdFont-Regular.ttf"

  return 0
}

# ============================================================================
# 验证：检查是否成功
# ============================================================================
step_fonts_verify() {
  # 检查字体缓存是否存在
  if ! command -v fc-list >/dev/null 2>&1; then
    warn "fc-list 命令不可用，跳过验证"
    return 0
  fi

  # 检查是否有字体
  local font_count=$(fc-list | wc -l)
  if [ "$font_count" -lt 10 ]; then
    error "验证失败：检测到的字体数量过少（$font_count）"
    return 1
  fi

  success "验证通过：检测到 $font_count 个字体"
  return 0
}

# ============================================================================
# 后续提示
# ============================================================================
step_fonts_after() {
  info "后续操作："
  echo "  ✓ 字体已安装"
  echo ""
  info "查看已安装字体："
  echo "  ${BRIGHT_CYAN}fc-list | grep -i nerd${RESET}  # 查看 Nerd Fonts"
  echo "  ${BRIGHT_CYAN}fc-list | grep -i noto${RESET}  # 查看 Noto 字体"
  echo ""
  info "终端配置："
  echo "  • 在终端设置中选择 Nerd Font 字体以显示图标"
  echo "  • 推荐：MesloLGS NF, JetBrains Mono Nerd Font"
}

# ============================================================================
# 主入口
# ============================================================================
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  source "$SCRIPT_DIR/lib/steps.sh"
  step_execute "fonts"
fi
