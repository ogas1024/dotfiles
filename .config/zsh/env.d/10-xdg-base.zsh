# ============================================================================#
# XDG 相关环境变量（集中管理所有“为了 XDG 化”而设置的变量）
# - 本文件只做「路径与文件位置」的约定，不做任何外部命令调用。
# - 设计目标：
#   * 把常见工具散落在各处的点文件统一迁移到 XDG 目录；
#   * 尽量避免在 $HOME 里生成新的“垃圾文件”（history、rc 等）。
# - 修改建议：
#   * 新增加的 XDG 化需求（例如某工具支持 XDG_* 环境变量），请放到本文件；
#   * 与语言/编辑器/区域设置相关的环境变量放到 20-editor-lang.zsh。
# ============================================================================#

# ------------------- XDG Base 目录本身 -------------------
# 若外部已经显式设置 XDG_*，则尊重外部设置；否则给出默认值。
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
export XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME

# ------------------- CLI 工具配置目录 -------------------

# Git / SSH 等已经天然支持 XDG（例如 ~/.config/git/config），无需额外变量。

# Docker：全局配置目录
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"

# npm：全局配置文件位置（行为由 ~/.config/npm/npmrc 决定）
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"

# Wakatime：把 wakatime 的配置与数据库放到 XDG 目录
export WAKATIME_HOME="$XDG_CONFIG_HOME/wakatime"

# Wget：使用 XDG 配置目录，并把 HSTS 缓存放到 ~/.cache
export WGETRC="$XDG_CONFIG_HOME/wget/wgetrc"

# ripgrep：默认配置文件路径（如需定制默认行为，在该文件中设置）
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/ripgreprc"

# pip：统一配置路径（不直接改变 pip 行为，仅指定配置文件位置）
export PIP_CONFIG_FILE="$XDG_CONFIG_HOME/pip/pip.conf"

# Readline：避免使用 ~/.inputrc，改为 XDG 路径（文件可为空）
export INPUTRC="$XDG_CONFIG_HOME/readline/inputrc"

# curl：让 curlrc 位于 XDG
export CURL_HOME="$XDG_CONFIG_HOME/curl"

# ------------------- History / cache 类文件 -------------------

# Python / less 历史：避免在家目录生成痕迹文件
export PYTHONHISTFILE="$XDG_CACHE_HOME/python/history"
export LESSHISTFILE="$XDG_CACHE_HOME/less/history"

# Zsh 历史文件移动到 XDG（避免 ~/.zsh_history）
export HISTFILE="$XDG_STATE_HOME/zsh/history"

# GDB 历史：避免在家目录生成 .gdb_history
export GDBHISTFILE="$XDG_STATE_HOME/gdb/history"

# Node REPL 历史：避免在家目录生成 .node_repl_history
export NODE_REPL_HISTORY="$XDG_STATE_HOME/node/repl_history"

# SQLite 历史记录
export SQLITE_HISTORY="$XDG_STATE_HOME/sqlite/history"

# ------------------- 各语言生态的 XDG 化 -------------------

# Maven：将本地仓库迁移至 XDG 数据目录（JVM 选项），避免使用 ~/.m2/repository。
export MAVEN_OPTS="${MAVEN_OPTS:+$MAVEN_OPTS }-Dmaven.repo.local=$XDG_DATA_HOME/maven/repository"

# Rust / Cargo：将目录迁移到 XDG（已有 .cargo/.rustup 时可手动迁移后再启用）
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
case ":$PATH:" in
  *":$CARGO_HOME/bin:"*) ;;
  *) PATH="$CARGO_HOME/bin:$PATH" ;;
esac

# Go：将 GOPATH/GOCACHE/GOENV 指向 XDG，二进制在 $GOPATH/bin
export GOPATH="$XDG_DATA_HOME/go"
export GOCACHE="$XDG_CACHE_HOME/go-build"
export GOENV="$XDG_CONFIG_HOME/go/env"
case ":$PATH:" in
  *":$GOPATH/bin:"*) ;;
  *) PATH="$GOPATH/bin:$PATH" ;;
esac

# Gradle：用户目录（缓存/包装器）
export GRADLE_USER_HOME="$XDG_DATA_HOME/gradle"

# pipx：把虚拟环境与元数据放到 XDG
export PIPX_HOME="$XDG_DATA_HOME/pipx"
export PIPX_BIN_DIR="$HOME/.local/bin"
case ":$PATH:" in
  *":$PIPX_BIN_DIR:"*) ;;
  *) PATH="$PIPX_BIN_DIR:$PATH" ;;
esac

# npm 全局安装路径：配合 ~/.config/npm/npmrc 使用
case ":$PATH:" in
  *":$XDG_DATA_HOME/npm/bin:"*) ;;
  *) PATH="$XDG_DATA_HOME/npm/bin:$PATH" ;;
esac

export PATH

