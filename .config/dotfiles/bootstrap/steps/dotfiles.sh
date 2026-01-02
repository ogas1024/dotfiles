#!/usr/bin/env bash
# 步骤：部署 Dotfiles 配置
# 重要性：CRITICAL（关键步骤，必须成功）
# 依赖：packages

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# ============================================================================
# 步骤描述
# ============================================================================
step_dotfiles_describe() {
  cat << 'EOF'
⚙️  Dotfiles 配置部署

将要执行的操作：
  1. 检查裸仓库是否存在（~/.dotfiles）
  2. 如果不存在，从远程克隆裸仓库
  3. Checkout 配置文件到 $HOME
  4. 设置 showUntrackedFiles=no 避免干扰

配置内容：
  • Zsh 配置（~/.config/zsh/）
  • Tmux 配置（~/.config/tmux/）
  • Neovim 配置（~/.config/nvim/）
  • Starship 配置
  • Yazi 配置
  • 其他工具配置

风险提示：
  ⚠ 如果 $HOME 中存在同名文件，会被覆盖
  ⚠ 建议提前备份重要的配置文件
  ℹ Git 会忽略未跟踪的文件，不会影响其他文件

为什么需要这一步：
  这是整个配置系统的核心，将预设的配置文件部署到系统中
  后续的 shell、plugins 等步骤都依赖这些配置文件
EOF
}

# ============================================================================
# 检查：判断是否需要执行
# ============================================================================
step_dotfiles_check() {
  # 检查关键配置文件是否存在
  local key_files=(
    "$HOME/.config/zsh/.zshrc"
    "$HOME/.config/tmux/tmux.conf"
    "$HOME/.config/nvim/init.lua"
  )

  local missing=()
  for file in "${key_files[@]}"; do
    if [ ! -f "$file" ]; then
      missing+=("$file")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    info "以下配置文件缺失："
    printf '       - %s\n' "${missing[@]}"
    return 1  # 需要执行
  fi

  # 检查是否是从 dotfiles 仓库来的
  if [ -d "$DOTDIR" ]; then
    info "Dotfiles 已部署"
    return 0  # 无需执行
  fi

  return 1  # 需要执行
}

# ============================================================================
# 执行：部署 dotfiles
# ============================================================================
step_dotfiles_run() {
  local REPO="${REPO:-git@github.com:ogas1024/dotfiles.git}"
  local DOTDIR="${DOTDIR:-$HOME/.dotfiles}"

  if [ -d "$DOTDIR" ]; then
    substep "检测到已存在的裸仓库：$DOTDIR"

    # 更新仓库
    substep "拉取最新更新"
    if git --git-dir="$DOTDIR" --work-tree="$HOME" fetch 2>&1 | sed 's/^/       /'; then
      success "仓库已更新"
    else
      warn "拉取更新失败，将使用现有版本"
    fi

    substep "配置 dotfiles 别名"
    git --git-dir="$DOTDIR" --work-tree="$HOME" config --local status.showUntrackedFiles no

    substep "Checkout 配置文件到 $HOME"
    info "注意：同名文件将被覆盖"

    if git --git-dir="$DOTDIR" --work-tree="$HOME" checkout -f 2>&1 | sed 's/^/       /'; then
      success "配置文件已更新"
    else
      error "Checkout 失败"
      return 1
    fi
  else
    # 首次克隆
    substep "克隆裸仓库：$REPO"
    info "目标位置：$DOTDIR"

    if git clone --bare "$REPO" "$DOTDIR" 2>&1 | sed 's/^/       /'; then
      success "仓库克隆成功"
    else
      error "克隆失败，请检查仓库地址和网络连接"
      return 1
    fi

    substep "配置 dotfiles 别名"
    git --git-dir="$DOTDIR" --work-tree="$HOME" config --local status.showUntrackedFiles no

    substep "Checkout 配置文件到 $HOME"
    if git --git-dir="$DOTDIR" --work-tree="$HOME" checkout -f 2>&1 | sed 's/^/       /'; then
      success "配置文件已部署"
    else
      error "Checkout 失败"
      return 1
    fi
  fi

  return 0
}

# ============================================================================
# 验证：检查是否成功
# ============================================================================
step_dotfiles_verify() {
  local key_files=(
    "$HOME/.config/zsh/.zshrc"
    "$HOME/.config/tmux/tmux.conf"
    "$HOME/.config/nvim/init.lua"
  )

  local missing=()
  for file in "${key_files[@]}"; do
    if [ ! -f "$file" ]; then
      missing+=("$file")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    error "验证失败：以下配置文件不存在："
    printf '  - %s\n' "${missing[@]}"
    return 1
  fi

  # 检查裸仓库
  if [ ! -d "$DOTDIR" ]; then
    error "验证失败：裸仓库不存在"
    return 1
  fi

  success "验证通过：Dotfiles 已成功部署"
  return 0
}

# ============================================================================
# 后续提示
# ============================================================================
step_dotfiles_after() {
  info "后续步骤："
  echo "  ✓ Dotfiles 配置已部署"
  echo "  → 接下来将设置密钥文件和 Shell"
  echo ""
  info "提示："
  echo "  • 使用 'dotfiles' 命令管理配置（需要重新登录后生效）"
  echo "  • 示例：dotfiles status, dotfiles add <file>, dotfiles commit"
}

# ============================================================================
# 主入口
# ============================================================================
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  source "$SCRIPT_DIR/lib/steps.sh"
  step_execute "dotfiles"
fi
