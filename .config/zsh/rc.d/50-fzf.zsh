# ------------------- FZF 默认参数（全局生效） -------------------
# 说明：
# - 统一设置样式与交互（反向列表、右侧预览、指针/标记符号等）。
# - 可以按需修改 --height、--color、--prompt 等配置。
export FZF_DEFAULT_OPTS="\
--ansi \
--layout=reverse \
--info=inline \
--height=50% \
--multi \
--cycle \
--preview-window=right:50% \
--preview-window=cycle \
--prompt=\"λ -> \" \
--pointer=\"▷\" \
--marker=\"✓\" \
--color=bg+:236,gutter:-1,fg:-1,bg:-1,hl:-1,hl+:-1,prompt:-1,pointer:105,marker:-1,spinner:-1\
"

# 默认搜索命令：fd 更快；如果没有 fd，可改为 `rg --files` 或 `find . -type f`。
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

# Ctrl-T 调用同样的文件源；Alt-C 用于目录跳转。
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
