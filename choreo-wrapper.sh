#!/bin/sh
set -e

# 1. 因为 /tmp 是易失的（重启即空），每次启动必须重建目录
mkdir -p /tmp/database /tmp/uploads

# 2. 赋予当前用户（10014）写入权限
chmod 755 /tmp/database /tmp/uploads

# 3. 打印日志方便调试（可选）
echo "✅ Choreo environment prepared: /tmp directories created."

# 4. 将控制权移交给 Kener 原有的启动脚本
# 使用 exec 确保进程 ID 不变，能够正确响应关闭信号
exec /app/entrypoint.sh "$@"
