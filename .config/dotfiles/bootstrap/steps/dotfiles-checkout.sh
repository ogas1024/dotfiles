#!/usr/bin/env bash
# dotfiles 裸仓库 checkout（覆盖同名文件）
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

if [ -d "$DOTDIR" ]; then
  substep "检测到已存在的裸仓库：$DOTDIR"

  substep "配置 dotfiles 别名"
  git --git-dir="$DOTDIR" --work-tree="$HOME" config --local status.showUntrackedFiles no

  substep "Checkout 配置文件到 $HOME"
  git --git-dir="$DOTDIR" --work-tree="$HOME" checkout -f 2>&1 | sed 's/^/       /'

  success "Dotfiles 已更新"
else
  info "首次安装，克隆裸仓库"
  dotfiles_checkout
fi
