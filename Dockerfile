FROM rajnandan1/kener:latest

# 1. 切换到 root 以修改文件系统
USER root

# 2. 拷贝本地的启动脚本到镜像中
COPY entrypoint.sh /app/entrypoint.sh

# 3. 设置权限：
# - 赋予脚本执行权限
# - 删除原有的只读目录
# - 创建指向 /tmp 的软链接
RUN chmod +x /app/entrypoint.sh && \
    rm -rf /app/database /app/uploads && \
    ln -s /tmp/database /app/database && \
    ln -s /tmp/uploads /app/uploads

# 4. 切换回 Choreo 要求的受限用户
USER 10014

# 5. 指定新的入口点
ENTRYPOINT ["/app/entrypoint.sh"]

# 6. 保持默认启动命令
CMD ["node", "main"]
