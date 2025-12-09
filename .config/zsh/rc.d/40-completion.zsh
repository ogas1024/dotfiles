# ------------------- 补全系统（统一初始化） -------------------
# zstyle：
# - completer：设定补全函数执行顺序（先展开、再补全、忽略列表）。
# - matcher-list：大小写不敏感匹配（如 gC == gcc）。
# - list-colors：复用 LS_COLORS 为补全上色。
# - menu no：默认不开启菜单模式（避免与 fzf-tab 冲突）。
# - squeeze-slashes：将多重 // 视为单个 /，增强路径补全鲁棒性。
# - special-dirs：在路径补全中显示 . 与 ..
zstyle ':completion:*' completer _expand _complete _ignored
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' special-dirs true

# 仅初始化一次补全（借助 zinit 提供的加速封装）
zicompinit
zicdreplay
