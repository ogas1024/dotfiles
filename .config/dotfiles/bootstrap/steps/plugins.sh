#!/usr/bin/env bash
# 步骤：安装插件管理器
# 重要性：IMPORTANT（重要步骤）
# 依赖：dotfiles, shell

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# ============================================================================
# 步骤描述
# ============================================================================
step_plugins_describe() {
  cat << 'EOF'
🔌 插件管理器安装

将要执行的操作：
  1. 安装 TPM（Tmux Plugin Manager）
  2. 触发 Zinit 自动安装（Zsh 插件管理器）
  3. 安装 Tmux 插件
  4. 同步 Neovim 插件（LazyVim）

插件管理器说明：
  • TPM: Tmux 插件管理器
    位置：~/.local/share/tmux/plugins/tpm
    用途：管理 tmux 插件

  • Zinit: Zsh 插件管理器
    位置：~/.local/share/zinit/zinit.git
    用途：管理 zsh 插件（自动补全、语法高亮等）

  • LazyVim: Neovim 插件管理器
    用途：管理 Neovim 插件和配置

风险提示：
  ⚠ Neovim 插件同步可能需要 5-10 分钟
  ⚠ 需要网络连接从 GitHub 下载插件
  ℹ 如果网络较慢，可以跳过 Neovim 插件同步

为什么需要这一步：
  插件管理器是现代化 shell 和编辑器体验的基础
  没有这些插件，配置文件中的很多功能无法使用
EOF
}

# ============================================================================
# 检查：判断是否需要执行
# ============================================================================
step_plugins_check() {
  local TPM_DIR="$HOME/.local/share/tmux/plugins/tpm"
  local ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

  local needs_install=()

  if [ ! -d "$TPM_DIR" ]; then
    needs_install+=("TPM")
  fi

  if [ ! -d "$ZINIT_HOME" ]; then
    needs_install+=("Zinit")
  fi

  if [ ${#needs_install[@]} -gt 0 ]; then
    info "需要安装：${needs_install[*]}"
    return 1  # 需要执行
  fi

  info "所有插件管理器已安装"
  return 0  # 无需执行
}

# ============================================================================
# 执行：安装插件管理器
# ============================================================================
step_plugins_run() {
  local TPM_DIR="$HOME/.local/share/tmux/plugins/tpm"
  local ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
  local ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
  local INSTALL_NVIM_PLUGINS="${INSTALL_NVIM_PLUGINS:-1}"

  # ---- TPM（Tmux Plugin Manager）----
  if [ ! -d "$TPM_DIR" ]; then
    substep "安装 TPM (Tmux Plugin Manager)"
    info "克隆仓库到 $TPM_DIR"

    if git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM_DIR" 2>&1 | sed 's/^/       /'; then
      success "TPM 安装成功"
    else
      error "TPM 安装失败"
      return 1
    fi
  else
    info "TPM 已存在，跳过安装"
  fi

  # ---- Zinit（Zsh 插件管理器）----
  if [ ! -d "$ZINIT_HOME" ]; then
    substep "触发 Zinit 自动安装"
    info "首次启动 zsh 时 zinit 会自动安装"

    if ! command -v zsh >/dev/null 2>&1; then
      warn "zsh 未安装，跳过 zinit 初始化"
    else
      if ZDOTDIR="$ZDOTDIR" zsh -ic 'echo "Zinit initialized"' 2>&1 | sed 's/^/       /'; then
        success "Zinit 已初始化"
      else
        warn "Zinit 初始化失败，将在首次启动 zsh 时重试"
      fi
    fi
  else
    info "Zinit 已存在，跳过安装"
  fi

  # ---- 安装 Tmux 插件 ----
  if [ -x "$TPM_DIR/bin/install_plugins" ]; then
    substep "安装 Tmux 插件"
    info "通过 TPM 安装插件..."

    if "$TPM_DIR/bin/install_plugins" 2>&1 | sed 's/^/       /'; then
      success "Tmux 插件安装完成"
    else
      warn "部分 Tmux 插件安装失败"
      info "首次启动 tmux 时按 Ctrl+b I 可以重新安装"
    fi
  fi

  # ---- Neovim 插件同步 ----
  if [ "$INSTALL_NVIM_PLUGINS" = "1" ]; then
    if ! command -v nvim >/dev/null 2>&1; then
      warn "Neovim 未安装，跳过插件同步"
    else
      substep "同步 Neovim 插件（LazyVim）"
      info "这可能需要 5-10 分钟，请耐心等待..."
      warn "如果失败，可以稍后手动运行：nvim --headless '+Lazy! sync' +qa"

      # 创建超时机制（10 分钟）
      if timeout 600 nvim --headless "+Lazy! sync" +qa 2>&1 | sed 's/^/       /'; then
        success "Neovim 插件同步完成"
      else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
          warn "Neovim 插件同步超时（10分钟），可能网络较慢"
        else
          warn "Neovim 插件同步失败（退出码：$exit_code）"
        fi
        info "你可以稍后手动同步：打开 nvim，运行 :Lazy sync"
      fi
    fi
  else
    info "跳过 Neovim 插件同步（INSTALL_NVIM_PLUGINS=$INSTALL_NVIM_PLUGINS）"
  fi

  return 0
}

# ============================================================================
# 验证：检查是否成功
# ============================================================================
step_plugins_verify() {
  local TPM_DIR="$HOME/.local/share/tmux/plugins/tpm"
  local ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

  local missing=()

  if [ ! -d "$TPM_DIR" ]; then
    missing+=("TPM")
  fi

  if [ ! -d "$ZINIT_HOME" ]; then
    missing+=("Zinit")
  fi

  if [ ${#missing[@]} -gt 0 ]; then
    error "验证失败：以下插件管理器未安装："
    printf '  - %s\n' "${missing[@]}"
    return 1
  fi

  success "验证通过：所有插件管理器已安装"
  return 0
}

# ============================================================================
# 后续提示
# ============================================================================
step_plugins_after() {
  info "后续操作："
  echo "  ✓ 插件管理器已安装"
  echo ""
  info "Tmux 插件："
  echo "  • 首次启动 tmux 时按 ${BRIGHT_WHITE}Ctrl+b I${RESET} 可以重新安装插件"
  echo "  • 按 ${BRIGHT_WHITE}Ctrl+b U${RESET} 可以更新插件"
  echo ""
  info "Zsh 插件："
  echo "  • 重新启动 zsh 后自动加载插件"
  echo "  • 使用 ${BRIGHT_CYAN}zinit list${RESET} 查看已安装插件"
  echo ""
  info "Neovim 插件："
  echo "  • 打开 nvim，运行 ${BRIGHT_WHITE}:Lazy${RESET} 管理插件"
  echo "  • 运行 ${BRIGHT_WHITE}:Lazy sync${RESET} 同步插件"
}

# ============================================================================
# 主入口
# ============================================================================
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  source "$SCRIPT_DIR/lib/steps.sh"
  step_execute "plugins"
fi
