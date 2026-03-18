#!/bin/bash
#
# MkDocs Wiki 快速更新脚本
# 用途：上传文档并重新构建 Wiki
#

set -e

REMOTE_SERVER="38.246.245.39"
REMOTE_USER="root"
REMOTE_PASS="Huanxin0321"
REMOTE_DOCS="/opt/mkdocs/docs/"

log_info() { echo "[INFO] $1"; }
log_success() { echo "[✓] $1"; }
log_error() { echo "[✗] $1"; }

# 检查参数
if [ $# -eq 0 ]; then
    echo "用法：$0 <文件 1> [文件 2] [文件 3] ..."
    echo ""
    echo "示例："
    echo "  $0 server.md"
    echo "  $0 server.md subagent.md"
    echo "  $0 *.md"
    exit 1
fi

log_info "准备上传文件到 Wiki 服务器..."
echo ""

# 上传文件
for file in "$@"; do
    if [ -f "$file" ]; then
        log_info "上传：$file"
        sshpass -p "$REMOTE_PASS" scp -o StrictHostKeyChecking=no "$file" "$REMOTE_USER@$REMOTE_SERVER:$REMOTE_DOCS/"
        log_success "$file 上传成功"
    else
        log_error "文件不存在：$file"
    fi
done

echo ""
log_info "构建 Wiki 站点..."
sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_SERVER" "
    cd /opt/mkdocs && \
    mkdocs build --clean 2>&1 | tail -5 && \
    systemctl reload nginx
"

echo ""
log_success "Wiki 更新完成！"
echo ""
echo "访问地址：http://wiki.mubai.top"
