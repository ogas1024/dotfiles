# ============================================================================#
# 代理相关函数（proxy_on / proxy_off / proxy_status）
# - 用法示例：
#   * 手动开启：  proxy_on             # 使用默认端口 7890
#   * 自定义端口：proxy_on http://127.0.0.1:1080 socks5h://127.0.0.1:1080
#   * 查看状态：  proxy_status
#   * 关闭：      proxy_off
# ============================================================================#

proxy_on() {
  local http_proxy_url="${1:-http://127.0.0.1:7890}"
  local all_proxy_url="${2:-socks5h://127.0.0.1:7890}"
  local no_proxy_list="${3:-localhost,127.0.0.1,::1,.local}"

  export http_proxy="$http_proxy_url"
  export https_proxy="$http_proxy_url"
  export all_proxy="$all_proxy_url"
  export no_proxy="$no_proxy_list"
  export HTTP_PROXY="$http_proxy_url"
  export HTTPS_PROXY="$http_proxy_url"
  export ALL_PROXY="$all_proxy_url"
  export NO_PROXY="$no_proxy_list"
  echo "Proxy ON -> $http_proxy_url"
}

proxy_off() {
  unset http_proxy https_proxy all_proxy no_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY
  echo "Proxy OFF"
}

proxy_status() {
  env | grep -i '^.*_proxy=' || echo "No proxy env set"
}

