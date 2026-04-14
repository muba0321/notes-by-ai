#!/bin/bash
# SSH 隧道状态检查脚本
# 用法：./check-tunnel.sh

set -e

echo "=========================================="
echo "  CI/CD 服务状态检查"
echo "=========================================="
echo

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查函数
check_status() {
    local name=$1
    local status=$2
    
    if [ "$status" = "active" ] || [ "$status" = "Up" ]; then
        echo -e "${GREEN}✓${NC} $name: $status"
        return 0
    else
        echo -e "${RED}✗${NC} $name: $status"
        return 1
    fi
}

echo "【子节点 1 - SSH 隧道】"
TUNNEL_STATUS=$(systemctl is-active ssh-tunnel 2>/dev/null || echo "inactive")
check_status "SSH 隧道" "$TUNNEL_STATUS"

echo
echo "【子节点 1 - Nginx】"
NGINX_STATUS=$(systemctl is-active nginx 2>/dev/null || echo "inactive")
check_status "Nginx" "$NGINX_STATUS"

echo
echo "【隧道端口监听】"
for port in 18080 19090 13000; do
    if ss -tlnp | grep -q ":$port "; then
        echo -e "${GREEN}✓${NC} 端口 $port: 监听中"
    else
        echo -e "${RED}✗${NC} 端口 $port: 未监听"
    fi
done

echo
echo "【隧道连接测试】"
for port in 18080 19090 13000; do
    response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://127.0.0.1:$port 2>/dev/null || echo "000")
    if [ "$response" != "000" ]; then
        echo -e "${GREEN}✓${NC} 端口 $port: HTTP $response"
    else
        echo -e "${RED}✗${NC} 端口 $port: 连接失败"
    fi
done

echo
echo "【堡垒机 - Docker 容器】(需 SSH 连接)"
ssh root@222.211.80.222 "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'" 2>/dev/null || echo "无法连接到堡垒机"

echo
echo "=========================================="
echo "  检查完成"
echo "=========================================="
