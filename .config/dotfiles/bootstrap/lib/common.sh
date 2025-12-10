#!/usr/bin/env bash
# 公共变量与工具函数（避免重复与耦合）
set -euo pipefail

# ---- 默认环境变量（可被外部 export 覆盖） ----
REPO="${REPO:-https://github.com/ogas1024/dotfiles.git}"
DOTDIR="${DOTDIR:-$HOME/.dotfiles}"
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
SET_DEFAULT_SHELL="${SET_DEFAULT_SHELL:-1}"
INSTALL_NVIM_PLUGINS="${INSTALL_NVIM_PLUGINS:-1}"
MIHOMO_SETUP="${MIHOMO_SETUP:-1}"
MIHOMO_CONFIG="${MIHOMO_CONFIG:-$HOME/.config/mihomo/config.yaml}"
MIHOMO_DOWNLOAD_GEODATA="${MIHOMO_DOWNLOAD_GEODATA:-1}"
MIHOMO_ENABLE_SERVICE="${MIHOMO_ENABLE_SERVICE:-1}"
MIHOMO_USER="${MIHOMO_USER:-mihomo}"
MIHOMO_GEO_BASE="${MIHOMO_GEO_BASE:-https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release}"
MIHOMO_TGZ_URL="${MIHOMO_TGZ_URL:-https://github.com/MetaCubeX/mihomo/releases/latest/download/mihomo-linux-amd64.tar.gz}"
FCITX5_SETUP="${FCITX5_SETUP:-1}"

# ---- 工具函数 ----
need() { command -v "$1" >/dev/null 2>&1; }

# 裸仓库 checkout（覆盖同名文件）
dotfiles_checkout() {
  rm -rf "$DOTDIR"
  git clone --bare "$REPO" "$DOTDIR"
  alias dotfiles="git --git-dir=$DOTDIR --work-tree=$HOME"
  dotfiles config --local status.showUntrackedFiles no
  dotfiles checkout -f
}

# 准备密钥文件（忽略且 600）
ensure_secrets_file() {
  mkdir -p "$ZDOTDIR/env.d"
  touch "$ZDOTDIR/env.d/90-secrets.zsh"
  chmod 600 "$ZDOTDIR/env.d/90-secrets.zsh"
}

# 设置默认 shell
ensure_shell() {
  if [ "$SET_DEFAULT_SHELL" = "1" ] && [ -x /usr/bin/zsh ]; then
    chsh -s /usr/bin/zsh "$(whoami)" || true
  fi
}

# 安装插件集合：TPM + zinit + LazyVim
install_plugins() {
  if [ ! -d "$HOME/.local/share/tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm "$HOME/.local/share/tmux/plugins/tpm"
  fi
  ZDOTDIR="$ZDOTDIR" zsh -ic 'echo zinit ok'
  "$HOME/.local/share/tmux/plugins/tpm/bin/install_plugins" || true
  if [ "$INSTALL_NVIM_PLUGINS" = "1" ] && need nvim; then
    nvim --headless "+Lazy! sync" +qa || true
  fi
}

# 校验 mihomo 配置是否存在
require_mihomo_config() {
  if [ ! -f "$MIHOMO_CONFIG" ]; then
    echo "ERROR: 找不到 mihomo 配置 $MIHOMO_CONFIG ，请先创建后重试。" >&2
    exit 1
  fi
}
