# ------------------- Maven XDG 集成 -------------------
# 目标：
# - 本地仓库：使用 $XDG_DATA_HOME/maven/repository（已在 MAVEN_OPTS 中设置）
# - 配置文件：优先使用 $XDG_CONFIG_HOME/maven/settings.xml（通过 -gs 注入）

_ogas_maven_settings="$XDG_CONFIG_HOME/maven/settings.xml"
if [ -r "$_ogas_maven_settings" ]; then
  # 仅在交互式环境覆盖 mvn 命令，确保脚本/非交互用法不受影响
  mvn() {
    command mvn -gs "$_ogas_maven_settings" "$@"
  }
fi

