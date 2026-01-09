# ------------------- 常用别名与小函数 -------------------
# 提示：
# - 你可以在这里追加/覆盖别名，文件会在最后被加载；
# - 自定义函数本体已迁移到 $ZDOTDIR/functions/ 目录，本文件只保留 alias。

alias l="eza --icons --long --header"
alias ls="eza --icons --grid"
alias ll="eza --icons --long --header"
alias la="eza --icons --long --header --all"
alias lg="eza --icons --long --header --all --git"
alias tree="eza --icons --tree -L1"
alias man="tldr"
alias mkdir='mkdir -p'
alias df="duf -style unicode -hide-mp '/run/credentials/*'"
alias top="bpytop"
alias nvidia-smi="watch -n 3 -c nvidia-smi"
alias x="unar"
alias ff="fastfetch"  # 快速显示 fastfetch
alias bw="flatpak run --command=bw com.bitwarden.desktop" # bitwarden-cli
alias vim="nvim"

# 只有在 macOS 下，且安装了 7zz 时，才建立这个别名
if [[ "$(uname -s)" == "Darwin" ]] && command -v 7zz >/dev/null 2>&1; then
    alias 7z='7zz'
fi

alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME' # 使用 git bare repo 管理 dotfiles

# Zsh 启动模式快捷命令：
# - 默认情况下，shell 以“轻量模式”（OGAS_DEV_TOOLS=0）启动，不加载重型开发工具；
# - 需要完整开发环境时，可以通过下列 alias 打开新的交互 shell：
#     zsh-dev   ：以 OGAS_DEV_TOOLS=1 启动 zsh -i（加载 mise / conda 等）；
#     zsh-lite  ：显式以轻量模式启动 zsh -i（方便在重型 shell 中再开一个轻量子 shell）。
alias zsh-dev='OGAS_DEV_TOOLS=1 zsh -i'
alias zsh-lite='OGAS_DEV_TOOLS=0 zsh -i'
