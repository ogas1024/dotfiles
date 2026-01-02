#!/usr/bin/env bash
# 步骤框架：定义步骤接口和执行逻辑

# 加载依赖（如果还没加载）
if ! declare -f info >/dev/null 2>&1; then
  LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$LIB_DIR/ui.sh"
  source "$LIB_DIR/state.sh"
fi

# ============================================================================
# 步骤定义
# ============================================================================

# 步骤元数据
declare -A STEP_INFO=(
  # 格式：[步骤名]="显示名称|重要性|依赖步骤"
  [packages]="系统软件包|CRITICAL|"
  [dotfiles]="Dotfiles配置|CRITICAL|packages"
  [secrets]="密钥文件|OPTIONAL|dotfiles"
  [shell]="默认Shell|IMPORTANT|packages,dotfiles"
  [plugins]="插件管理器|IMPORTANT|dotfiles,shell"
  [mihomo]="Mihomo代理|OPTIONAL|packages"
  [fcitx5]="Fcitx5输入法|OPTIONAL|packages"
  [fonts]="字体安装|OPTIONAL|packages"
)

# 重要性级别说明
# CRITICAL:  必须成功，失败则停止整个安装
# IMPORTANT: 应该成功，失败提示用户但可以选择继续
# OPTIONAL:  可选功能，失败可忽略

# ============================================================================
# 步骤信息获取
# ============================================================================

step_get_name() {
  local step="$1"
  echo "${STEP_INFO[$step]}" | cut -d'|' -f1
}

step_get_importance() {
  local step="$1"
  echo "${STEP_INFO[$step]}" | cut -d'|' -f2
}

step_get_deps() {
  local step="$1"
  echo "${STEP_INFO[$step]}" | cut -d'|' -f3
}

# ============================================================================
# 依赖检查
# ============================================================================

# 检查步骤的依赖是否满足
step_check_deps() {
  local step="$1"
  local deps=$(step_get_deps "$step")

  if [ -z "$deps" ]; then
    return 0  # 无依赖
  fi

  local failed_deps=()
  IFS=',' read -ra DEP_ARRAY <<< "$deps"
  for dep in "${DEP_ARRAY[@]}"; do
    if ! state_is_completed "$dep"; then
      failed_deps+=("$dep")
    fi
  done

  if [ ${#failed_deps[@]} -gt 0 ]; then
    error "步骤 '$step' 的依赖未满足："
    for dep in "${failed_deps[@]}"; do
      warn "  - $dep (状态: $(state_get "$dep"))"
    done
    return 1
  fi

  return 0
}

# ============================================================================
# 步骤执行框架
# ============================================================================

# 执行单个步骤
# 参数：
#   $1: 步骤名
#   $2: 是否强制重新执行（force）
step_execute() {
  local step="$1"
  local force="${2:-no}"
  local step_name=$(step_get_name "$step")
  local importance=$(step_get_importance "$step")
  local step_script="$SCRIPT_DIR/../steps/${step}.sh"

  # 获取日志文件
  local log_file="$LOG_DIR/${step}.log"

  # ========================================
  # 1. 检查是否已完成
  # ========================================
  if [ "$force" != "force" ] && state_is_completed "$step"; then
    info "步骤 '$step_name' 已完成，跳过"
    return 0
  fi

  # ========================================
  # 2. 检查依赖
  # ========================================
  if ! step_check_deps "$step"; then
    error "无法执行步骤 '$step_name'：依赖未满足"
    state_fail "$step"
    return 1
  fi

  # ========================================
  # 3. 调用步骤的 describe 函数（如果存在）
  # ========================================
  if declare -f "step_${step}_describe" >/dev/null 2>&1; then
    echo ""
    separator
    info "关于步骤：$step_name"
    echo ""
    "step_${step}_describe"
    echo ""
    separator
  fi

  # ========================================
  # 4. 询问用户是否执行
  # ========================================
  if [ "${NON_INTERACTIVE:-0}" != "1" ]; then
    local default_answer="yes"

    # 可选步骤默认询问
    if [ "$importance" = "OPTIONAL" ]; then
      if ! ask_yes "是否执行此步骤？"; then
        state_skip "$step"
        info "已跳过步骤：$step_name"
        return 0
      fi
    else
      # 关键步骤只需确认
      echo ""
      if ! ask_yes "准备执行：$step_name，继续？"; then
        warn "用户取消"
        return 1
      fi
    fi
  fi

  # ========================================
  # 5. 检查是否需要执行（check 函数）
  # ========================================
  echo ""
  step "执行步骤：$step_name"

  if declare -f "step_${step}_check" >/dev/null 2>&1; then
    substep "检查是否需要执行..."
    if "step_${step}_check"; then
      success "$step_name 无需执行（已满足条件）"
      state_skip "$step"
      return 0
    fi
  fi

  # ========================================
  # 6. 标记开始执行
  # ========================================
  state_start "$step"

  # ========================================
  # 7. 执行步骤
  # ========================================
  substep "开始执行..."

  local exit_code=0

  # 调用步骤脚本或函数
  if declare -f "step_${step}_run" >/dev/null 2>&1; then
    # 使用函数
    if ! "step_${step}_run" 2>&1 | tee "$log_file"; then
      exit_code=${PIPESTATUS[0]}
    fi
  elif [ -f "$step_script" ]; then
    # 使用外部脚本
    if ! bash "$step_script" 2>&1 | tee "$log_file"; then
      exit_code=${PIPESTATUS[0]}
    fi
  else
    error "步骤 '$step' 未定义（缺少函数或脚本）"
    exit_code=1
  fi

  # ========================================
  # 8. 检查执行结果
  # ========================================
  if [ $exit_code -ne 0 ]; then
    error "步骤 '$step_name' 执行失败（退出码：$exit_code）"
    warn "日志文件：$log_file"
    state_fail "$step"

    # 根据重要性决定是否继续
    if [ "$importance" = "CRITICAL" ]; then
      error "这是关键步骤，必须成功才能继续"
      return 1
    elif [ "$importance" = "IMPORTANT" ]; then
      warn "这是重要步骤，建议解决后重试"
      if [ "${NON_INTERACTIVE:-0}" != "1" ]; then
        if ! ask_no "是否忽略错误继续？"; then
          return 1
        fi
      else
        return 1
      fi
    else
      warn "这是可选步骤，将继续执行"
    fi

    return 0
  fi

  # ========================================
  # 9. 验证步骤结果（verify 函数）
  # ========================================
  if declare -f "step_${step}_verify" >/dev/null 2>&1; then
    substep "验证执行结果..."
    if ! "step_${step}_verify"; then
      error "步骤 '$step_name' 验证失败"
      state_fail "$step"
      return 1
    fi
  fi

  # ========================================
  # 10. 标记成功
  # ========================================
  success "步骤 '$step_name' 完成"
  state_success "$step"

  # 调用后续提示（如果存在）
  if declare -f "step_${step}_after" >/dev/null 2>&1; then
    echo ""
    "step_${step}_after"
  fi

  return 0
}

# ============================================================================
# 批量执行步骤
# ============================================================================

# 执行步骤列表
steps_execute_list() {
  local steps=("$@")
  local failed_steps=()

  for step in "${steps[@]}"; do
    if ! step_execute "$step"; then
      failed_steps+=("$step")

      # 如果是关键步骤失败，停止
      local importance=$(step_get_importance "$step")
      if [ "$importance" = "CRITICAL" ]; then
        error "关键步骤失败，停止安装"
        break
      fi
    fi
  done

  # 显示摘要
  echo ""
  separator
  if [ ${#failed_steps[@]} -eq 0 ]; then
    success "所有步骤完成！"
    return 0
  else
    warn "以下步骤失败："
    for step in "${failed_steps[@]}"; do
      echo "  - $(step_get_name "$step")"
    done
    return 1
  fi
}

# ============================================================================
# 恢复失败的步骤
# ============================================================================

# 重试所有失败的步骤
steps_retry_failed() {
  local failed=$(state_get_failed)

  if [ -z "$failed" ]; then
    info "没有失败的步骤需要重试"
    return 0
  fi

  info "将重试以下失败的步骤："
  echo "$failed" | sed 's/^/  - /'
  echo ""

  if [ "${NON_INTERACTIVE:-0}" != "1" ]; then
    if ! ask_yes "是否继续？"; then
      return 0
    fi
  fi

  # 转换为数组并执行
  local failed_array=()
  while IFS= read -r step; do
    failed_array+=("$step")
  done <<< "$failed"

  steps_execute_list "${failed_array[@]}"
}
