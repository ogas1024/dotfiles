# 示例：本机私密环境变量（勿提交真实值）
# - 复制为 ~/.config/zsh/secrets.zsh，并 chmod 600 仅限本人读取；
# - Git 已忽略 secrets.zsh / secrets.d/*，可安全提交本模板；
# - 如需在仓库中保存加密版，可自行用 age/sops/gpg 生成 secrets.zsh.age 等，
#   解密后放回 secrets.zsh 再启动 shell。

# Bitwarden Session Token（示例占位）
# export BW_SESSION="__fill_from_bw_unlock__"

# 其他密钥示例：
# export GH_TOKEN="ghp_xxx"
# export AWS_PROFILE="personal"
# export DOCKER_CONFIG="$HOME/.docker"
