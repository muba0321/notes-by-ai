#!/bin/bash
#
# Nginx 自动部署脚本
# 用途：在多台远程服务器上自动安装和配置 Nginx + OpenClaw 反向代理
#
# 依赖：
#   - SSH 免密登录已配置
#   - ip.txt 文件中包含目标服务器 IP 列表
#
# 用法：
#   ./deploy-nginx.sh [域名]
#   默认域名：openclaw.mubai.top
#

set -e

# ============ 配置区域 ============
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IP_FILE="${SCRIPT_DIR}/ip.txt"
DEFAULT_DOMAIN="openclaw.mubai.top"
DOMAIN="${1:-$DEFAULT_DOMAIN}"
SSH_USER="root"
SSH_PORT="22"

# Nginx 配置模板
NGINX_CONFIG='
server {
    listen 80;
    listen [::]:80;
    server_name DOMAIN_PLACEHOLDER;

    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name DOMAIN_PLACEHOLDER;

    ssl_certificate /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    location / {
        auth_basic "OpenClaw Admin";
        auth_basic_user_file /etc/nginx/.htpasswd;

        proxy_pass http://127.0.0.1:18789;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        proxy_buffering off;
    }

    access_log /var/log/nginx/openclaw_access.log;
    error_log /var/log/nginx/openclaw_error.log;
}
'

# ============ 颜色输出 ============
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ============ 函数定义 ============

# 检查 SSH 连接
check_ssh() {
    local ip=$1
    local port=$2
    local user=$3
    
    ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p "$port" "$user@$ip" "echo 'SSH OK'" > /dev/null 2>&1
    return $?
}

# 在远程服务器执行命令
remote_exec() {
    local ip=$1
    local port=$2
    local user=$3
    local cmd=$4
    
    ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip" "$cmd"
}

# 在远程服务器部署 Nginx
deploy_to_remote() {
    local ip=$1
    local port=$2
    local user=$3
    local domain=$4
    
    log_info "正在部署到 $ip (端口：$port, 用户：$user)"
    
    # 检查 SSH 连接
    if ! check_ssh "$ip" "$port" "$user"; then
        log_error "SSH 连接失败：$ip"
        return 1
    fi
    log_success "SSH 连接成功：$ip"
    
    # 1. 安装 Nginx
    log_info "[$ip] 安装 Nginx..."
    remote_exec "$ip" "$port" "$user" "
        apt update -qq && \
        apt install -y nginx > /dev/null 2>&1 && \
        echo 'Nginx installed'
    " || { log_error "[$ip] Nginx 安装失败"; return 1; }
    
    # 2. 安装 Certbot
    log_info "[$ip] 安装 Certbot..."
    remote_exec "$ip" "$port" "$user" "
        apt install -y certbot python3-certbot-nginx > /dev/null 2>&1 && \
        echo 'Certbot installed'
    " || { log_warn "[$ip] Certbot 安装可能需要手动配置 SSL"; }
    
    # 3. 创建 Nginx 配置
    log_info "[$ip] 创建 Nginx 配置..."
    local config="${NGINX_CONFIG//DOMAIN_PLACEHOLDER/$domain}"
    remote_exec "$ip" "$port" "$user" "cat > /etc/nginx/sites-available/$domain" <<EOF
$config
EOF
    
    # 4. 启用站点
    log_info "[$ip] 启用站点配置..."
    remote_exec "$ip" "$port" "$user" "
        ln -sf /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/$domain && \
        rm -f /etc/nginx/sites-enabled/default
    "
    
    # 5. 测试 Nginx 配置
    log_info "[$ip] 测试 Nginx 配置..."
    remote_exec "$ip" "$port" "$user" "/usr/sbin/nginx -t" || { log_error "[$ip] Nginx 配置测试失败"; return 1; }
    
    # 6. 重新加载 Nginx
    log_info "[$ip] 重新加载 Nginx..."
    remote_exec "$ip" "$port" "$user" "systemctl reload nginx" || {
        log_warn "[$ip] Nginx 重载失败，尝试重启..."
        remote_exec "$ip" "$port" "$user" "systemctl restart nginx"
    }
    
    # 7. 获取 SSL 证书（可选，需要域名解析正确）
    log_info "[$ip] 尝试获取 SSL 证书..."
    remote_exec "$ip" "$port" "$user" "
        certbot --nginx -d $domain --non-interactive --agree-tos --email admin@$domain > /dev/null 2>&1 || \
        echo 'SSL 证书需要手动获取或域名未解析'
    "
    
    log_success "[$ip] 部署完成！"
    return 0
}

# 解析 IP 文件
parse_ip_file() {
    local line=$1
    
    # 跳过注释和空行
    [[ "$line" =~ ^[[:space:]]*# ]] && return 1
    [[ -z "${line// }" ]] && return 1
    
    # 解析格式：IP[:PORT[:USER]]
    local ip port user
    IFS=':' read -r ip port user <<< "$line"
    
    # 默认值
    port="${port:-$SSH_PORT}"
    user="${user:-$SSH_USER}"
    
    echo "$ip $port $user"
    return 0
}

# ============ 主程序 ============

main() {
    echo ""
    echo "========================================"
    echo "  Nginx + OpenClaw 自动部署脚本"
    echo "========================================"
    echo ""
    log_info "目标域名：$DOMAIN"
    log_info "IP 文件：$IP_FILE"
    echo ""
    
    # 检查 IP 文件
    if [[ ! -f "$IP_FILE" ]]; then
        log_error "IP 文件不存在：$IP_FILE"
        echo "请创建 $IP_FILE 文件，每行一个目标服务器 IP"
        exit 1
    fi
    
    # 统计
    local total=0
    local success=0
    local failed=0
    
    # 读取 IP 列表并部署
    while IFS= read -r line || [[ -n "$line" ]]; do
        parsed=$(parse_ip_file "$line") || continue
        
        read -r ip port user <<< "$parsed"
        
        if [[ -z "$ip" ]]; then
            continue
        fi
        
        ((total++))
        echo ""
        echo "----------------------------------------"
        echo "  部署 #$total"
        echo "----------------------------------------"
        
        if deploy_to_remote "$ip" "$port" "$user" "$DOMAIN"; then
            ((success++))
        else
            ((failed++))
            log_error "部署失败：$ip"
        fi
        
    done < "$IP_FILE"
    
    # 汇总
    echo ""
    echo "========================================"
    echo "  部署完成"
    echo "========================================"
    log_info "总计：$total | 成功：$success | 失败：$failed"
    echo ""
    
    if [[ $failed -gt 0 ]]; then
        log_warn "有 $failed 台服务器部署失败，请检查日志"
        exit 1
    fi
    
    log_success "所有服务器部署成功！"
    echo ""
    echo "下一步："
    echo "  1. 确保域名 $DOMAIN 已解析到各服务器"
    echo "  2. 访问 https://$DOMAIN 测试"
    echo "  3. 如需修改密码：htpasswd /etc/nginx/.htpasswd admin"
    echo ""
}

main "$@"
