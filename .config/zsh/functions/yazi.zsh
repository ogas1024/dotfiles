# ============================================================================#
# yazi 集成：命令 `y`，退出后自动 cd 到 yazi 最后所在目录
# - 用法：
#   * 在交互式 shell 中执行 `y` 打开 yazi；
#   * 传参透传给 yazi（例如 y ~/Downloads）。
# ============================================================================#

if command -v yazi >/dev/null 2>&1; then
  y() {
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
  }
else
  # 未安装 yazi 时给出友好提示，避免误用。
  y() { echo "未检测到 yazi，请先安装后再使用 y 函数。" >&2; return 127; }
fi

