FROM rajnandan1/kener:latest

USER root

# 1. 复制 wrapper 脚本
COPY choreo-wrapper.sh /app/choreo-wrapper.sh

# 2. 执行系统改造 + 安全修复
# 注意：我们将所有操作合并在一个 RUN 中以减少镜像层数
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
    # 清理缓存减小体积
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # -----------------------------------------------------------------
    # [安全修复] 2. 修复 Node.js 依赖漏洞
    # -----------------------------------------------------------------
    # 修复 form-data (CVE-2025-7783): 升级到 4.0.4+
    npm install form-data@4.0.4 && \
    # 修复 esbuild (CVE-2024-24790): 升级架构包以获取新版 Go 编译的二进制
    npm install @esbuild/linux-x64@latest

USER 10014

ENTRYPOINT ["/app/choreo-wrapper.sh"]

CMD ["node", "main"]
