FROM rajnandan1/kener:latest

USER root

# 1. 复制 wrapper 脚本
COPY choreo-wrapper.sh /app/choreo-wrapper.sh

# 2. 执行系统改造 + 安全修复
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
    # [安全修复] 2. 修复 Node.js 依赖漏洞
    # -----------------------------------------------------------------
    # 修复 form-data (CVE-2025-7783)
    npm install form-data@4.0.4 && \
    # 修复 esbuild (CVE-2024-24790): 
    # 强制安装最新版 esbuild 主包，它会自动依赖最新版的 @esbuild/linux-x64
    # 这能解决嵌套依赖导致的漏洞残留
    npm install esbuild@latest

USER 10014

ENTRYPOINT ["/app/choreo-wrapper.sh"]

CMD ["node", "main"]
