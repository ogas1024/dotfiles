# ------------------- fzf-tab 样式与行为 -------------------
# 基础：复用 FZF_DEFAULT_OPTS（见 50-fzf.zsh）。
zstyle ':fzf-tab:*' use-fzf-default-opts yes

# 目录类补全：右侧预览目录（使用 eza，可替换为 `ls -la --color=always`）。
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --icons -1 --color=always $realpath'
zstyle ':fzf-tab:complete:cd:*' popup-pad 30 0
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --icons -1 --color=always $realpath'
zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza --icons -1 --color=always $realpath'

# 进程类补全：下方面板显示命令行（可改为 `pstree -ap $word` 之类）。
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags '--preview-window=down:3:wrap'
zstyle ':fzf-tab:complete:kill:*' popup-pad 0 3

# 快捷键：切换分组与快速接受当前项。
zstyle ':fzf-tab:*' fzf-bindings '`:accept'
zstyle ':fzf-tab:*' switch-group '<' '>'
