# ------------------- Zinit：插件管理器（安装与加载） -------------------
# ZINIT_HOME：将 zinit 安装在 XDG 数据目录下，保持 $HOME 干净。
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -f $ZINIT_HOME/zinit.zsh ]]; then
  # 首次安装 zinit（仅执行一次）。
  print -P "%F{33} %F{220}正在安装 Zinit…%f"
  command mkdir -p "$(dirname $ZINIT_HOME)"
  command git clone https://github.com/zdharma-continuum/zinit "$ZINIT_HOME" && \
    print -P "%F{33} %F{34}Zinit 安装成功.%f%b" || \
    print -P "%F{160}Zinit 克隆失败.%f%b"
fi

# 加载 zinit 核心与补全
source "${ZINIT_HOME}/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# 性能与兼容性优化选项：
# - skip_global_compinit：不自动跑全局 compinit，交给我们在 40-completion.zsh 手动初始化。
# - DISABLE_MAGIC_FUNCTIONS/ZSH_DISABLE_COMPFIX：避免某些全局定义带来的慢启动与告警。
skip_global_compinit=1
DISABLE_MAGIC_FUNCTIONS=true
ZSH_DISABLE_COMPFIX=true

# Annexes（扩展功能包）。如无需某些语言支持，可注释对应行以减少开销。
zinit ice wait"1" lucid as"null"
zinit for \
  zdharma-continuum/zinit-annex-as-monitor \
  zdharma-continuum/zinit-annex-bin-gem-node \
  zdharma-continuum/zinit-annex-patch-dl \
  zdharma-continuum/zinit-annex-rust

# 使用说明（添加/调整插件）：
# - 典型模式：
#     zinit ice wait"0b" lucid  # 设置加载策略（如延迟加载、静默）
#     zinit light owner/repo    # 轻量拉取插件
# - `wait` 值越小越先尝试加载；可按需要微调加载顺序与速度。
