#!/usr/bin/env bash
# 用户界面工具函数：彩色输出、图标、进度提示
# 灵感来自 holman/dotfiles 和现代化 CLI 工具

# ============================================================================
# 颜色定义（ANSI 转义序列）
# ============================================================================
if [ -t 1 ]; then
  # 仅在终端输出时使用颜色
  BOLD='\033[1m'
  RESET='\033[0m'

  # 前景色
  BLACK='\033[0;30m'
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  MAGENTA='\033[0;35m'
  CYAN='\033[0;36m'
  WHITE='\033[0;37m'

  # 高亮色
  BRIGHT_RED='\033[1;31m'
  BRIGHT_GREEN='\033[1;32m'
  BRIGHT_YELLOW='\033[1;33m'
  BRIGHT_BLUE='\033[1;34m'
  BRIGHT_MAGENTA='\033[1;35m'
  BRIGHT_CYAN='\033[1;36m'
  BRIGHT_WHITE='\033[1;37m'

  # 背景色
  BG_BLUE='\033[44m'
else
  # 非终端环境，不使用颜色
  BOLD=''
  RESET=''
  BLACK='' RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' WHITE=''
  BRIGHT_RED='' BRIGHT_GREEN='' BRIGHT_YELLOW='' BRIGHT_BLUE='' BRIGHT_MAGENTA='' BRIGHT_CYAN='' BRIGHT_WHITE=''
  BG_BLUE=''
fi

# ============================================================================
# Unicode 图标（如果终端不支持，会降级为 ASCII）
# ============================================================================
ICON_CHECK="✓"
ICON_CROSS="✗"
ICON_ARROW="➜"
ICON_INFO="ℹ"
ICON_WARN="⚠"
ICON_QUESTION="?"
ICON_ROCKET="🚀"
ICON_PACKAGE="📦"
ICON_GEAR="⚙"
ICON_LOCK="🔒"
ICON_PLUGIN="🔌"
ICON_FONT="🔤"

# ============================================================================
# 核心输出函数
# ============================================================================

# 信息提示（蓝色）
info() {
  printf "\r  [ ${BLUE}${ICON_INFO}${RESET} ] $1\n"
}

# 成功提示（绿色）
success() {
  printf "\r${BOLD}${GREEN}  [ ${ICON_CHECK} ] $1${RESET}\n"
}

# 错误提示（红色）
error() {
  printf "\r${BOLD}${BRIGHT_RED}  [ ${ICON_CROSS} ] $1${RESET}\n" >&2
}

# 警告提示（黄色）
warn() {
  printf "\r  [ ${YELLOW}${ICON_WARN}${RESET} ] ${YELLOW}$1${RESET}\n"
}

# 用户提问（青色）
ask() {
  printf "\r  [ ${CYAN}${ICON_QUESTION}${RESET} ] ${BOLD}$1${RESET} "
}

# 步骤标题（大标题，带背景）
step() {
  printf "\n${BG_BLUE}${WHITE}${BOLD} ${ICON_ARROW} $1 ${RESET}\n\n"
}

# 子步骤（缩进）
substep() {
  printf "     ${BRIGHT_CYAN}→${RESET} $1\n"
}

# 运行中的任务（旋转动画）
running() {
  printf "\r  [ ${YELLOW}...${RESET} ] $1"
}

# ============================================================================
# 交互函数
# ============================================================================

# 询问 yes/no 问题（默认 yes）
# 用法: ask_yes "是否继续？" && do_something
ask_yes() {
  local prompt="${1:-继续吗？}"
  local response

  ask "$prompt ${BRIGHT_WHITE}[Y/n]${RESET}"
  read -r response

  case "$response" in
    [nN][oO]|[nN])
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

# 询问 yes/no 问题（默认 no）
ask_no() {
  local prompt="${1:-继续吗？}"
  local response

  ask "$prompt ${BRIGHT_WHITE}[y/N]${RESET}"
  read -r response

  case "$response" in
    [yY][eE][sS]|[yY])
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# 询问带默认值的问题
# 用法: answer=$(ask_default "你的名字？" "John")
ask_default() {
  local prompt="$1"
  local default="$2"
  local response

  ask "$prompt ${BRIGHT_WHITE}[${default}]${RESET}"
  read -r response

  echo "${response:-$default}"
}

# 单字符选择菜单
# 用法: ask_choice "选择操作" "继续" "c" "跳过" "s" "退出" "q"
ask_choice() {
  local prompt="$1"
  shift

  printf "\n  ${BOLD}${CYAN}${ICON_QUESTION} ${prompt}${RESET}\n"

  # 打印选项
  while [ $# -ge 2 ]; do
    local desc="$1"
    local key="$2"
    printf "     ${BRIGHT_WHITE}[${BRIGHT_YELLOW}${key}${BRIGHT_WHITE}]${RESET} ${desc}\n"
    shift 2
  done

  printf "\n  ${CYAN}→${RESET} "
  read -r -n 1 choice
  printf "\n"

  echo "$choice"
}

# ============================================================================
# Banner 和装饰
# ============================================================================

# 显示欢迎 banner
banner() {
  cat << "EOF"

    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║     🚀  Dotfiles Bootstrap - 一键配置你的开发环境        ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝

EOF
}

# 显示完成 banner
finish_banner() {
  cat << "EOF"

    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║     ✨  安装完成！享受你的新环境吧！                      ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝

EOF
}

# 分隔线
separator() {
  printf "${BRIGHT_WHITE}    ────────────────────────────────────────────────────${RESET}\n"
}

# ============================================================================
# 进度条（简单版本）
# ============================================================================

# 显示进度
# 用法: show_progress 3 10 "正在安装..."
show_progress() {
  local current=$1
  local total=$2
  local message="${3:-处理中}"
  local percent=$((current * 100 / total))
  local filled=$((percent / 2))
  local empty=$((50 - filled))

  printf "\r  ${CYAN}[${RESET}"
  printf "%${filled}s" | tr ' ' '='
  printf "%${empty}s" | tr ' ' ' '
  printf "${CYAN}]${RESET} ${percent}%% ${message}"

  [ "$current" -eq "$total" ] && printf "\n"
}

# ============================================================================
# 辅助函数
# ============================================================================

# 在同一行更新消息（用于动态状态更新）
update_line() {
  printf "\r\033[K  $1"
}

# 清除当前行
clear_line() {
  printf "\r\033[K"
}
