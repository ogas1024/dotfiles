# ------------------- 常用 zsh 选项（交互体验） -------------------
# AUTO_CD：输入目录名直接 cd 过去（省略 cd 命令）。
# AUTO_PUSHD/PUSHD_*：使用 cd 时维护目录栈，便于在目录间来回跳转（pushd/popd/dirs）。
setopt AUTO_CD AUTO_PUSHD PUSHD_SILENT PUSHD_IGNORE_DUPS

# 交互友好：允许 # 之后是注释；关闭蜂鸣；历史执行前先回显确认。
setopt INTERACTIVE_COMMENTS NO_BEEP
setopt HIST_VERIFY

# 实时追加历史到文件（而非退出时一次性写入），便于多会话共享历史。
setopt INC_APPEND_HISTORY
