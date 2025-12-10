#!/usr/bin/env bash
# 公共变量与工具函数（避免重复与耦合）
set -euo pipefail

# 加载 UI 函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ui.sh"

# ============================================================================
# 默认环境变量（可被外部 export 覆盖）
# ============================================================================
REPO="${REPO:-git@github.com:ogas1024/dotfiles.git}"
DOTDIR="${DOTDIR:-$HOME/.dotfiles}"
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"

# 安装选项（1=是，0=否）
SET_DEFAULT_SHELL="${SET_DEFAULT_SHELL:-1}"
INSTALL_NVIM_PLUGINS="${INSTALL_NVIM_PLUGINS:-1}"
MIHOMO_SETUP="${MIHOMO_SETUP:-0}"              # 默认跳过 mihomo
FCITX5_SETUP="${FCITX5_SETUP:-0}"              # 默认跳过 fcitx5

# Mihomo 配置（仅在 MIHOMO_SETUP=1 时使用）
MIHOMO_CONFIG="${MIHOMO_CONFIG:-$HOME/.config/mihomo/config.yaml}"
MIHOMO_DOWNLOAD_GEODATA="${MIHOMO_DOWNLOAD_GEODATA:-1}"
MIHOMO_ENABLE_SERVICE="${MIHOMO_ENABLE_SERVICE:-0}"
MIHOMO_USER="${MIHOMO_USER:-mihomo}"
MIHOMO_GEO_BASE="${MIHOMO_GEO_BASE:-https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release}"
MIHOMO_TGZ_URL="${MIHOMO_TGZ_URL:-https://github.com/MetaCubeX/mihomo/releases/latest/download/mihomo-linux-amd64.tar.gz}"

# 镜像优化（仅 Arch/CachyOS）
RUN_MIRRORS="${RUN_MIRRORS:-1}"
REFLECTOR_COUNTRY="${REFLECTOR_COUNTRY:-China}"

# ============================================================================
# 工具函数
# ============================================================================

# 检查命令是否存在
need() {
  command -v "$1" >/dev/null 2>&1
}

# ============================================================================
# Dotfiles 仓库管理
# ============================================================================

# 裸仓库 checkout（覆盖同名文件）
dotfiles_checkout() {
  substep "克隆裸仓库：$REPO"
  rm -rf "$DOTDIR"
  git clone --bare "$REPO" "$DOTDIR" 2>&1 | sed 's/^/       /'

  substep "配置 dotfiles 别名"
  git --git-dir="$DOTDIR" --work-tree="$HOME" config --local status.showUntrackedFiles no

  substep "Checkout 配置文件到 $HOME"
  git --git-dir="$DOTDIR" --work-tree="$HOME" checkout -f 2>&1 | sed 's/^/       /'

  success "Dotfiles 已部署"
}

# ============================================================================
# 密钥和环境变量管理
# ============================================================================

# 准备密钥文件（忽略且 600）
ensure_secrets_file() {
  substep "创建密钥文件：$ZDOTDIR/env.d/90-secrets.zsh"
  mkdir -p "$ZDOTDIR/env.d"

  if [ ! -f "$ZDOTDIR/env.d/90-secrets.zsh" ]; then
    touch "$ZDOTDIR/env.d/90-secrets.zsh"
    chmod 600 "$ZDOTDIR/env.d/90-secrets.zsh"
    info "请编辑 $ZDOTDIR/env.d/90-secrets.zsh 添加你的密钥"
  else
    info "密钥文件已存在，跳过"
  fi
}

# ============================================================================
# Shell 配置
# ============================================================================

# 设置默认 shell
ensure_shell() {
  if [ "$SET_DEFAULT_SHELL" = "1" ]; then
    if [ -x /usr/bin/zsh ]; then
      substep "设置 zsh 为默认 shell"
      chsh -s /usr/bin/zsh "$(whoami)" 2>&1 | sed 's/^/       /' || warn "chsh 失败，可能需要重新登录"
      success "默认 shell 已设置为 zsh"
    else
      warn "zsh 未安装，跳过设置默认 shell"
    fi
  else
    info "跳过设置默认 shell"
  fi
}

# ============================================================================
# 插件管理
# ============================================================================

# 安装插件集合：TPM + zinit + LazyVim
install_plugins() {
  local TPM_DIR="$HOME/.local/share/tmux/plugins/tpm"
  local ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

  # TPM（Tmux Plugin Manager）
  if [ ! -d "$TPM_DIR" ]; then
    substep "安装 TPM (Tmux Plugin Manager)"
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM_DIR" 2>&1 | sed 's/^/       /'
    success "TPM 已安装"
  else
    info "TPM 已存在，跳过安装"
  fi

  # Zinit（首次启动 zsh 时自动安装）
  if [ ! -d "$ZINIT_HOME" ]; then
    substep "触发 Zinit 自动安装"
    ZDOTDIR="$ZDOTDIR" zsh -ic 'echo "Zinit initialized"' 2>&1 | sed 's/^/       /'
    success "Zinit 已安装"
  else
    info "Zinit 已存在，跳过安装"
  fi

  # 安装 Tmux 插件
  if [ -x "$TPM_DIR/bin/install_plugins" ]; then
    substep "安装 Tmux 插件"
    "$TPM_DIR/bin/install_plugins" 2>&1 | sed 's/^/       /' || warn "部分 Tmux 插件安装失败"
  fi

  # LazyVim 插件同步
  if [ "$INSTALL_NVIM_PLUGINS" = "1" ] && need nvim; then
    substep "同步 Neovim 插件（LazyVim）"
    info "这可能需要几分钟，请耐心等待..."
    nvim --headless "+Lazy! sync" +qa 2>&1 | sed 's/^/       /' || warn "Neovim 插件同步失败"
    success "Neovim 插件已同步"
  else
    info "跳过 Neovim 插件同步"
  fi
}

# ============================================================================
# Mihomo 配置校验
# ============================================================================

# 校验 mihomo 配置是否存在
require_mihomo_config() {
  if [ ! -f "$MIHOMO_CONFIG" ]; then
    error "找不到 mihomo 配置：$MIHOMO_CONFIG"
    warn "请先创建配置文件后重试"
    exit 1
  fi
}
