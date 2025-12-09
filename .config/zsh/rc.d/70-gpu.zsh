# ------------------- GPU & CUDA（可选模块） -------------------
# 说明：
# - 默认关闭（if false）。如需启用，把 false 改为 true。
# - 提供 PATH/LD_LIBRARY_PATH 注入与 CUDA 版本快速切换函数。
if true; then
  case ":$PATH:" in
    *:"/usr/local/cuda/bin":*) ;;
    *) export PATH="/usr/local/cuda/bin:$PATH" ;;
  esac

  case ":$LD_LIBRARY_PATH:" in
    *:"/usr/local/cuda/lib64":*) ;;
    *) export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH" ;;
  esac

  # 切换 CUDA 版本：使用系统已有 /usr/local/cuda-<ver> 目录。
  switch_cuda() {
    if [ -z "$1" ]; then
      echo "错误: 请提供一个CUDA版本号. 用法: switch_cuda 11.8"
      return 1
    fi
    local target_path="/usr/local/cuda-$1"
    if [ ! -d "$target_path" ]; then
      echo "错误: 找不到CUDA版本 $1. 请确认目录 ${target_path} 是否存在."
      return 1
    fi
    echo "正在将CUDA版本切换到 $1 ..."
    sudo ln -sfn "$target_path" /usr/local/cuda
    echo "切换完成. 当前 nvcc 版本:"
    nvcc --version
  }
fi
