# ------------------- 核心插件（zinit Turbo 懒加载） -------------------
# 说明：
# - 通过 zinit 的 wait"X" 选项，将插件加载延迟到首个 prompt 之后；
# - 越大的 wait 值越晚执行，减小对启动时间的影响；
# - 使用 light-mode 可以减少元数据检查，进一步降低开销。

# 1) 补全增强：zsh-completions
# - blockf 阻止其内部触发 compinit，由 40-completion.zsh 统一初始化。
# - 使用字母型 wait 值（0a、0b…），避免潜在的小数解析问题。
zinit ice wait"0a" lucid blockf
zinit light zsh-users/zsh-completions

# 2) fzf-tab：使用 fzf 交互选择补全项（样式见 45-fzf-tab.zsh）。
zinit ice wait"0b" lucid
zinit light Aloxaf/fzf-tab

# 3) 自动建议：zsh-autosuggestions
# - atload 中启动建议功能，并绑定 ` 键快速接受建议。
zinit ice wait"0c" lucid atload'_zsh_autosuggest_start; bindkey "\`" autosuggest-accept'
zinit light zsh-users/zsh-autosuggestions

# 4) 语法高亮：fast-syntax-highlighting
zinit ice wait"0d" lucid
zinit light zdharma-continuum/fast-syntax-highlighting

# 5) Vim 风格按键：zsh-vi-mode
# - 必须放在 autosuggestions 和 syntax-highlighting 之后；
# - 这里使用略大的 wait，保证加载顺序正确。
zinit ice wait"0e" depth=1 lucid
zinit light jeffreytse/zsh-vi-mode

# 6) 历史管理：atuin（可选）
# - 目前通过官方二进制的 `atuin init zsh` 初始化；
# - 这里暂不通过 zinit 管理（官方仓库主要是 Rust 项目本体，不是 zsh 插件）。
if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh)"
fi

# 7) 智能 cd：zoxide（可选）
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# 提示：
# - 停用某插件：注释对应两行（ice/light 或 eval）；
# - 调整加载先后：修改 wait"X" 的值（例如从 0c 改为 0f）；
# - 如插件对启动时间影响仍然明显，可考虑用条件变量包裹（例如只在特定机器开启）。
