# ==========================================
# 阶段 1: 构建阶段 (Builder)
# ==========================================
FROM golang:alpine AS builder

WORKDIR /src

# 安装 git
RUN apk add --no-cache git

# 1. 拉取源码
RUN git clone https://github.com/komari-monitor/komari-agent.git .

# 2. 检出最新的 Tag
RUN git fetch --tags && \
    LATEST_TAG=$(git describe --tags --abbrev=0) && \
    git checkout $LATEST_TAG

# 3. 编译并注入版本号
RUN VERSION=$(git describe --tags --always) && \
    echo "--------------------------------------" && \
    echo "正在构建版本: $VERSION" && \
    echo "--------------------------------------" && \
    go mod download && \
    CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags="-s -w -X github.com/komari-monitor/komari-agent/update.CurrentVersion=${VERSION}" \
    -o komari-agent .

# ==========================================
# 第二阶段：运行环境 (Final Image)
# 基于 kener:latest
# ==========================================
FROM rajnandan1/kener:latest

USER root

# 1. 复制 wrapper 脚本
COPY choreo-wrapper.sh /app/choreo-wrapper.sh

# 2. 执行系统改造 + 深度安全修复
RUN chmod +x /app/choreo-wrapper.sh && \
    # -----------------------------------------------------------------
    # [Choreo 适配] 解决只读文件系统问题
    # -----------------------------------------------------------------
    rm -rf /app/database /app/uploads && \
    ln -s /tmp/database /app/database && \
    ln -s /tmp/uploads /app/uploads && \
    # -----------------------------------------------------------------
    # [安全修复] 1. 修复 Debian 系统漏洞 (CVE-2025-6965)
    # -----------------------------------------------------------------
    apt-get update && \
    apt-get install -y --only-upgrade libsqlite3-0 sqlite3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # -----------------------------------------------------------------
    # [安全修复] 2. 深度修复 Node.js 嵌套依赖漏洞 (重点修改部分)
    # -----------------------------------------------------------------
    # A. 修复 form-data 漏洞
    npm install form-data@4.0.4 && \
    # B. 修复 esbuild 漏洞 (CVE-2024-24790)
    # 使用 overrides 强制所有依赖（包括 vite）都使用最新版 esbuild
    # 这会消除 node_modules/vite/node_modules/... 下的旧版本
    npm pkg set overrides.esbuild="^0.24.2" && \
    npm pkg set overrides.@esbuild/linux-x64="^0.24.2" && \
    # C. 应用更改
    # 删除 lock 文件以强制重新计算依赖树
    rm -f package-lock.json && \
    # 重新安装，npm 现在会把所有 esbuild 统一升级到 0.24.2
    npm install && \
    # D. 双重保险：物理删除任何可能残留的旧版二进制文件
    # 如果 npm install 没清理干净，这里直接手动删除嵌套的 esbuild 文件夹
    rm -rf node_modules/vite/node_modules/@esbuild && \
    # 清理缓存减小体积
    npm cache clean --force

# 3. 从其他镜像复制必要的二进制文件
COPY --from=builder /src/komari-agent /app/komari-agent

USER 10014

ENTRYPOINT ["/app/choreo-wrapper.sh"]

CMD ["node", "main"]
