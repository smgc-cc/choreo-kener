#!/bin/sh
set -e

# 环境变量配置与默认值
KOMARI_SERVER="${KOMARI_SERVER:-}"
KOMARI_SECRET="${KOMARI_SECRET:-}"

# 1. 启动 komari-agent
if [ -n "$KOMARI_SERVER" ] && [ -n "$KOMARI_SECRET" ]; then
    echo "[Komari] 启动监控..."
    /app/komari-agent -e "$KOMARI_SERVER" -t "$KOMARI_SECRET" --disable-auto-update >/dev/null 2>&1 &
else
    echo "[Komari] 未配置，跳过。"
fi

# 2. 因为 /tmp 是易失的（重启即空），每次启动必须重建目录
mkdir -p /tmp/database /tmp/uploads

# 3. 赋予当前用户（10014）写入权限
chmod 755 /tmp/database /tmp/uploads

# 4. 打印日志方便调试（可选）
echo "✅ Choreo environment prepared: /tmp directories created."

# 5. 将控制权移交给 Kener 原有的启动脚本
# 使用 exec 确保进程 ID 不变，能够正确响应关闭信号
exec /app/entrypoint.sh "$@"
