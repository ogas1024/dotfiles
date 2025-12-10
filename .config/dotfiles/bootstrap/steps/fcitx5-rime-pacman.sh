#!/usr/bin/env bash
# Arch/CachyOS：安装配置 fcitx5 + rime-ice，写入环境变量
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

echo "[fcitx5-rime][pacman] 安装 fcitx5 与组件"
sudo pacman -Syu --noconfirm
sudo pacman -Sy --noconfirm --needed \
  fcitx5 fcitx5-configtool fcitx5-gtk fcitx5-qt fcitx5-rime fcitx5-material-color

echo "[fcitx5-rime][pacman] 安装 rime-ice（paru）"
if need paru; then
  paru -S --needed --noconfirm rime-ice-git
else
  echo "ERROR: 需要 paru 安装 rime-ice-git" >&2
  exit 1
fi

echo "[fcitx5-rime][pacman] 写入 /etc/environment 输入法环境变量（追加/覆盖同名键）"
tmp_env="$(mktemp)"
sudo cp /etc/environment "$tmp_env" 2>/dev/null || true

ensure_key() {
  local key="$1" val="$2"
  if grep -q "^${key}=" "$tmp_env"; then
    sudo sed -i "s|^${key}=.*|${key}=${val}|" "$tmp_env"
  else
    echo "${key}=${val}" | sudo tee -a "$tmp_env" >/dev/null
  fi
}
ensure_key GTK_IM_MODULE fcitx
ensure_key QT_IM_MODULE fcitx
ensure_key XMODIFIERS "@im=fcitx"
ensure_key INPUT_METHOD fcitx
ensure_key SDL_IM_MODULE fcitx
ensure_key GLFW_IM_MODULE fcitx
sudo install -m644 "$tmp_env" /etc/environment
rm -f "$tmp_env"

echo "[fcitx5-rime][pacman] 准备用户 rime 配置目录并写入 default.custom.yaml"
mkdir -p "$HOME/.local/share/fcitx5/rime"
cat >"$HOME/.local/share/fcitx5/rime/default.custom.yaml" <<'YAML'
patch:
  __include: rime_ice_suggestion:/
  __patch:
    key_binder/bindings/+:
      - { when: paging, accept: comma, send: Page_Up }
      - { when: has_menu, accept: period, send: Page_Down }
    menu/page_size: 10
YAML

echo "[fcitx5-rime][pacman] 完成。请手动操作："
echo "1) 重新登录或重启（让 /etc/environment 生效）"
echo "2) 首次启动 Fcitx5，让 rime 生成数据；如需手动部署：rime_deployer 或 fcitx5 -r"
echo "3) 在 Fcitx5 配置工具中添加 Rime 输入法"
