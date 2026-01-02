#!/usr/bin/env bash
# 步骤：设置默认 Shell
# 重要性：IMPORTANT（重要步骤）
# 依赖：packages, dotfiles

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# ============================================================================
# 步骤描述
# ============================================================================
step_shell_describe() {
  cat << 'EOF'
🐚 默认 Shell 设置

将要执行的操作：
  1. 检查 zsh 是否已安装
  2. 使用 chsh 将默认 shell 设置为 zsh
  3. 验证设置是否成功

为什么选择 zsh：
  • 强大的补全系统
  • 丰富的插件生态（通过 zinit 管理）
  • 更好的交互体验
  • 兼容 bash 语法

风险提示：
  ℹ 需要输入当前用户密码
  ℹ 更改会在下次登录后生效
  ℹ 如果 zsh 配置有问题，可能导致登录后 shell 异常
  💡 可以随时使用 'chsh -s /bin/bash' 切换回 bash

为什么需要这一步：
  我们的配置是为 zsh 设计的，使用 bash 无法获得完整体验
EOF
}

# ============================================================================
# 检查：判断是否需要执行
# ============================================================================
step_shell_check() {
  # 检查当前默认 shell
  local current_shell=$(getent passwd "$USER" | cut -d: -f7)

  if [[ "$current_shell" == *"zsh"* ]]; then
    info "当前默认 shell 已经是 zsh"
    return 0  # 无需执行
  fi

  info "当前默认 shell：$current_shell"
  return 1  # 需要执行
}

# ============================================================================
# 执行：设置默认 shell
# ============================================================================
step_shell_run() {
  local SET_DEFAULT_SHELL="${SET_DEFAULT_SHELL:-1}"

  if [ "$SET_DEFAULT_SHELL" != "1" ]; then
    info "SET_DEFAULT_SHELL=$SET_DEFAULT_SHELL，跳过设置"
    return 0
  fi

  # 检查 zsh 是否存在
  if ! command -v zsh >/dev/null 2>&1; then
    error "zsh 未安装"
    warn "请先运行 packages 步骤安装 zsh"
    return 1
  fi

  local zsh_path=$(command -v zsh)
  substep "找到 zsh：$zsh_path"

  # 检查 zsh 是否在 /etc/shells 中
  if ! grep -q "^$zsh_path$" /etc/shells; then
    warn "$zsh_path 不在 /etc/shells 中"
    substep "添加到 /etc/shells"

    if echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null; then
      success "已添加到 /etc/shells"
    else
      error "添加失败"
      return 1
    fi
  fi

  # 设置默认 shell
  substep "设置 zsh 为默认 shell"
  info "可能需要输入密码..."

  if chsh -s "$zsh_path" 2>&1 | sed 's/^/       /'; then
    success "默认 shell 已设置为 zsh"
  else
    error "chsh 命令失败"
    warn "你可以稍后手动运行：chsh -s $zsh_path"
    return 1
  fi

  return 0
}

# ============================================================================
# 验证：检查是否成功
# ============================================================================
step_shell_verify() {
  local current_shell=$(getent passwd "$USER" | cut -d: -f7)

  if [[ "$current_shell" != *"zsh"* ]]; then
    error "验证失败：默认 shell 仍然是 $current_shell"
    return 1
  fi

  success "验证通过：默认 shell 是 $current_shell"
  return 0
}

# ============================================================================
# 后续提示
# ============================================================================
step_shell_after() {
  info "后续操作："
  echo "  ✓ 默认 shell 已设置为 zsh"
  echo "  → 更改将在下次登录后生效"
  echo ""
  info "立即使用 zsh（不登出）："
  echo "  ${BRIGHT_CYAN}zsh${RESET}"
  echo ""
  warn "注意："
  echo "  • 如果 zsh 启动有问题，可以使用 'bash' 切换回 bash"
  echo "  • 如果需要永久切换回 bash：${BRIGHT_CYAN}chsh -s /bin/bash${RESET}"
}

# ============================================================================
# 主入口
# ============================================================================
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  source "$SCRIPT_DIR/lib/steps.sh"
  step_execute "shell"
fi
