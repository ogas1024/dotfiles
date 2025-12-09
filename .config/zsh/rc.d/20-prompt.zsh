# ------------------- 提示符（Starship） -------------------
# 说明：仅在系统存在 starship 时启用，避免多余的子进程与报错。
# 自定义外观：编辑 ~/.config/starship.toml
# - 可关闭不常用模块、降低 command_timeout 提升性能。
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh --print-full-init)"
fi
