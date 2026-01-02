#!/usr/bin/env bash
# ============================================================================
# Dotfiles Bootstrap v2.0 - 完全重构版
# ============================================================================
#
# 核心改进：
#   ✓ 原子性：每个步骤要么完全成功，要么完全失败
#   ✓ 可恢复性：中断后可以从失败点继续
#   ✓ 幂等性：可以安全地重复运行
#   ✓ 详细提示：每步都有详细说明、风险提示、验证
#   ✓ 智能依赖：自动检查和满足依赖关系
#
# 用法：
#   交互式安装：
#     bash bootstrap.sh
#
#   非交互式安装：
#     bash bootstrap.sh --yes
#
#   继续上次安装：
#     bash bootstrap.sh --resume
#
#   重试失败步骤：
#     bash bootstrap.sh --retry
#
#   重置状态：
#     bash bootstrap.sh --reset
#
#   查看状态：
#     bash bootstrap.sh --status
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
source "$SCRIPT_DIR/lib/ui.sh"
source "$SCRIPT_DIR/lib/state.sh"
source "$SCRIPT_DIR/lib/steps.sh"
source "$SCRIPT_DIR/lib/common.sh"

# 初始化状态系统
state_init

# ============================================================================
# 命令行参数解析
# ============================================================================
MODE="normal"
NON_INTERACTIVE="${NON_INTERACTIVE:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
    -y|--yes|--non-interactive)
      NON_INTERACTIVE=1
      shift
      ;;
    --resume)
      MODE="resume"
      shift
      ;;
    --retry)
      MODE="retry"
      shift
      ;;
    --reset)
      MODE="reset"
      shift
      ;;
    --status)
      MODE="status"
      shift
      ;;
    -h|--help)
      cat << 'EOF'
Dotfiles Bootstrap v2.0 - 一键配置你的开发环境

用法:
  bash bootstrap.sh [选项]

模式:
  (默认)                 正常安装流程
  --resume               从上次中断处继续
  --retry                重试所有失败的步骤
  --status               显示当前状态
  --reset                重置所有状态（慎用）

选项:
  -y, --yes              非交互模式，使用默认配置
  -h, --help             显示此帮助信息

环境变量:
  REPO                   Git 仓库地址
  DOTDIR                 裸仓库位置（默认：~/.dotfiles）
  MIHOMO_SETUP=1         启用 mihomo 安装
  FCITX5_SETUP=1         启用 fcitx5 安装
  RUN_MIRRORS=1          优化 Arch 镜像源
  INSTALL_NVIM_PLUGINS=1 同步 Neovim 插件

示例:
  # 交互式安装
  bash bootstrap.sh

  # 非交互式安装
  bash bootstrap.sh --yes

  # 查看当前状态
  bash bootstrap.sh --status

  # 继续上次安装
  bash bootstrap.sh --resume

  # 重试失败的步骤
  bash bootstrap.sh --retry
EOF
      exit 0
      ;;
    *)
      error "未知参数：$1"
      echo "使用 --help 查看帮助"
      exit 1
      ;;
  esac
done

export NON_INTERACTIVE

# ============================================================================
# 模式处理
# ============================================================================

case "$MODE" in
  status)
    # 显示状态
    banner
    state_summary
    echo ""
    info "详细状态："
    echo ""
    for step in packages dotfiles secrets shell plugins mihomo fcitx5 fonts; do
      status=$(state_get "$step")
      name=$(step_get_name "$step")
      case "$status" in
        success)
          success "$name: 已完成"
          ;;
        failed)
          error "$name: 失败"
          ;;
        running)
          warn "$name: 运行中"
          ;;
        skipped)
          info "$name: 已跳过"
          ;;
        *)
          info "$name: 待执行"
          ;;
      esac
    done
    exit 0
    ;;

  reset)
    warn "即将重置所有安装状态"
    if [ "$NON_INTERACTIVE" != "1" ]; then
      if ! ask_no "确定要重置吗？这将清除所有进度记录"; then
        info "已取消"
        exit 0
      fi
    fi
    state_reset
    success "状态已重置"
    exit 0
    ;;

  retry)
    # 重试失败的步骤
    banner
    steps_retry_failed
    exit $?
    ;;

  resume)
    # 从上次中断处继续
    banner
    info "恢复上次安装..."
    # 继续执行正常流程
    ;;

  normal)
    # 正常流程
    ;;
esac

# ============================================================================
# 欢迎界面
# ============================================================================
banner

# 检查是否有未完成的安装
completed=$(state_get_completed | wc -l)
failed=$(state_get_failed | wc -l)

if [ "$completed" -gt 0 ] || [ "$failed" -gt 0 ]; then
  warn "检测到之前的安装记录："
  echo "  完成: $completed 个步骤"
  echo "  失败: $failed 个步骤"
  echo ""

  if [ "$MODE" != "resume" ] && [ "$NON_INTERACTIVE" != "1" ]; then
    local choice=$(ask_choice "如何处理？" \
      "从头开始（重置状态）" "r" \
      "继续安装" "c" \
      "退出" "q")

    case "$choice" in
      r)
        state_reset
        info "状态已重置"
        ;;
      c)
        info "继续安装"
        ;;
      q)
        exit 0
        ;;
    esac
    echo ""
  fi
fi

info "即将为你配置以下内容："
echo ""
echo "   ${ICON_PACKAGE} 系统软件包（zsh, tmux, nvim, starship 等）"
echo "   ${ICON_GEAR} Dotfiles 配置文件（zsh, tmux, nvim 等）"
echo "   ${ICON_LOCK} 密钥文件模板"
echo "   ${ICON_GEAR} 默认 Shell 设置"
echo "   ${ICON_PLUGIN} 插件管理器（zinit, TPM, LazyVim）"
echo ""

# 可选组件
local MIHOMO_SETUP="${MIHOMO_SETUP:-0}"
local FCITX5_SETUP="${FCITX5_SETUP:-0}"

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
# 询问用户配置
# ============================================================================
if [ "$NON_INTERACTIVE" != "1" ] && [ "$MODE" != "resume" ]; then
  if ! ask_yes "是否继续安装？"; then
    warn "安装已取消"
    exit 0
  fi

  echo ""
  info "快速配置（可以直接回车使用推荐值）："
  echo ""

  # 仅询问关键问题
  if [ "$DISTRO" = "arch" ]; then
    if ask_yes "是否优化 Arch 镜像源？（推荐中国大陆用户）"; then
      RUN_MIRRORS=1
      config_save "RUN_MIRRORS" "1"
    else
      RUN_MIRRORS=0
      config_save "RUN_MIRRORS" "0"
    fi
  fi

  echo ""

  if ask_yes "是否设置 zsh 为默认 shell？"; then
    SET_DEFAULT_SHELL=1
    config_save "SET_DEFAULT_SHELL" "1"
  else
    SET_DEFAULT_SHELL=0
    config_save "SET_DEFAULT_SHELL" "0"
  fi

  echo ""

  if ask_yes "是否同步 Neovim 插件？（首次安装推荐，但耗时较长）"; then
    INSTALL_NVIM_PLUGINS=1
    config_save "INSTALL_NVIM_PLUGINS" "1"
  else
    INSTALL_NVIM_PLUGINS=0
    config_save "INSTALL_NVIM_PLUGINS" "0"
  fi

  # 导出配置
  export RUN_MIRRORS SET_DEFAULT_SHELL INSTALL_NVIM_PLUGINS
else
  # 非交互模式或恢复模式：使用保存的配置或默认值
  RUN_MIRRORS=$(config_get "RUN_MIRRORS" "1")
  SET_DEFAULT_SHELL=$(config_get "SET_DEFAULT_SHELL" "1")
  INSTALL_NVIM_PLUGINS=$(config_get "INSTALL_NVIM_PLUGINS" "1")
  export RUN_MIRRORS SET_DEFAULT_SHELL INSTALL_NVIM_PLUGINS

  info "使用${MODE}模式，配置："
  echo "  RUN_MIRRORS=$RUN_MIRRORS"
  echo "  SET_DEFAULT_SHELL=$SET_DEFAULT_SHELL"
  echo "  INSTALL_NVIM_PLUGINS=$INSTALL_NVIM_PLUGINS"
fi

# ============================================================================
# 执行安装步骤
# ============================================================================
separator
echo ""

# 定义要执行的步骤（按依赖顺序）
STEPS=(packages dotfiles secrets shell plugins fonts)

# 添加可选步骤
if [ "$MIHOMO_SETUP" = "1" ]; then
  STEPS+=(mihomo)
fi

if [ "$FCITX5_SETUP" = "1" ]; then
  STEPS+=(fcitx5)
fi

# 执行步骤列表
steps_execute_list "${STEPS[@]}"
EXIT_CODE=$?

# ============================================================================
# 完成
# ============================================================================
echo ""

if [ $EXIT_CODE -eq 0 ]; then
  finish_banner
  success "所有步骤已完成！"
else
  warn "部分步骤失败"
  echo ""
  info "你可以："
  echo "  • 查看状态: bash bootstrap.sh --status"
  echo "  • 重试失败的步骤: bash bootstrap.sh --retry"
  echo "  • 查看日志: ls $LOG_DIR"
fi

echo ""
info "后续步骤："
echo "   1. 重新登录以应用 shell 更改"
echo "   2. 首次启动 tmux 时按 ${BRIGHT_WHITE}Ctrl+b I${RESET} 安装插件"
echo "   3. 编辑 ${BRIGHT_WHITE}~/.config/zsh/env.d/90-secrets.zsh${RESET} 添加密钥"
echo ""

info "管理 dotfiles："
echo "   ${BRIGHT_CYAN}dotfiles status${RESET}          查看状态"
echo "   ${BRIGHT_CYAN}dotfiles add <file>${RESET}      添加文件"
echo "   ${BRIGHT_CYAN}dotfiles commit -m \"msg\"${RESET}  提交更改"
echo "   ${BRIGHT_CYAN}dotfiles push${RESET}             推送到远程"
echo ""

success "祝你使用愉快！${ICON_ROCKET}"
echo ""

exit $EXIT_CODE
