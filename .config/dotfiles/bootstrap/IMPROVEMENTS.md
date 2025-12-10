# Dotfiles Bootstrap 改进说明

## 🎨 用户体验改进

### 改进前的问题
- ❌ 提示信息不清晰，全是纯文本
- ❌ 需要输入 10+ 个环境变量（太繁琐）
- ❌ 每一步都要手动输入 y/s/e（效率低）
- ❌ 没有视觉反馈，不知道进度
- ❌ 错误提示不明显
- ❌ 没有非交互模式

### 改进后的优势
- ✅ **彩色输出 + Unicode 图标**：清晰醒目的视觉反馈
- ✅ **智能默认值**：只问 3-5 个关键问题
- ✅ **欢迎 Banner**：专业的启动界面
- ✅ **进度指示**：显示 [1/7]、[2/7] 等进度
- ✅ **非交互模式**：支持 `--yes` 参数自动安装
- ✅ **分层提示**：step → substep → info/success/warn/error
- ✅ **智能检测**：自动检测已安装的组件并跳过

## 📦 新增文件

```
bootstrap/
├── lib/
│   ├── ui.sh          # 🆕 彩色输出和 UI 函数库
│   └── common.sh      # ✨ 改进：使用 UI 库，更清晰的输出
├── bootstrap.sh       # ✨ 完全重构：更友好的交互
└── steps/
    ├── pacman-packages.sh  # ✨ 改进：彩色输出
    ├── dotfiles-checkout.sh # ✨ 简化
    ├── plugins.sh          # ✨ 简化
    ├── secrets.sh          # ✨ 简化
    └── shell-default.sh    # ✨ 简化
```

## 🚀 使用方法

### 交互式安装（推荐首次使用）
```bash
bash ~/.config/dotfiles/bootstrap/bootstrap.sh
```

### 非交互式安装（使用默认配置）
```bash
bash ~/.config/dotfiles/bootstrap/bootstrap.sh --yes
```

### curl 一键安装（在新机器上）
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ogas1024/dotfiles/main/.config/dotfiles/bootstrap/bootstrap.sh)
```

### 自定义安装（环境变量）
```bash
# 同时安装 mihomo 和 fcitx5
MIHOMO_SETUP=1 FCITX5_SETUP=1 bash bootstrap.sh --yes

# 跳过 Neovim 插件同步（节省时间）
INSTALL_NVIM_PLUGINS=0 bash bootstrap.sh

# 使用不同的仓库地址
REPO=git@gitlab.com:yourname/dotfiles.git bash bootstrap.sh
```

## 🎬 视觉效果预览

### 欢迎界面
```
    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║     🚀  Dotfiles Bootstrap - 一键配置你的开发环境        ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝

  [ ℹ ] 即将为你配置以下内容：

   📦 系统软件包（zsh, tmux, nvim, starship 等）
   ⚙  Dotfiles 配置文件（zsh, tmux, nvim 等）
   🔌 插件管理器（zinit, TPM, LazyVim）
   🔒 密钥文件模板

    ────────────────────────────────────────────────────

  [ ℹ ] 检测到发行版：Arch Linux / CachyOS
```

### 步骤执行
```
 ⚙  [1/7] 📦 安装系统软件包

     → 优化 Arch 镜像源
  [ ℹ ] 使用 reflector 更新镜像列表（国家：China）...
       Retrieving latest mirror list...
  [ ✓ ] 镜像源优化完成

     → 升级系统软件包
       Synchronizing package databases...
  [ ✓ ] 系统已升级

     → 安装开发工具和常用软件
  [ ℹ ] 这可能需要几分钟...
  [ ✓ ] 软件包安装完成
```

### 完成界面
```
    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║     ✨  安装完成！享受你的新环境吧！                      ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝

  [ ✓ ] 所有步骤已完成！

  [ ℹ ] 后续步骤：
   1. 重新登录以应用 shell 更改
   2. 首次启动 tmux 时按 Ctrl+b I 安装插件
   3. 编辑 ~/.config/zsh/env.d/90-secrets.zsh 添加密钥

  [ ℹ ] 管理 dotfiles：
   dotfiles status          查看状态
   dotfiles add <file>      添加文件
   dotfiles commit -m "msg"  提交更改
   dotfiles push             推送到远程

  [ ✓ ] 祝你使用愉快！🚀
```

## 🔧 关键改进详解

### 1. UI 函数库 (`lib/ui.sh`)

提供了丰富的输出函数：

```bash
# 基础输出
info "信息提示"        # 蓝色 ℹ
success "成功提示"     # 绿色 ✓
error "错误提示"       # 红色 ✗
warn "警告提示"        # 黄色 ⚠

# 结构化输出
step "主要步骤"        # 大标题，带背景
substep "子步骤"       # 缩进的箭头

# 交互函数
ask_yes "是否继续？"   # 默认 yes 的询问
ask_no "是否跳过？"    # 默认 no 的询问

# 装饰
banner                # 欢迎 banner
finish_banner         # 完成 banner
separator            # 分隔线
```

### 2. 简化的交互流程

**改进前**：需要输入 12 个变量
```bash
REPO [git@github.com:...]:
DOTDIR [/home/user/.dotfiles]:
ZDOTDIR [/home/user/.config/zsh]:
RUN_MIRRORS [1]:
REFLECTOR_COUNTRY [China]:
SET_DEFAULT_SHELL [1]:
INSTALL_NVIM_PLUGINS [1]:
MIHOMO_SETUP [1]:
MIHOMO_CONFIG [...]:
MIHOMO_DOWNLOAD_GEODATA [1]:
MIHOMO_ENABLE_SERVICE [1]:
... 还有更多
```

**改进后**：只问 3-5 个关键问题
```bash
是否继续安装？ [Y/n]
是否优化 Arch 镜像源？ [Y/n]
是否设置 zsh 为默认 shell？ [Y/n]
是否同步 Neovim 插件？ [Y/n]
是否安装 mihomo 代理？ [y/N]
是否安装 fcitx5 输入法？ [y/N]
```

### 3. 智能默认值

```bash
# 常用功能默认启用
SET_DEFAULT_SHELL=1
INSTALL_NVIM_PLUGINS=1
RUN_MIRRORS=1

# 可选功能默认禁用
MIHOMO_SETUP=0
FCITX5_SETUP=0
```

### 4. 非交互模式

```bash
# 使用默认配置快速安装
bash bootstrap.sh --yes

# 或者设置环境变量
NON_INTERACTIVE=1 bash bootstrap.sh
```

## 📝 配置建议

### 日常开发机（完整安装）
```bash
bash bootstrap.sh --yes
```

### 服务器（最小安装，跳过 GUI 相关）
```bash
FCITX5_SETUP=0 MIHOMO_SETUP=0 INSTALL_NVIM_PLUGINS=0 bash bootstrap.sh --yes
```

### 家用 NAS（基础 + 代理）
```bash
MIHOMO_SETUP=1 FCITX5_SETUP=0 bash bootstrap.sh --yes
```

## 🔄 回滚方法

如果遇到问题，可以恢复旧版本：

```bash
cd ~/.config/dotfiles/bootstrap
mv bootstrap.sh bootstrap-improved.sh
mv bootstrap-old.sh.backup bootstrap.sh
```

## 📚 参考

改进灵感来自：
- [holman/dotfiles](https://github.com/holman/dotfiles) - 彩色输出
- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles) - 简洁交互
- [felipecrs/dotfiles](https://github.com/felipecrs/dotfiles) - 智能默认值
