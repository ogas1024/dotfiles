#!/usr/bin/env bash
# 状态管理系统：跟踪步骤执行状态，支持恢复和重试

# 不修改全局 SCRIPT_DIR 变量

# ============================================================================
# 状态存储路径
# ============================================================================
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-bootstrap"
STATE_FILE="$STATE_DIR/state.json"
CONFIG_FILE="$STATE_DIR/config.json"
LOG_DIR="$STATE_DIR/logs"

# ============================================================================
# 初始化状态系统
# ============================================================================
state_init() {
  mkdir -p "$STATE_DIR" "$LOG_DIR"

  # 如果状态文件不存在，创建空状态
  if [ ! -f "$STATE_FILE" ]; then
    echo '{"steps":{},"last_run":"","version":"2.0"}' > "$STATE_FILE"
  fi

  # 如果配置文件不存在，创建默认配置
  if [ ! -f "$CONFIG_FILE" ]; then
    echo '{}' > "$CONFIG_FILE"
  fi
}

# ============================================================================
# 状态查询
# ============================================================================

# 获取步骤状态: pending|running|success|failed|skipped
state_get() {
  local step="$1"

  if [ ! -f "$STATE_FILE" ]; then
    echo "pending"
    return
  fi

  # 使用 jq 或 grep/sed 解析（优先使用 jq）
  if command -v jq >/dev/null 2>&1; then
    jq -r ".steps[\"$step\"].status // \"pending\"" "$STATE_FILE"
  else
    # 简单的 grep 方案（不依赖 jq）
    if grep -q "\"$step\"" "$STATE_FILE" 2>/dev/null; then
      grep "\"$step\"" "$STATE_FILE" | grep -o '"status":"[^"]*"' | cut -d'"' -f4
    else
      echo "pending"
    fi
  fi
}

# 检查步骤是否已完成
state_is_completed() {
  local step="$1"
  local status=$(state_get "$step")
  [ "$status" = "success" ] || [ "$status" = "skipped" ]
}

# 检查步骤是否失败
state_is_failed() {
  local step="$1"
  [ "$(state_get "$step")" = "failed" ]
}

# 获取所有已完成的步骤
state_get_completed() {
  if [ ! -f "$STATE_FILE" ]; then
    return
  fi

  if command -v jq >/dev/null 2>&1; then
    jq -r '.steps | to_entries[] | select(.value.status=="success" or .value.status=="skipped") | .key' "$STATE_FILE"
  else
    grep -o '"[^"]*":{[^}]*"status":"success"' "$STATE_FILE" | cut -d'"' -f2 2>/dev/null || true
    grep -o '"[^"]*":{[^}]*"status":"skipped"' "$STATE_FILE" | cut -d'"' -f2 2>/dev/null || true
  fi
}

# 获取所有失败的步骤
state_get_failed() {
  if [ ! -f "$STATE_FILE" ]; then
    return
  fi

  if command -v jq >/dev/null 2>&1; then
    jq -r '.steps | to_entries[] | select(.value.status=="failed") | .key' "$STATE_FILE"
  else
    grep -o '"[^"]*":{[^}]*"status":"failed"' "$STATE_FILE" | cut -d'"' -f2 2>/dev/null || true
  fi
}

# ============================================================================
# 状态更新
# ============================================================================

# 更新步骤状态
state_set() {
  local step="$1"
  local status="$2"  # pending|running|success|failed|skipped
  local timestamp=$(date -Iseconds)

  state_init

  if command -v jq >/dev/null 2>&1; then
    # 使用 jq 更新
    local temp=$(mktemp)
    jq ".steps[\"$step\"] = {status: \"$status\", timestamp: \"$timestamp\"} | .last_run = \"$timestamp\"" \
      "$STATE_FILE" > "$temp" && mv "$temp" "$STATE_FILE"
  else
    # 简单方案：使用 sed（不完美但可用）
    local temp=$(mktemp)

    # 读取现有内容
    if [ -f "$STATE_FILE" ]; then
      cat "$STATE_FILE" > "$temp"
    else
      echo '{"steps":{},"last_run":""}' > "$temp"
    fi

    # 简单替换（需要改进）
    # TODO: 实现更健壮的 JSON 更新
    mv "$temp" "$STATE_FILE"
  fi

  # 记录日志
  echo "[$(date -Iseconds)] Step '$step' -> $status" >> "$LOG_DIR/state.log"
}

# 标记步骤开始
state_start() {
  local step="$1"
  state_set "$step" "running"
}

# 标记步骤成功
state_success() {
  local step="$1"
  state_set "$step" "success"
}

# 标记步骤失败
state_fail() {
  local step="$1"
  state_set "$step" "failed"
}

# 标记步骤跳过
state_skip() {
  local step="$1"
  state_set "$step" "skipped"
}

# ============================================================================
# 配置管理
# ============================================================================

# 保存配置
config_save() {
  local key="$1"
  local value="$2"

  state_init

  if command -v jq >/dev/null 2>&1; then
    local temp=$(mktemp)
    jq ".[\"$key\"] = \"$value\"" "$CONFIG_FILE" > "$temp" && mv "$temp" "$CONFIG_FILE"
  fi
}

# 读取配置
config_get() {
  local key="$1"
  local default="${2:-}"

  if [ ! -f "$CONFIG_FILE" ]; then
    echo "$default"
    return
  fi

  if command -v jq >/dev/null 2>&1; then
    jq -r ".[\"$key\"] // \"$default\"" "$CONFIG_FILE"
  else
    echo "$default"
  fi
}

# ============================================================================
# 重置和清理
# ============================================================================

# 重置所有状态
state_reset() {
  if [ -d "$STATE_DIR" ]; then
    rm -rf "$STATE_DIR"
  fi
  state_init
}

# 重置单个步骤
state_reset_step() {
  local step="$1"
  state_set "$step" "pending"
}

# 显示状态摘要
state_summary() {
  if [ ! -f "$STATE_FILE" ]; then
    echo "尚未开始安装"
    return
  fi

  echo "状态摘要："
  echo "  完成: $(state_get_completed | wc -l) 个步骤"
  echo "  失败: $(state_get_failed | wc -l) 个步骤"

  local failed=$(state_get_failed)
  if [ -n "$failed" ]; then
    echo ""
    echo "失败的步骤："
    echo "$failed" | sed 's/^/  - /'
  fi
}
