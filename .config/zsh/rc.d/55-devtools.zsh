# ------------------- 重型开发工具（可开关） -------------------
# 设计目标：
# - 默认以「轻量模式」启动 shell（不自动注入 mise / conda 等复杂逻辑）；
# - 需要完整开发环境时，通过环境变量或 alias 显式开启。
#
# 使用方式：
# - 一次性开启一个“重型”子 shell：
#     zsh-dev          # 自动以 OGAS_DEV_TOOLS=1 启动 zsh -i
# - 若希望当前会话就是重型模式，可以在启动前设置：
#     OGAS_DEV_TOOLS=1 zsh -i
#
# 注意事项：
# - 只有交互式 shell 才会加载本模块（由 ~/.zshrc 控制）；
# - 脚本模式（zsh script.zsh）不会执行这里的逻辑，不会被 mise / conda 污染；
# - 本文件可以安全地调用外部命令（mise/conda），但只在 OGAS_DEV_TOOLS=1 时执行。

# 如果没有显式开启开发模式，则直接返回，保持启动极简。
if [[ ${OGAS_DEV_TOOLS:-0} -ne 1 ]]; then
  return
fi

# ------------------- mise 开发环境管理工具 -------------------
# 说明：
# - mise 负责按目录切换开发语言/工具链版本；
# - 这里调用 `mise activate zsh` 注入 shim 与补全。
# 动态查找 mise 命令，兼容 Linux (/usr/bin) 和 macOS (/opt/homebrew/bin)
if command -v mise >/dev/null 2>&1; then
  # 使用找到的 mise 路径进行初始化
  eval "$($(command -v mise) activate zsh)"
fi

# ------------------- pnpm -------------------
# 说明：
# - 将 pnpm 的 home 放在 XDG 数据目录；
# - 幂等地将其加入 PATH。
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) PATH="$PNPM_HOME:$PATH" ;;
esac
export PATH

# ------------------- conda（Miniforge） -------------------
# 说明：
# - 优先通过 `conda shell.zsh hook` 获取初始化代码；
# - 如失败，则退回到 profile.d/conda.sh 或直接把 bin 加入 PATH；
# - 使用 XDG 位置的 condarc（可以在不同机器放不同配置）。

if [ -x "/opt/miniforge/bin/conda" ]; then
  export CONDARC="$XDG_CONFIG_HOME/conda/condarc"
  __conda_setup="$('/opt/miniforge/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
  if [ $? -eq 0 ]; then
    eval "$__conda_setup"
  elif [ -f "/opt/miniforge/etc/profile.d/conda.sh" ]; then
    . "/opt/miniforge/etc/profile.d/conda.sh"
  else
    PATH="/opt/miniforge/bin:$PATH"
    export PATH
  fi
  unset __conda_setup
fi
