#!/usr/bin/env bash
# ============================================================================
# Dotfiles Bootstrap - 一键配置你的开发环境
# ============================================================================
#
# 用法：
#   交互式安装：
#     bash bootstrap.sh
#
#   非交互式安装（使用默认值）：
#     bash bootstrap.sh --yes
#
#   curl 直接运行：
#     bash <(curl -fsSL https://raw.githubusercontent.com/ogas1024/dotfiles/main/.config/dotfiles/bootstrap/bootstrap.sh)
#
# 环境变量配置（可选）：
#   REPO=          Git 仓库地址（默认：git@github.com:ogas1024/dotfiles.git）
#   DOTDIR=        裸仓库位置（默认：$HOME/.dotfiles）
#   NON_INTERACTIVE=1  非交互模式
#
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================================
# 自举逻辑：如果 steps/ 不存在，先克隆仓库
# ============================================================================
if [ "${BOOTSTRAP_STAGE:-0}" != "1" ] && [ ! -d "$SCRIPT_DIR/steps" ]; then
  echo "🔍 检测到首次运行，正在克隆 dotfiles 仓库..."

  REPO="${REPO:-git@github.com:ogas1024/dotfiles.git}"
  BRANCH="${BRANCH:-main}"
  DOTDIR="${DOTDIR:-$HOME/.dotfiles}"
  TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-bootstrap-XXXXXX")"

  # 安装 git（如果需要）
  if ! command -v git >/dev/null 2>&1; then
    echo "📦 正在安装 git..."
    if command -v pacman >/dev/null 2>&1; then
      sudo pacman -Sy --noconfirm git
    elif command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update -y && sudo apt-get install -y git
    else
      echo "❌ 无法安装 git，请手动安装后重试" >&2
      exit 1
    fi
  fi

  # 克隆裸仓库
  echo "📥 克隆仓库：$REPO ($BRANCH)"
  rm -rf "$DOTDIR"
  git clone --bare --branch "$BRANCH" "$REPO" "$DOTDIR"

  # 提取 bootstrap 目录
  echo "📦 准备安装脚本..."
  git --git-dir="$DOTDIR" archive "$BRANCH" .config/dotfiles/bootstrap | tar -x -C "$TMP_DIR"

  # 重新执行自身
  echo "🚀 启动安装程序..."
  echo ""
  BOOTSTRAP_STAGE=1 DOTDIR="$DOTDIR" REPO="$REPO" BRANCH="$BRANCH" \
    bash "$TMP_DIR/.config/dotfiles/bootstrap/bootstrap.sh" "$@"

  rm -rf "$TMP_DIR"
  exit 0
fi

# ============================================================================
# 加载依赖
# ============================================================================
source "$SCRIPT_DIR/lib/common.sh"

# ============================================================================
# 命令行参数解析
# ============================================================================
NON_INTERACTIVE="${NON_INTERACTIVE:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
    -y|--yes|--non-interactive)
      NON_INTERACTIVE=1
      shift
      ;;
    -h|--help)
      cat << 'EOF'
Dotfiles Bootstrap - 一键配置你的开发环境

用法:
  bash bootstrap.sh [选项]

选项:
  -y, --yes              非交互模式，使用默认配置
  -h, --help             显示此帮助信息

环境变量:
  REPO                   Git 仓库地址
  DOTDIR                 裸仓库位置（默认：~/.dotfiles）
  MIHOMO_SETUP=1         启用 mihomo 安装
  FCITX5_SETUP=1         启用 fcitx5 安装

示例:
  # 交互式安装
  bash bootstrap.sh

  # 非交互式安装
  bash bootstrap.sh --yes

  # 同时安装 mihomo 和 fcitx5
  MIHOMO_SETUP=1 FCITX5_SETUP=1 bash bootstrap.sh --yes
EOF
      exit 0
      ;;
    *)
      echo "未知参数：$1"
      echo "使用 --help 查看帮助"
      exit 1
      ;;
  esac
done

# ============================================================================
# 欢迎界面
# ============================================================================
banner

info "即将为你配置以下内容："
echo ""
echo "   ${ICON_PACKAGE} 系统软件包（zsh, tmux, nvim, starship 等）"
echo "   ${ICON_GEAR} Dotfiles 配置文件（zsh, tmux, nvim 等）"
echo "   ${ICON_PLUGIN} 插件管理器（zinit, TPM, LazyVim）"
echo "   ${ICON_LOCK} 密钥文件模板"
echo ""

if [ "$MIHOMO_SETUP" = "1" ]; then
  echo "   ${ICON_ROCKET} Mihomo 代理（可选，已启用）"
fi

if [ "$FCITX5_SETUP" = "1" ]; then
  echo "   ${ICON_FONT} Fcitx5 输入法（可选，已启用）"
fi

echo ""
separator

# ============================================================================
# 检测发行版
# ============================================================================
if command -v pacman >/dev/null 2>&1; then
  DISTRO="arch"
  info "检测到发行版：Arch Linux / CachyOS"
elif command -v apt-get >/dev/null 2>&1; then
  DISTRO="debian"
  info "检测到发行版：Debian / Ubuntu"
else
  error "不支持的发行版（需要 pacman 或 apt-get）"
  exit 1
fi

export DISTRO

echo ""

# ============================================================================
# 交互式配置（仅在非交互模式下跳过）
# ============================================================================
if [ "$NON_INTERACTIVE" != "1" ]; then
  if ! ask_yes "是否继续安装？"; then
    warn "安装已取消"
    exit 0
  fi

  echo ""
  info "你可以自定义一些选项，或直接回车使用默认值"
  echo ""

  # 仅询问关键问题
  if [ "$DISTRO" = "arch" ]; then
    if ask_yes "是否优化 Arch 镜像源？（推荐中国大陆用户）"; then
      RUN_MIRRORS=1
    else
      RUN_MIRRORS=0
    fi
  fi

  echo ""

  if ask_yes "是否设置 zsh 为默认 shell？"; then
    SET_DEFAULT_SHELL=1
  else
    SET_DEFAULT_SHELL=0
  fi

  echo ""

  if ask_yes "是否同步 Neovim 插件？（首次安装推荐，耗时较长）"; then
    INSTALL_NVIM_PLUGINS=1
  else
    INSTALL_NVIM_PLUGINS=0
  fi

  echo ""

  # 可选功能
  info "可选功能（通常不需要）："
  echo ""

  if ask_no "是否安装 mihomo 代理？"; then
    MIHOMO_SETUP=1
  fi

  if ask_no "是否安装 fcitx5 输入法？"; then
    FCITX5_SETUP=1
  fi

  # 导出配置
  export RUN_MIRRORS SET_DEFAULT_SHELL INSTALL_NVIM_PLUGINS
  export MIHOMO_SETUP FCITX5_SETUP
else
  info "使用非交互模式，将使用默认配置"
fi

# ============================================================================
# 执行安装步骤
# ============================================================================
separator
echo ""

# 定义要执行的步骤
STEPS="packages dotfiles secrets shell plugins"

if [ "$MIHOMO_SETUP" = "1" ]; then
  STEPS="$STEPS mihomo"
fi

if [ "$FCITX5_SETUP" = "1" ]; then
  STEPS="$STEPS fcitx5"
fi

STEPS="$STEPS fonts"

# 计算总步骤数
TOTAL_STEPS=$(echo $STEPS | wc -w)
CURRENT_STEP=0

# 执行每个步骤
for s in $STEPS; do
  CURRENT_STEP=$((CURRENT_STEP + 1))

  case "$s" in
    packages)
      step "[$CURRENT_STEP/$TOTAL_STEPS] ${ICON_PACKAGE} 安装系统软件包"
      if [ "$DISTRO" = "arch" ]; then
        bash "$SCRIPT_DIR/steps/pacman-packages.sh"
      else
        bash "$SCRIPT_DIR/steps/apt-packages.sh"
      fi
      ;;

    dotfiles)
      step "[$CURRENT_STEP/$TOTAL_STEPS] ${ICON_GEAR} 部署 Dotfiles"
      bash "$SCRIPT_DIR/steps/dotfiles-checkout.sh"
      ;;

    secrets)
      step "[$CURRENT_STEP/$TOTAL_STEPS] ${ICON_LOCK} 创建密钥文件"
      bash "$SCRIPT_DIR/steps/secrets.sh"
      ;;

    shell)
      step "[$CURRENT_STEP/$TOTAL_STEPS] ${ICON_GEAR} 设置默认 Shell"
      bash "$SCRIPT_DIR/steps/shell-default.sh"
      ;;

    plugins)
      step "[$CURRENT_STEP/$TOTAL_STEPS] ${ICON_PLUGIN} 安装插件管理器"
      bash "$SCRIPT_DIR/steps/plugins.sh"
      ;;

    mihomo)
      step "[$CURRENT_STEP/$TOTAL_STEPS] ${ICON_ROCKET} 配置 Mihomo"
      if [ "$DISTRO" = "arch" ]; then
        bash "$SCRIPT_DIR/steps/mihomo-pacman.sh"
      else
        bash "$SCRIPT_DIR/steps/mihomo-apt.sh"
      fi
      ;;

    fcitx5)
      step "[$CURRENT_STEP/$TOTAL_STEPS] ${ICON_FONT} 安装 Fcitx5"
      if [ "$DISTRO" = "arch" ]; then
        bash "$SCRIPT_DIR/steps/fcitx5-rime-pacman.sh"
      else
        bash "$SCRIPT_DIR/steps/fcitx5-rime-apt.sh"
      fi
      ;;

    fonts)
      step "[$CURRENT_STEP/$TOTAL_STEPS] ${ICON_FONT} 安装字体"
      if [ "$DISTRO" = "arch" ]; then
        bash "$SCRIPT_DIR/steps/fonts-arch.sh"
      else
        bash "$SCRIPT_DIR/steps/fonts-apt.sh"
      fi
      ;;
  esac

  echo ""
done

# ============================================================================
# 完成
# ============================================================================
finish_banner

success "所有步骤已完成！"
echo ""
info "后续步骤："
echo "   1. 重新登录以应用 shell 更改"
echo "   2. 首次启动 tmux 时按 ${BRIGHT_WHITE}Ctrl+b I${RESET} 安装插件"
echo "   3. 编辑 ${BRIGHT_WHITE}~/.config/zsh/env.d/90-secrets.zsh${RESET} 添加密钥"
echo ""

if [ "$MIHOMO_SETUP" = "1" ]; then
  info "Mihomo 提醒："
  echo "   - 编辑 ${BRIGHT_WHITE}~/.config/mihomo/config.yaml${RESET} 配置订阅"
  echo "   - 运行 ${BRIGHT_WHITE}systemctl --user status mihomo${RESET} 检查状态"
  echo ""
fi

if [ "$FCITX5_SETUP" = "1" ]; then
  info "Fcitx5 提醒："
  echo "   - 重新登录后在输入法配置中添加 Rime"
  echo "   - 如需更多输入法方案，请访问 rime-ice 项目"
  echo ""
fi

info "管理 dotfiles："
echo "   ${BRIGHT_CYAN}dotfiles status${RESET}          查看状态"
echo "   ${BRIGHT_CYAN}dotfiles add <file>${RESET}      添加文件"
echo "   ${BRIGHT_CYAN}dotfiles commit -m \"msg\"${RESET}  提交更改"
echo "   ${BRIGHT_CYAN}dotfiles push${RESET}             推送到远程"
echo ""

success "祝你使用愉快！${ICON_ROCKET}"
echo ""
