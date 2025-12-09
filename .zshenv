# ============================================================================#
# 最小化的 Zsh 环境文件（务必保持精简）
# - 所有 zsh 实例（交互式与非交互式）都会读取此文件；
# - 只做两件事：
#   1) 把 Zsh 的配置目录从 $HOME 重定向到 XDG 目录（ZDOTDIR）；
#   2) 提供一个开关变量 OGAS_DEV_TOOLS，并统一加载 env.d 下的纯环境变量。
# - 请避免在此文件中调用外部命令（git / mise / conda / starship 等），
#   以免影响非交互式脚本的行为与性能。
# ============================================================================#

# 将 Zsh 配置目录指向 XDG 位置（默认为 ~/.config/zsh）
# - 如需改到其它目录，修改下方路径即可；
# - 临时恢复传统行为：启动时用 `ZDOTDIR=$HOME zsh`。
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

# 控制是否加载“重型开发工具”模块（rc.d/55-devtools.zsh）：
# - 默认：0（轻量模式，不自动注入 mise / conda 等）；
# - 完整开发 shell：
#     OGAS_DEV_TOOLS=1 zsh -i
export OGAS_DEV_TOOLS="${OGAS_DEV_TOOLS:-0}"

# 统一加载 env.d 下的纯环境变量片段：
# - 本目录约定只包含「export / 赋值」等轻量操作，不调用外部命令；
# - 这样既能让脚本模式受益于相同的环境配置，又不至于拖慢启动。
if [ -d "$ZDOTDIR/env.d" ]; then
  for f in "$ZDOTDIR"/env.d/*.zsh; do
    [ -r "$f" ] && . "$f"
  done
fi
