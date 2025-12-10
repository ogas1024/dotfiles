#!/usr/bin/env bash
# 顶层调度器（交互式、多步骤、可选择性执行；支持 curl 直接运行）
# 特性：
#   - 如当前目录缺少 steps/，自动裸克隆 REPO 到 DOTDIR，打包 bootstrap 到临时目录再自举，无需额外 stage0；
#   - 启动时逐项询问关键变量（带默认值）并 export，避免全局耦合；
#   - 自动检测发行版（pacman/apt）并调用对应步骤脚本；
#   - 每一步前给出“将做什么 / 完成后需手动什么”的中文提示，再询问 y=执行 / s=跳过 / e=退出；
#   - 默认步骤：packages dotfiles secrets shell plugins mihomo fcitx5 fonts，可通过 STEPS 调整。
# 用法：
#   # 如果已经在仓库工作树内：
#   bash ~/.config/dotfiles/bootstrap/bootstrap.sh
#   # 如果想 curl 直接跑（单文件入口）：
#   curl -fsSL https://raw.githubusercontent.com/<you>/<dotfiles>/main/.config/dotfiles/bootstrap/bootstrap.sh | bash

set -euo pipefail

# 兼容 curl | bash：BASH_SOURCE 可能为空
SCRIPT_PATH="${BASH_SOURCE[0]:-}"
if [ -z "$SCRIPT_PATH" ] || [ "$SCRIPT_PATH" = "-" ]; then
  SCRIPT_DIR="$(pwd)"
else
  SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
fi

# ---- 自举逻辑：如果 steps 不存在，裸克隆 + 打包后重新执行自己 ----
if [ "${BOOTSTRAP_STAGE:-0}" != "1" ] && [ ! -d "$SCRIPT_DIR/steps" ]; then
  REPO="${REPO:-https://github.com/ogas1024/dotfiles.git}"
  BRANCH="${BRANCH:-main}"
  DOTDIR="${DOTDIR:-$HOME/.dotfiles}"
  TMP_BASE="${TMPDIR:-/tmp}"
  TMP_DIR="$(mktemp -d "${TMP_BASE%/}/dotfiles-bootstrap-XXXXXX")"
  echo "[bootstrap] steps 不存在，进行自举：裸克隆 $REPO ($BRANCH) -> $DOTDIR"
  if ! command -v git >/dev/null 2>&1; then
    echo "[bootstrap] 未检测到 git，尝试安装..."
    if command -v pacman >/dev/null 2>&1; then
      sudo pacman -Sy --noconfirm git
    elif command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update -y && sudo apt-get install -y git
    else
      echo "[bootstrap] 无法安装 git（未检测到 pacman/apt-get），请手动安装后重试。" >&2
      exit 1
    fi
  fi
  rm -rf "$DOTDIR"
  git clone --bare --branch "$BRANCH" "$REPO" "$DOTDIR"
  echo "[bootstrap] 打包 bootstrap 目录到临时目录 $TMP_DIR"
  git --git-dir="$DOTDIR" archive "$BRANCH" .config/dotfiles/bootstrap | tar -x -C "$TMP_DIR"
  echo "[bootstrap] 重新执行自身（携带 BOOTSTRAP_STAGE=1）"
  BOOTSTRAP_STAGE=1 DOTDIR="$DOTDIR" REPO="$REPO" BRANCH="$BRANCH" bash "$TMP_DIR/.config/dotfiles/bootstrap/bootstrap.sh"
  rm -rf "$TMP_DIR"
  exit 0
fi

prompt_var() {
  local var="$1" default="$2" val
  read -r -p "$var [$default]: " val
  if [ -z "$val" ]; then val="$default"; fi
  export "$var=$val"
}

# ---- 交互式变量输入（带默认值；集中在此减少耦合） ----
prompt_var REPO "${REPO:-git@github.com:ogas1024/dotfiles.git}"
prompt_var DOTDIR "${DOTDIR:-$HOME/.dotfiles}"
prompt_var ZDOTDIR "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
prompt_var RUN_MIRRORS "${RUN_MIRRORS:-1}"
prompt_var REFLECTOR_COUNTRY "${REFLECTOR_COUNTRY:-China}"
prompt_var SET_DEFAULT_SHELL "${SET_DEFAULT_SHELL:-1}"
prompt_var INSTALL_NVIM_PLUGINS "${INSTALL_NVIM_PLUGINS:-1}"
prompt_var MIHOMO_SETUP "${MIHOMO_SETUP:-1}"
prompt_var MIHOMO_CONFIG "${MIHOMO_CONFIG:-$HOME/.config/mihomo/config.yaml}"
prompt_var MIHOMO_DOWNLOAD_GEODATA "${MIHOMO_DOWNLOAD_GEODATA:-1}"
prompt_var MIHOMO_ENABLE_SERVICE "${MIHOMO_ENABLE_SERVICE:-1}"
prompt_var MIHOMO_USER "${MIHOMO_USER:-mihomo}"
prompt_var MIHOMO_GEO_BASE "${MIHOMO_GEO_BASE:-https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release}"
prompt_var MIHOMO_TGZ_URL "${MIHOMO_TGZ_URL:-https://github.com/MetaCubeX/mihomo/releases/latest/download/mihomo-linux-amd64.tar.gz}"
prompt_var FCITX5_SETUP "${FCITX5_SETUP:-1}"
prompt_var STEPS "${STEPS:-packages dotfiles secrets shell plugins mihomo fcitx5 fonts}"

# ---- 检测发行版（一次判定，后续步骤调用时不再重复判定） ----
if command -v pacman >/dev/null 2>&1; then
  DISTRO="arch"
elif command -v apt-get >/dev/null 2>&1; then
  DISTRO="debian"
else
  echo "Unsupported distro: neither pacman nor apt-get found." >&2
  exit 1
fi

# ---- 步骤执行路由 ----
run_step() {
  local step="$1"
  case "$step" in
  packages)
    if [ "$DISTRO" = "arch" ]; then
      bash "$SCRIPT_DIR/steps/pacman-packages.sh"
    else
      bash "$SCRIPT_DIR/steps/apt-packages.sh"
    fi
    ;;
  dotfiles)
    bash "$SCRIPT_DIR/steps/dotfiles-checkout.sh"
    ;;
  secrets)
    bash "$SCRIPT_DIR/steps/secrets.sh"
    ;;
  shell)
    bash "$SCRIPT_DIR/steps/shell-default.sh"
    ;;
  plugins)
    bash "$SCRIPT_DIR/steps/plugins.sh"
    ;;
  mihomo)
    if [ "$DISTRO" = "arch" ]; then
      bash "$SCRIPT_DIR/steps/mihomo-pacman.sh"
    else
      bash "$SCRIPT_DIR/steps/mihomo-apt.sh"
    fi
    ;;
  fcitx5)
    if [ "$DISTRO" = "arch" ]; then
      bash "$SCRIPT_DIR/steps/fcitx5-rime-pacman.sh"
    else
      bash "$SCRIPT_DIR/steps/fcitx5-rime-apt.sh"
    fi
    ;;
  fonts)
    if [ "$DISTRO" = "arch" ]; then
      bash "$SCRIPT_DIR/steps/fonts-arch.sh"
    else
      bash "$SCRIPT_DIR/steps/fonts-apt.sh"
    fi
    ;;
  *)
    echo "Unknown step: $step" >&2
    exit 1
    ;;
  esac
}

# ---- 步骤说明（执行前展示，便于用户决策） ----
step_info() {
  local step="$1"
  case "$step" in
  packages)
    echo "即将执行：安装/升级系统与常用软件（含 paru 仅在 Arch）；可能耗时且需要网络。"
    echo "完成后：无需额外动作。"
    ;;
  dotfiles)
    echo "即将执行：裸仓库 checkout -f 覆盖本地同名文件，使用 REPO=$REPO。"
    echo "完成后：如果有冲突或自定义文件会被覆盖，需自行备份。"
    ;;
  secrets)
    echo "即将执行：创建 ~/.config/zsh/env.d/90-secrets.zsh（已忽略）。"
    echo "完成后：手动编辑填入密钥，并 chmod 600（脚本已做）。"
    ;;
  shell)
    echo "即将执行：chsh 将默认 shell 设置为 zsh（SET_DEFAULT_SHELL=$SET_DEFAULT_SHELL）。"
    echo "完成后：重新登录后生效。"
    ;;
  plugins)
    echo "即将执行：安装 TPM、触发 zinit、LazyVim 插件同步（INSTALL_NVIM_PLUGINS=$INSTALL_NVIM_PLUGINS）。"
    echo "完成后：无手动步骤，首次 nvim 启动若有缺依赖需自行处理。"
    ;;
  mihomo)
    echo "即将执行：原生 mihomo 部署（配置源：$MIHOMO_CONFIG，下载 geodata=$MIHOMO_DOWNLOAD_GEODATA，启动服务=$MIHOMO_ENABLE_SERVICE）。"
    echo "完成后：如未在 $MIHOMO_CONFIG 填写订阅 URL/密钥，请先填写再运行本步骤；如已启动服务可用 systemctl status mihomo 查看。"
    ;;
  fcitx5)
    echo "即将执行：安装/配置 fcitx5 + rime（含环境变量写入 /etc/environment，Arch 会装 rime-ice-git）。"
    echo "完成后：需重新登录使环境变量生效；首次启动 Fcitx5 后在配置工具中添加 Rime，必要时运行 rime_deployer。"
    ;;
  fonts)
    echo "即将执行：安装常用字体（Arch 用 paru 包含 AUR；Debian 用可用替代包）。"
    echo "完成后：如需额外字体请手动放入 ~/.local/share/fonts 并运行 fc-cache -fv，商用字体自行准备。"
    ;;
  esac
}

# ---- 询问并执行单步 ----
confirm_and_run() {
  local step="$1" ans
  step_info "$step"
  while true; do
    read -r -p "[step: $step] y=执行 / s=跳过 / e=退出 ? " ans
    case "$ans" in
    y | Y)
      run_step "$step"
      break
      ;;
    s | S)
      echo "[skip] $step"
      break
      ;;
    e | E)
      echo "退出"
      exit 0
      ;;
    *) echo "请输入 y / s / e" ;;
    esac
  done
}

for s in $STEPS; do
  confirm_and_run "$s"
done
