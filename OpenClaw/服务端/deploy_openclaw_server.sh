#!/bin/bash
#
# =============================================================================
# OpenClaw 服务端一键部署脚本 v2.0
# =============================================================================
#
# 【用途】
#   在 Ubuntu 服务器上自动部署 OpenClaw Gateway + Nginx + HTTPS
#
# 【特点】
#   - 一键执行，自动化程度高
#   - 每步都有详细输出和检查
#   - 支持配置自定义参数（API Key、域名等）
#   - 适合批量部署和重复部署
#
# 【使用方法】
#   1. 编辑本脚本，修改【配置区域】中的参数
#   2. 执行：bash deploy_openclaw_server.sh
#   3. 等待部署完成，记录输出的访问地址和 Token
#
# 【系统要求】
#   - Ubuntu 22.04 或更高版本
#   - root 权限
#   - 域名已解析到服务器 IP
#   - 80/443 端口开放
#
# 【作者】OpenClaw 部署团队
# 【版本】2.0
# 【更新】2026-03-17
#
# =============================================================================

set -e  # 遇到错误立即退出

# =============================================================================
# 【配置区域】==== 请根据实际情况修改以下参数 ====
# =============================================================================

# 域名配置（必须修改）
# 将你的域名填写在这里，例如：openclaw.mubai.top
DOMAIN="${DOMAIN:-briquette.mubai.top}"

# 管理员邮箱（用于 SSL 证书通知，建议修改）
# 格式：your-email@example.com
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@${DOMAIN}}"

# 阿里云百炼 API Key（可选，用于配置 AI 模型）
# 获取地址：https://dashscope.console.aliyun.com/
# 如果不需要配置模型，留空即可
DASHSCOPE_API_KEY="${DASHSCOPE_API_KEY:-}"

# 默认 AI 模型（可选）
# 可选值：qwen3.5-plus, qwen3-max-2026-01-23, qwen3-coder-next 等
DEFAULT_MODEL="${DEFAULT_MODEL:-qwen3.5-plus}"

# Gateway 端口（一般不需要修改）
GATEWAY_PORT="${GATEWAY_PORT:-18789}"

# Nginx 是否启用基础认证（true/false，建议 false，只用 Token 认证）
ENABLE_BASIC_AUTH="${ENABLE_BASIC_AUTH:-false}"

# 基础认证用户名（如果启用基础认证）
BASIC_AUTH_USER="${BASIC_AUTH_USER:-admin}"

# 基础认证密码（如果启用基础认证，请修改为强密码）
BASIC_AUTH_PASSWORD="${BASIC_AUTH_PASSWORD:-}"

# =============================================================================
# 【脚本内部配置】==== 以下一般不需要修改 ====
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/deploy_$(date +%Y%m%d_%H%M%S).log"
OPENCLAW_VERSION="latest"
NODE_VERSION="22.x"

# 颜色输出定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# =============================================================================
# 【日志函数】==== 记录每步操作和结果 ====
# =============================================================================

# 记录到日志文件
log_to_file() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 信息输出（蓝色）
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log_to_file "INFO: $1"
}

# 成功输出（绿色）
log_success() {
    echo -e "${GREEN}[✓ SUCCESS]${NC} $1"
    log_to_file "SUCCESS: $1"
}

# 警告输出（黄色）
log_warn() {
    echo -e "${YELLOW}[⚠ WARN]${NC} $1"
    log_to_file "WARN: $1"
}

# 错误输出（红色）
log_error() {
    echo -e "${RED}[✗ ERROR]${NC} $1"
    log_to_file "ERROR: $1"
}

# 步骤标题（粗体 + 青色）
log_step() {
    echo -e "\n${BOLD}${CYAN}========================================${NC}"
    echo -e "${BOLD}${CYAN}$1${NC}"
    echo -e "${BOLD}${CYAN}========================================${NC}"
    log_to_file "STEP: $1"
}

# =============================================================================
# 【检查函数】==== 验证每步是否成功 ====
# =============================================================================

# 检查命令是否执行成功
check_result() {
    if [ $? -eq 0 ]; then
        log_success "$1"
        return 0
    else
        log_error "$2"
        return 1
    fi
}

# 检查是否以 root 运行
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用 root 用户运行此脚本（sudo -i）"
        exit 1
    fi
    log_success "root 权限检查通过"
}

# 检查系统版本
check_system() {
    if ! command -v lsb_release &> /dev/null; then
        log_warn "无法检测系统版本，继续执行..."
        return 0
    fi
    
    local release=$(lsb_release -rs)
    log_info "检测到 Ubuntu $release"
    
    # 检查是否为 22.04+
    if (( $(echo "$release >= 22.04" | bc -l) )); then
        log_success "系统版本符合要求"
    else
        log_warn "建议使用 Ubuntu 22.04 或更高版本"
    fi
}

# 检查网络连接
check_network() {
    log_info "检查网络连接..."
    if ping -c 2 -W 2 8.8.8.8 > /dev/null 2>&1; then
        log_success "网络连接正常"
    else
        log_error "网络连接失败，请检查网络设置"
        exit 1
    fi
}

# 检查端口占用
check_port() {
    local port=$1
    if ss -tlnp | grep -q ":$port "; then
        log_warn "端口 $port 已被占用"
        return 1
    else
        log_info "端口 $port 可用"
        return 0
    fi
}

# =============================================================================
# 【安装函数】==== 执行具体的安装步骤 ====
# =============================================================================

# 安装系统依赖
install_dependencies() {
    log_step "步骤 1: 安装系统依赖"
    
    log_info "更新软件包索引..."
    apt update -qq || { log_error "apt update 失败"; return 1; }
    
    log_info "安装基础工具..."
    apt install -y -qq \
        curl \
        wget \
        gnupg \
        ca-certificates \
        software-properties-common \
        bc \
        > /dev/null 2>&1
    check_result "基础工具安装完成" "基础工具安装失败"
}

# 安装 Node.js
install_nodejs() {
    log_step "步骤 2: 安装 Node.js ${NODE_VERSION}"
    
    # 检查是否已安装
    if command -v node &> /dev/null; then
        local version=$(node --version)
        log_info "Node.js 已安装：$version"
        
        # 检查版本是否 >= 18
        local major_version=$(echo $version | cut -d'.' -f1 | tr -d 'v')
        if [ "$major_version" -ge 18 ]; then
            log_success "Node.js 版本符合要求"
            return 0
        else
            log_warn "Node.js 版本过低，需要升级"
        fi
    fi
    
    log_info "添加 NodeSource 仓库..."
    curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}" | bash - > /dev/null 2>&1
    check_result "NodeSource 仓库添加成功" "NodeSource 仓库添加失败"
    
    log_info "安装 Node.js..."
    apt install -y -qq nodejs > /dev/null 2>&1
    check_result "Node.js 安装成功" "Node.js 安装失败"
    
    # 验证安装
    local node_ver=$(node --version)
    local npm_ver=$(npm --version)
    log_success "Node.js $node_ver, npm $npm_ver"
}

# 安装 OpenClaw
install_openclaw() {
    log_step "步骤 3: 安装 OpenClaw"
    
    log_info "使用 npm 安装 OpenClaw ${OPENCLAW_VERSION}..."
    npm install -g openclaw@${OPENCLAW_VERSION} --no-fund --no-audit --loglevel=error 2>/dev/null
    check_result "OpenClaw 安装成功" "OpenClaw 安装失败"
    
    # 验证安装
    local version=$(openclaw --version 2>/dev/null | head -1)
    log_success "OpenClaw 已安装：$version"
}

# 安装 Nginx
install_nginx() {
    log_step "步骤 4: 安装 Nginx"
    
    # 检查是否已安装
    if command -v nginx &> /dev/null; then
        local ver=$(nginx -v 2>&1)
        log_info "Nginx 已安装：$ver"
        log_success "Nginx 检查通过"
        return 0
    fi
    
    log_info "安装 Nginx..."
    apt install -y -qq nginx > /dev/null 2>&1
    check_result "Nginx 安装成功" "Nginx 安装失败"
    
    # 验证安装
    local ver=$(nginx -v 2>&1)
    log_success "$ver"
}

# 安装 Certbot
install_certbot() {
    log_step "步骤 5: 安装 Certbot (SSL 证书工具)"
    
    # 检查是否已安装
    if command -v certbot &> /dev/null; then
        log_info "Certbot 已安装"
        log_success "Certbot 检查通过"
        return 0
    fi
    
    log_info "安装 Certbot 和 Nginx 插件..."
    apt install -y -qq certbot python3-certbot-nginx > /dev/null 2>&1
    check_result "Certbot 安装成功" "Certbot 安装失败"
    
    # 验证安装
    local ver=$(certbot --version 2>&1 | head -1)
    log_success "$ver"
}

# 创建 OpenClaw 配置
create_openclaw_config() {
    log_step "步骤 6: 创建 OpenClaw 配置"
    
    # 生成随机 Token
    local auth_token=$(cat /proc/sys/kernel/random/uuid | tr -d '-')
    log_info "生成随机 Token: ${auth_token:0:16}..."
    
    # 创建配置目录
    mkdir -p ~/.openclaw
    check_result "配置目录创建成功" "配置目录创建失败"
    
    # 构建模型配置（如果提供了 API Key）
    local models_config=""
    if [ -n "$DASHSCOPE_API_KEY" ]; then
        log_info "配置阿里云百炼模型..."
        models_config=',
  "models": {
    "mode": "merge",
    "providers": {
      "bailian": {
        "baseUrl": "https://coding.dashscope.aliyuncs.com/v1",
        "apiKey": "'"$DASHSCOPE_API_KEY"'",
        "api": "openai-completions",
        "models": [
          {"id": "qwen3.5-plus", "name": "qwen3.5-plus", "reasoning": false, "input": ["text", "image"], "contextWindow": 1000000, "maxTokens": 65536},
          {"id": "qwen3-max-2026-01-23", "name": "qwen3-max-2026-01-23", "reasoning": false, "input": ["text"], "contextWindow": 262144, "maxTokens": 65536},
          {"id": "qwen3-coder-next", "name": "qwen3-coder-next", "reasoning": false, "input": ["text"], "contextWindow": 262144, "maxTokens": 65536},
          {"id": "qwen3-coder-plus", "name": "qwen3-coder-plus", "reasoning": false, "input": ["text"], "contextWindow": 1000000, "maxTokens": 65536},
          {"id": "MiniMax-M2.5", "name": "MiniMax-M2.5", "reasoning": false, "input": ["text"], "contextWindow": 196608, "maxTokens": 32768},
          {"id": "glm-5", "name": "glm-5", "reasoning": false, "input": ["text"], "contextWindow": 202752, "maxTokens": 16384},
          {"id": "glm-4.7", "name": "glm-4.7", "reasoning": false, "input": ["text"], "contextWindow": 202752, "maxTokens": 16384},
          {"id": "kimi-k2.5", "name": "kimi-k2.5", "reasoning": false, "input": ["text", "image"], "contextWindow": 262144, "maxTokens": 32768}
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "bailian/'"$DEFAULT_MODEL"'"
      }
    }
  }'
        log_success "模型配置完成"
    else
        log_warn "未配置 API Key，跳过模型配置"
    fi
    
    # 创建配置文件
    cat > ~/.openclaw/openclaw.json << EOF
{
  "meta": {
    "lastTouchedVersion": "2026.3.13",
    "lastTouchedAt": "$(date -Iseconds)",
    "deployedBy": "deploy_openclaw_server.sh v2.0"
  },
  "gateway": {
    "port": ${GATEWAY_PORT},
    "mode": "local",
    "bind": "lan",
    "controlUi": {
      "enabled": true,
      "allowedOrigins": ["*"],
      "allowInsecureAuth": true,
      "dangerouslyDisableDeviceAuth": true
    },
    "auth": {
      "mode": "token",
      "token": "${auth_token}"
    }
  }${models_config}
}
EOF
    check_result "配置文件创建成功" "配置文件创建失败"
    
    # 验证 JSON 格式
    if cat ~/.openclaw/openclaw.json | python3 -m json.tool > /dev/null 2>&1; then
        log_success "配置文件格式验证通过"
    else
        log_error "配置文件格式错误"
        return 1
    fi
    
    # 保存 Token 到单独文件（方便查看）
    echo "$auth_token" > ~/.openclaw/auth_token.txt
    chmod 600 ~/.openclaw/auth_token.txt
    log_info "Token 已保存到 ~/.openclaw/auth_token.txt"
    
    # 输出 Token（重要！）
    echo ""
    log_success "========================================="
    log_success "  请保存以下 Token（登录时需要）："
    log_success "  Token: ${auth_token}"
    log_success "========================================="
    echo ""
    
    # 保存到日志
    log_to_file "AUTH_TOKEN: ${auth_token}"
}

# 创建 Nginx 配置
create_nginx_config() {
    log_step "步骤 7: 创建 Nginx 配置"
    
    # 构建基础认证配置（可选）
    local basic_auth_config=""
    if [ "$ENABLE_BASIC_AUTH" = "true" ] && [ -n "$BASIC_AUTH_PASSWORD" ]; then
        log_info "启用 Nginx 基础认证..."
        
        # 安装 apache2-utils（提供 htpasswd 命令）
        apt install -y -qq apache2-utils > /dev/null 2>&1
        
        # 创建密码文件
        htpasswd -cb /etc/nginx/.htpasswd "$BASIC_AUTH_USER" "$BASIC_AUTH_PASSWORD" > /dev/null 2>&1
        check_result "基础认证密码文件创建成功" "基础认证密码文件创建失败"
        
        basic_auth_config='
        auth_basic "OpenClaw Admin";
        auth_basic_user_file /etc/nginx/.htpasswd;
'
    else
        log_info "Nginx 基础认证：未启用（仅使用 Token 认证）"
    fi
    
    # 创建 Nginx 配置文件
    cat > /etc/nginx/sites-available/$DOMAIN << EOF
# HTTP - 强制跳转 HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN};

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS 配置
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${DOMAIN};

    # SSL 证书（Certbot 自动填充）
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;

    # SSL 安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
${basic_auth_config}
    # 反向代理到 OpenClaw Gateway
    location / {
        proxy_pass http://127.0.0.1:${GATEWAY_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        proxy_buffering off;
    }

    # 日志
    access_log /var/log/nginx/${DOMAIN}_access.log;
    error_log /var/log/nginx/${DOMAIN}_error.log;
}
EOF
    check_result "Nginx 配置文件创建成功" "Nginx 配置文件创建失败"
    
    # 启用站点
    log_info "启用站点配置..."
    ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    check_result "站点启用成功" "站点启用失败"
    
    # 测试配置
    log_info "测试 Nginx 配置..."
    nginx -t 2>&1 | tee -a "$LOG_FILE"
    check_result "Nginx 配置测试通过" "Nginx 配置测试失败"
}

# 申请 SSL 证书
request_ssl_certificate() {
    log_step "步骤 8: 申请 SSL 证书"
    
    log_info "使用 Certbot 申请 Let's Encrypt 证书..."
    log_info "域名：$DOMAIN"
    log_info "邮箱：$ADMIN_EMAIL"
    
    # 先重新加载 Nginx（需要 Nginx 运行才能验证域名）
    systemctl reload nginx 2>/dev/null || systemctl start nginx
    
    # 申请证书
    certbot certonly --nginx -d $DOMAIN \
        --non-interactive \
        --agree-tos \
        --email "$ADMIN_EMAIL" \
        2>&1 | tee -a "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        log_success "SSL 证书申请成功"
        
        # 显示证书信息
        log_info "证书信息："
        certbot certificates 2>&1 | tee -a "$LOG_FILE"
        
        # 重新加载 Nginx
        systemctl reload nginx
        check_result "Nginx 重新加载成功" "Nginx 重新加载失败"
    else
        log_warn "SSL 证书申请失败，可能原因："
        echo "  1. 域名未解析到本服务器"
        echo "  2. 80 端口被防火墙阻止"
        echo "  3. 域名已被申请过证书"
        echo ""
        log_info "可以手动申请：certbot --nginx -d $DOMAIN"
    fi
}

# 安装并启动 Gateway 服务
install_gateway_service() {
    log_step "步骤 9: 安装 OpenClaw Gateway 服务"
    
    log_info "安装 systemd 服务..."
    openclaw gateway install 2>&1 | tee -a "$LOG_FILE"
    check_result "服务安装成功" "服务安装失败"
    
    log_info "重新加载 systemd 配置..."
    systemctl --user daemon-reload
    check_result "systemd 配置重载成功" "systemd 配置重载失败"
    
    log_info "启用服务（开机自启）..."
    systemctl --user enable openclaw-gateway.service
    check_result "服务启用成功" "服务启用失败"
    
    log_info "启动服务..."
    systemctl --user start openclaw-gateway.service
    check_result "服务启动成功" "服务启动失败"
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 5
    
    # 验证服务状态
    log_info "检查服务状态..."
    if systemctl --user is-active openclaw-gateway.service > /dev/null 2>&1; then
        log_success "Gateway 服务运行正常"
    else
        log_warn "Gateway 服务未运行，尝试重启..."
        systemctl --user restart openclaw-gateway.service
        sleep 3
    fi
}

# 最终验证
final_verification() {
    log_step "步骤 10: 最终验证"
    
    local all_passed=true
    
    # 1. 检查 Gateway 端口
    log_info "检查 Gateway 端口 ${GATEWAY_PORT}..."
    if ss -tlnp | grep -q ":${GATEWAY_PORT} "; then
        log_success "Gateway 端口监听正常"
    else
        log_error "Gateway 端口未监听"
        all_passed=false
    fi
    
    # 2. 检查 Nginx
    log_info "检查 Nginx 状态..."
    if systemctl is-active nginx > /dev/null 2>&1; then
        log_success "Nginx 运行正常"
    else
        log_error "Nginx 未运行"
        all_passed=false
    fi
    
    # 3. 测试本地访问
    log_info "测试本地访问..."
    if curl -s http://127.0.0.1:${GATEWAY_PORT} | head -1 | grep -q "<!doctype"; then
        log_success "本地访问正常"
    else
        log_warn "本地访问可能有问题"
    fi
    
    # 4. 测试 HTTPS 访问（如果证书申请成功）
    if [ -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem ]; then
        log_info "测试 HTTPS 访问..."
        if curl -k -s -I https://$DOMAIN 2>/dev/null | head -1 | grep -q "200\|301\|302"; then
            log_success "HTTPS 访问正常"
        else
            log_warn "HTTPS 访问可能有问题（检查域名解析）"
        fi
    else
        log_warn "SSL 证书不存在，跳过 HTTPS 测试"
    fi
    
    echo ""
    if [ "$all_passed" = true ]; then
        log_success "所有验证通过！"
    else
        log_warn "部分验证未通过，请检查日志"
    fi
}

# 显示部署完成信息
show_completion_info() {
    log_step "🎉 部署完成！"
    
    echo ""
    echo "========================================"
    echo "  访问信息"
    echo "========================================"
    echo ""
    echo "  HTTPS 地址：https://${DOMAIN}"
    echo "  直接访问：http://$(hostname -I | awk '{print $1}'):${GATEWAY_PORT}"
    echo ""
    echo "  Auth Token: $(cat ~/.openclaw/auth_token.txt 2>/dev/null || echo '请查看 ~/.openclaw/openclaw.json')"
    echo ""
    echo "========================================"
    echo "  管理命令"
    echo "========================================"
    echo ""
    echo "  查看状态：openclaw gateway status"
    echo "  重启服务：systemctl --user restart openclaw-gateway.service"
    echo "  查看日志：openclaw logs --follow"
    echo "  Nginx 状态：systemctl status nginx"
    echo ""
    echo "========================================"
    echo "  日志文件"
    echo "========================================"
    echo ""
    echo "  部署日志：${LOG_FILE}"
    echo "  Gateway 日志：/tmp/openclaw/openclaw-$(date +%Y-%m-%d).log"
    echo "  Nginx 日志：/var/log/nginx/${DOMAIN}_*.log"
    echo ""
    echo "========================================"
    echo ""
    
    # 保存到日志
    log_to_file "========================================"
    log_to_file "部署完成"
    log_to_file "HTTPS: https://${DOMAIN}"
    log_to_file "Token: $(cat ~/.openclaw/auth_token.txt)"
    log_to_file "========================================"
}

# =============================================================================
# 【主程序】==== 按顺序执行所有步骤 ====
# =============================================================================

main() {
    echo ""
    echo "========================================"
    echo "  OpenClaw 服务端一键部署脚本 v2.0"
    echo "========================================"
    echo ""
    log_info "部署时间：$(date)"
    log_info "日志文件：${LOG_FILE}"
    echo ""
    
    # 显示配置信息
    log_info "配置信息："
    echo "  域名：${DOMAIN}"
    echo "  邮箱：${ADMIN_EMAIL}"
    echo "  API Key: ${DASHSCOPE_API_KEY:0:20}... (已隐藏)"
    echo "  默认模型：${DEFAULT_MODEL}"
    echo "  Gateway 端口：${GATEWAY_PORT}"
    echo "  基础认证：${ENABLE_BASIC_AUTH}"
    echo ""
    
    # 确认继续
    read -p "确认开始部署？(y/N): " confirm
    if [[ "$confirm" != "y" ]] && [[ "$confirm" != "Y" ]]; then
        log_info "已取消部署"
        exit 0
    fi
    
    echo ""
    
    # 执行检查和安装
    check_root
    check_system
    check_network
    
    install_dependencies
    install_nodejs
    install_openclaw
    install_nginx
    install_certbot
    
    create_openclaw_config
    create_nginx_config
    request_ssl_certificate
    install_gateway_service
    
    final_verification
    show_completion_info
    
    log_success "部署全部完成！"
}

# 运行主程序
main "$@"
