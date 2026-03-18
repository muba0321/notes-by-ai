#!/bin/bash
#
# Wiki.js 自动部署脚本（带 Nginx 反向代理）
# 用途：在远程服务器上自动安装 Wiki.js + Nginx + SSL
#
# 依赖：
#   - sshpass 工具（用于密码登录）
#   - Docker 和 Docker Compose
#   - ip-wiki.txt 文件中包含目标服务器信息
#
# 用法：
#   ./deploy-wiki.sh [域名]
#   默认域名：wiki.mubai.top
#

set -e

# ============ 配置区域 ============
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IP_FILE="${SCRIPT_DIR}/ip-wiki.txt"
DEFAULT_DOMAIN="wiki.mubai.top"
DOMAIN="${1:-$DEFAULT_DOMAIN}"
SSH_USER="root"
SSH_PORT="22"

# Wiki.js 配置
WIKI_PORT="3000"
DB_TYPE="sqlite"  # sqlite 或 postgres

# ============ 颜色输出 ============
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1" }
log_success() { echo -e "${GREEN}[✓]${NC} $1" }
log_warn() { echo -e "${YELLOW}[⚠]${NC} $1" }
log_error() { echo -e "${RED}[✗]${NC} $1" }
log_step() { echo -e "${CYAN}[>>>]${NC} $1" }

# ============ 函数定义 ============

# 检查 sshpass
check_sshpass() {
    if ! command -v sshpass &> /dev/null; then
        log_error "sshpass 未安装，请先安装：apt install -y sshpass"
        exit 1
    fi
    log_success "sshpass 已安装"
}

# 在远程服务器执行命令
remote_exec() {
    local ip=$1
    local port=$2
    local user=$3
    local password=$4
    local cmd=$5
    
    sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p "$port" "$user@$ip" "$cmd"
}

# 部署到远程服务器
deploy_to_remote() {
    local ip=$1
    local port=$2
    local user=$3
    local password=$4
    local domain=$5
    
    log_step "正在部署 Wiki.js 到 $ip (域名：$domain)"
    
    # 1. 检查 SSH 连接
    log_info "检查 SSH 连接..."
    if ! remote_exec "$ip" "$port" "$user" "$password" "echo 'SSH OK'" > /dev/null 2>&1; then
        log_error "SSH 连接失败：$ip"
        return 1
    fi
    log_success "SSH 连接成功"
    
    # 2. 检查并安装 Docker
    log_info "检查 Docker..."
    local docker_version
    docker_version=$(remote_exec "$ip" "$port" "$user" "$password" "docker --version 2>/dev/null || echo 'not installed'")
    
    if [[ "$docker_version" == "not installed" ]] || [[ -z "$docker_version" ]]; then
        log_warn "Docker 未安装，开始安装..."
        remote_exec "$ip" "$port" "$user" "$password" "
            curl -fsSL https://get.docker.com | bash
            systemctl enable docker
            systemctl start docker
            usermod -aG docker $user
        " || {
            log_error "Docker 安装失败"
            log_info "故障排除：手动执行 'curl -fsSL https://get.docker.com | bash'"
            return 1
        }
        log_success "Docker 安装完成"
    else
        log_success "Docker 已安装：$docker_version"
    fi
    
    # 3. 检查并安装 Docker Compose
    log_info "检查 Docker Compose..."
    local compose_version
    compose_version=$(remote_exec "$ip" "$port" "$user" "$password" "docker compose version 2>/dev/null || docker-compose --version 2>/dev/null || echo 'not installed'")
    
    if [[ "$compose_version" == "not installed" ]] || [[ -z "$compose_version" ]]; then
        log_warn "Docker Compose 未安装，开始安装..."
        remote_exec "$ip" "$port" "$user" "$password" "
            apt install -y docker-compose-plugin > /dev/null 2>&1 || \
            (curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose)
        "
        log_success "Docker Compose 安装完成"
    else
        log_success "Docker Compose 已安装：$compose_version"
    fi
    
    # 4. 创建 Wiki.js 目录和配置文件
    log_info "创建 Wiki.js 配置..."
    remote_exec "$ip" "$port" "$user" "$password" "
        mkdir -p /opt/wiki/data
        mkdir -p /opt/wiki/logs
        
        # 创建 Docker Compose 配置
        cat > /opt/wiki/docker-compose.yml << 'EOCOMPOSE'
version: '3.8'
services:
  wiki:
    image: requarks/wiki:latest
    container_name: wiki
    restart: unless-stopped
    ports:
      - \"127.0.0.1:3000:3000\"
    environment:
      - DB_TYPE=sqlite
      - DB_FILEPATH=/var/lib/wiki/db.sqlite
    volumes:
      - wiki-data:/var/lib/wiki
      - ./logs:/var/logs/wiki
    networks:
      - wiki-network

  nginx:
    image: nginx:alpine
    container_name: wiki-nginx
    restart: unless-stopped
    ports:
      - \"80:80\"
      - \"443:443\"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/letsencrypt:ro
    depends_on:
      - wiki
    networks:
      - wiki-network

volumes:
  wiki-data:

networks:
  wiki-network:
    driver: bridge
EOCOMPOSE

        # 创建 Nginx 配置（先配置 HTTP，SSL 后续申请）
        cat > /opt/wiki/nginx.conf << 'EONGINX'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    server_tokens off;
    
    # HTTP 重定向到 HTTPS
    server {
        listen 80;
        server_name DOMAIN_PLACEHOLDER;
        
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }
        
        location / {
            return 301 https://\$server_name\$request_uri;
        }
    }
    
    # HTTPS 配置
    server {
        listen 443 ssl http2;
        server_name DOMAIN_PLACEHOLDER;
        
        ssl_certificate /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/privkey.pem;
        
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
        ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;
        
        add_header X-Frame-Options \"SAMEORIGIN\" always;
        add_header X-Content-Type-Options \"nosniff\" always;
        add_header X-XSS-Protection \"1; mode=block\" always;
        
        # 上传文件大小限制
        client_max_body_size 50M;
        
        location / {
            proxy_pass http://wiki:3000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection \"upgrade\";
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
            proxy_buffering off;
        }
        
        access_log /var/log/nginx/wiki_access.log;
        error_log /var/log/nginx/wiki_error.log;
    }
}
EONGINX

        # 替换域名
        sed -i \"s/DOMAIN_PLACEHOLDER/$domain/g\" /opt/wiki/nginx.conf
        
        echo '✓ 配置文件创建完成'
    "
    log_success "Wiki.js 配置创建完成"
    
    # 5. 启动 Docker 容器
    log_info "启动 Wiki.js 容器..."
    remote_exec "$ip" "$port" "$user" "$password" "
        cd /opt/wiki
        docker compose up -d
        sleep 3
        docker compose ps
    "
    log_success "Wiki.js 容器已启动"
    
    # 6. 申请 SSL 证书
    log_info "申请 SSL 证书..."
    remote_exec "$ip" "$port" "$user" "$password" "
        mkdir -p /opt/wiki/ssl
        mkdir -p /var/www/certbot
        
        docker run --rm \
            -v /opt/wiki/ssl:/etc/letsencrypt \
            -v /var/www/certbot:/var/www/certbot \
            certbot/certbot certonly \
            --webroot -w /var/www/certbot \
            -d $domain \
            --email admin@$domain \
            --agree-tos \
            --non-interactive || \
        echo 'SSL 证书申请可能需要手动验证域名解析'
    "
    
    # 7. 验证部署
    log_info "验证部署..."
    remote_exec "$ip" "$port" "$user" "$password" "
        echo '=== 容器状态 ==='
        docker compose ps
        
        echo ''
        echo '=== 端口监听 ==='
        netstat -tlnp | grep -E '80|443' || ss -tlnp | grep -E '80|443'
        
        echo ''
        echo '=== Wiki.js 日志 ==='
        docker logs wiki --tail 5
    "
    
    # 输出访问信息
    echo ""
    log_success "部署完成！"
    echo ""
    echo "========================================"
    echo "  Wiki.js 访问信息"
    echo "========================================"
    echo "  域名：$domain"
    echo "  访问地址：https://$domain"
    echo ""
    echo "  首次访问需要初始化："
    echo "  1. 打开 https://$domain"
    echo "  2. 创建管理员账户"
    echo "  3. 配置站点信息"
    echo ""
    echo "  管理命令："
    echo "    cd /opt/wiki"
    echo "    docker compose ps          # 查看状态"
    echo "    docker compose logs -f     # 查看日志"
    echo "    docker compose restart     # 重启"
    echo "    docker compose stop        # 停止"
    echo "    docker compose start       # 启动"
    echo ""
    echo "  备份命令："
    echo "    docker compose exec wiki tar -czf /var/lib/wiki/backup.tar.gz /var/lib/wiki"
    echo "    docker cp wiki:/var/lib/wiki/backup.tar.gz ./wiki-backup.tar.gz"
    echo "========================================"
    echo ""
    
    return 0
}

# 解析 IP 文件
parse_ip_file() {
    local line=$1
    [[ "$line" =~ ^[[:space:]]*# ]] && return 1
    [[ -z "${line// }" ]] && return 1
    
    local ip port user password
    IFS=':' read -r ip port user password <<< "$line"
    port="${port:-$SSH_PORT}"
    user="${user:-root}"
    
    if [[ -z "$password" ]]; then
        log_error "密码不能为空：$ip"
        return 1
    fi
    
    echo "$ip $port $user $password"
    return 0
}

# ============ 主程序 ============

main() {
    echo ""
    echo "========================================"
    echo "  Wiki.js 自动部署脚本"
    echo "========================================"
    echo ""
    log_info "目标域名：$DOMAIN"
    log_info "IP 文件：$IP_FILE"
    echo ""
    
    check_sshpass
    
    if [[ ! -f "$IP_FILE" ]]; then
        log_error "IP 文件不存在：$IP_FILE"
        echo ""
        echo "请创建 $IP_FILE 文件，格式："
        echo "  IP:端口：用户名：密码"
        echo "  示例：38.246.245.39:22:root:yourpassword"
        echo ""
        exit 1
    fi
    
    log_warn "安全提醒：密码以明文存储在 $IP_FILE 中"
    read -p "确认继续？(y/N): " confirm
    [[ "$confirm" != "y" ]] && [[ "$confirm" != "Y" ]] && { log_info "已取消"; exit 0; }
    
    local total=0 success=0 failed=0
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        parsed=$(parse_ip_file "$line") || continue
        read -r ip port user password <<< "$parsed"
        [[ -z "$ip" ]] && continue
        
        ((total++))
        echo ""
        echo "========================================"
        echo "  部署 #$total"
        echo "========================================"
        
        if deploy_to_remote "$ip" "$port" "$user" "$password" "$DOMAIN"; then
            ((success++))
        else
            ((failed++))
            log_error "部署失败：$ip"
        fi
    done < "$IP_FILE"
    
    echo ""
    echo "========================================"
    echo "  部署汇总"
    echo "========================================"
    log_info "总计：$total | 成功：$success | 失败：$failed"
    
    [[ $failed -gt 0 ]] && exit 1
    log_success "部署成功！"
}

main "$@"
