#!/usr/bin/env bash
# dotfiles 裸仓库 checkout（覆盖同名文件）
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

if [ -d "$DOTDIR" ]; then
  echo "[dotfiles] 已存在裸仓库：$DOTDIR，直接 checkout"
else
  echo "[dotfiles] 克隆裸仓库：$REPO -> $DOTDIR"
  dotfiles_checkout
  exit 0
fi

# 使用已存在的裸仓库进行 checkout
alias dotfiles="git --git-dir=$DOTDIR --work-tree=$HOME"
dotfiles config --local status.showUntrackedFiles no
dotfiles checkout -f
