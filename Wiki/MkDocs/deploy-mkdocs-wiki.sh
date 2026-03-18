#!/bin/bash
#
# =============================================================================
# MkDocs Wiki 一键部署脚本
# =============================================================================
#
# 【用途】
#   在 Ubuntu 服务器上自动部署 MkDocs + Material 主题 Wiki 站点
#
# 【系统要求】
#   - Ubuntu 22.04+
#   - Python 3.10+
#   - Nginx
#   - root 权限
#
# 【使用方法】
#   1. 修改配置区域的参数
#   2. 执行：bash deploy-mkdocs-wiki.sh
#   3. 等待部署完成
#
# 【作者】OpenClaw 团队
# 【版本】1.0
# 【更新】2026-03-17
#
# =============================================================================

set -e  # 遇到错误立即退出

# =============================================================================
# 【配置区域】==== 请根据实际情况修改以下参数 ====
# =============================================================================

# Wiki 域名（必须修改）
WIKI_DOMAIN="${WIKI_DOMAIN:-wiki.mubai.top}"

# 管理员邮箱（用于 SSL 证书通知）
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@${WIKI_DOMAIN}}"

# MkDocs 站点名称
SITE_NAME="${SITE_NAME:-OpenClaw Wiki}"

# MkDocs 站点描述
SITE_DESCRIPTION="${SITE_DESCRIPTION:-OpenClaw 官方文档和脚本库}"

# 部署目录
DEPLOY_DIR="${DEPLOY_DIR:-/opt/mkdocs}"

# Python pip 镜像（可选，国内加速）
PIP_MIRROR="${PIP_MIRROR:-https://pypi.tuna.tsinghua.edu.cn/simple}"

# =============================================================================
# 【脚本内部配置】==== 以下一般不需要修改 ====
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/mkdocs_deploy_$(date +%Y%m%d_%H%M%S).log"

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

log_to_file() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log_to_file "INFO: $1"
}

log_success() {
    echo -e "${GREEN}[✓ SUCCESS]${NC} $1"
    log_to_file "SUCCESS: $1"
}

log_warn() {
    echo -e "${YELLOW}[⚠ WARN]${NC} $1"
    log_to_file "WARN: $1"
}

log_error() {
    echo -e "${RED}[✗ ERROR]${NC} $1"
    log_to_file "ERROR: $1"
}

log_step() {
    echo -e "\n${BOLD}${CYAN}========================================${NC}"
    echo -e "${BOLD}${CYAN}$1${NC}"
    echo -e "${BOLD}${CYAN}========================================${NC}"
    log_to_file "STEP: $1"
}

check_result() {
    if [ $? -eq 0 ]; then
        log_success "$1"
        return 0
    else
        log_error "$2"
        return 1
    fi
}

# =============================================================================
# 【检查函数】==== 验证环境和权限 ====
# =============================================================================

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用 root 用户运行此脚本（sudo -i）"
        exit 1
    fi
    log_success "root 权限检查通过"
}

check_system() {
    if ! command -v lsb_release &> /dev/null; then
        log_warn "无法检测系统版本，继续执行..."
        return 0
    fi
    
    local release=$(lsb_release -rs)
    log_info "检测到 Ubuntu $release"
    
    if (( $(echo "$release >= 22.04" | bc -l) )); then
        log_success "系统版本符合要求"
    else
        log_warn "建议使用 Ubuntu 22.04 或更高版本"
    fi
}

check_python() {
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 未安装，请先安装：apt install python3"
        exit 1
    fi
    
    local version=$(python3 --version)
    log_info "Python 已安装：$version"
    log_success "Python 检查通过"
}

check_nginx() {
    if ! command -v nginx &> /dev/null; then
        log_warn "Nginx 未安装，将在后续步骤安装"
        return 1
    fi
    
    local version=$(nginx -v 2>&1)
    log_info "Nginx 已安装：$version"
    log_success "Nginx 检查通过"
    return 0
}

# =============================================================================
# 【安装函数】==== 执行具体的安装步骤 ====
# =============================================================================

install_dependencies() {
    log_step "步骤 1: 安装系统依赖"
    
    log_info "更新软件包索引..."
    apt update -qq || { log_error "apt update 失败"; return 1; }
    
    log_info "安装基础工具..."
    apt install -y -qq \
        python3 \
        python3-pip \
        nginx \
        bc \
        curl \
        > /dev/null 2>&1
    check_result "系统依赖安装完成" "系统依赖安装失败"
}

install_mkdocs() {
    log_step "步骤 2: 安装 MkDocs 和主题"
    
    log_info "使用 pip 安装 MkDocs..."
    
    if [ -n "$PIP_MIRROR" ]; then
        pip3 install mkdocs -i "$PIP_MIRROR" -q
        check_result "MkDocs 安装成功" "MkDocs 安装失败"
    else
        pip3 install mkdocs -q
        check_result "MkDocs 安装成功" "MkDocs 安装失败"
    fi
    
    log_info "安装 Material 主题..."
    if [ -n "$PIP_MIRROR" ]; then
        pip3 install mkdocs-material -i "$PIP_MIRROR" -q
        check_result "Material 主题安装成功" "Material 主题安装失败"
    else
        pip3 install mkdocs-material -q
        check_result "Material 主题安装成功" "Material 主题安装失败"
    fi
    
    # 验证安装
    local version=$(mkdocs --version 2>&1 | head -1)
    log_success "MkDocs 已安装：$version"
}

create_project() {
    log_step "步骤 3: 创建 MkDocs 项目"
    
    log_info "创建部署目录：$DEPLOY_DIR"
    mkdir -p "$DEPLOY_DIR"
    check_result "目录创建成功" "目录创建失败"
    
    cd "$DEPLOY_DIR"
    
    log_info "初始化 MkDocs 项目..."
    mkdocs new . 2>/dev/null || {
        log_warn "项目已存在，跳过初始化"
        return 0
    }
    check_result "项目初始化成功" "项目初始化失败"
    
    log_info "创建文档目录结构..."
    mkdir -p docs/{openclaw/{deployment,configuration,troubleshooting},scripts/{deploy,config,tools},tools/{openclaw,wiki,nginx},assets/scripts}
    check_result "目录结构创建成功" "目录结构创建失败"
}

create_config() {
    log_step "步骤 4: 创建 MkDocs 配置"
    
    cat > "$DEPLOY_DIR/mkdocs.yml" << EOF
site_name: ${SITE_NAME}
site_url: http://${WIKI_DOMAIN}
site_author: OpenClaw Team
site_description: ${SITE_DESCRIPTION}

repo_url: https://github.com/openclaw/openclaw
repo_name: openclaw/openclaw

theme:
  name: material
  language: zh
  palette:
    primary: blue
    accent: blue
  features:
    - navigation.tabs
    - navigation.sections
    - navigation.expand
    - content.code.copy
    - content.code.download

extra_css:
  - assets/css/custom.css

markdown_extensions:
  - pymdownx.highlight:
      anchor_linenums: true
  - pymdownx.inlinehilite
  - pymdownx.snippets
  - pymdownx.superfences
  - tables
  - toc:
      permalink: true
  - attr_list
  - md_in_html
  - pymdownx.emoji:
      emoji_index: !!python/name:material.extensions.emoji.twemoji
      emoji_generator: !!python/name:material.extensions.emoji.to_svg

nav:
  - 首页：index.md
  - 工具分类:
    - 工具首页：tools/index.md
    - OpenClaw 工具：tools/openclaw/index.md
    - Wiki 工具：tools/wiki/index.md
    - Nginx 工具：tools/nginx/index.md
  - OpenClaw 部署:
    - 服务端部署：openclaw/deployment/server.md
    - 子节点部署：openclaw/deployment/subagent.md
    - Wiki.js 部署：openclaw/deployment/wiki.md
  - 配置文档:
    - Gateway 配置：openclaw/configuration/gateway.md
    - 模型配置：openclaw/configuration/model.md
    - 钉钉集成：openclaw/configuration/dingtalk.md
    - 子节点管理：openclaw/configuration/subagent.md
  - 脚本库:
    - 部署脚本:
      - deploy_openclaw_server.sh: scripts/deploy/deploy_openclaw_server.md
      - deploy-subagent.sh: scripts/deploy/deploy-subagent.md
      - deploy-wiki.sh: scripts/deploy/deploy-wiki.md
    - 配置文件:
      - ip.txt: scripts/config/ip-txt.md
      - ip-subagent.txt: scripts/config/ip-subagent-txt.md
      - ip-wiki.txt: scripts/config/ip-wiki-txt.md
    - 工具脚本:
      - set-nginx-password.sh: scripts/tools/set-nginx-password.md
  - 故障排除:
    - SSH 连接问题：openclaw/troubleshooting/ssh.md
    - Node.js 安装：openclaw/troubleshooting/nodejs.md
    - OpenClaw 问题：openclaw/troubleshooting/openclaw.md
    - Gateway 问题：openclaw/troubleshooting/gateway.md

extra:
  social:
    - icon: fontawesome/brands/github
      link: https://github.com/openclaw/openclaw
EOF
    check_result "配置文件创建成功" "配置文件创建失败"
}

create_nginx_config() {
    log_step "步骤 5: 配置 Nginx"
    
    cat > /etc/nginx/sites-available/${WIKI_DOMAIN} << EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${WIKI_DOMAIN};

    root ${DEPLOY_DIR}/site;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # 强制下载脚本文件
    location /assets/scripts/ {
        add_header Content-Disposition 'attachment';
        add_header Content-Type 'application/octet-stream';
    }

    location ~* \.(css|js|png|jpg|svg|woff|woff2|ico)$ {
        expires 7d;
        add_header Cache-Control "public";
    }

    access_log /var/log/nginx/${WIKI_DOMAIN}_access.log;
    error_log /var/log/nginx/${WIKI_DOMAIN}_error.log;
}
EOF
    check_result "Nginx 配置文件创建成功" "Nginx 配置文件创建失败"
    
    log_info "启用站点配置..."
    ln -sf /etc/nginx/sites-available/${WIKI_DOMAIN} /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    check_result "站点启用成功" "站点启用失败"
    
    log_info "测试 Nginx 配置..."
    nginx -t 2>&1 | tee -a "$LOG_FILE"
    check_result "Nginx 配置测试通过" "Nginx 配置测试失败"
}

build_site() {
    log_step "步骤 6: 构建 Wiki 站点"
    
    cd "$DEPLOY_DIR"
    
    log_info "清理旧站点..."
    rm -rf site/
    check_result "旧站点清理完成" "旧站点清理失败"
    
    log_info "构建新站点..."
    mkdocs build --clean 2>&1 | tee -a "$LOG_FILE"
    check_result "站点构建成功" "站点构建失败"
    
    # 显示构建结果
    local site_size=$(du -sh site/ | cut -f1)
    local file_count=$(find site/ -type f | wc -l)
    log_success "站点构建完成：$site_size ($file_count 个文件)"
}

start_services() {
    log_step "步骤 7: 启动服务"
    
    log_info "启动 Nginx..."
    systemctl enable nginx
    systemctl start nginx
    check_result "Nginx 启动成功" "Nginx 启动失败"
    
    log_info "重新加载 Nginx 配置..."
    systemctl reload nginx
    check_result "Nginx 配置重载成功" "Nginx 配置重载失败"
}

final_verification() {
    log_step "步骤 8: 最终验证"
    
    local all_passed=true
    
    # 1. 检查 Nginx
    log_info "检查 Nginx 状态..."
    if systemctl is-active nginx > /dev/null 2>&1; then
        log_success "Nginx 运行正常"
    else
        log_error "Nginx 未运行"
        all_passed=false
    fi
    
    # 2. 检查站点目录
    log_info "检查站点目录..."
    if [ -d "$DEPLOY_DIR/site" ] && [ -f "$DEPLOY_DIR/site/index.html" ]; then
        log_success "站点目录存在"
    else
        log_error "站点目录不存在"
        all_passed=false
    fi
    
    # 3. 测试本地访问
    log_info "测试本地访问..."
    if curl -s http://127.0.0.1/ | head -1 | grep -q "<!doctype"; then
        log_success "本地访问正常"
    else
        log_warn "本地访问可能有问题"
    fi
    
    echo ""
    if [ "$all_passed" = true ]; then
        log_success "所有验证通过！"
    else
        log_warn "部分验证未通过，请检查日志"
    fi
}

show_completion_info() {
    log_step "🎉 部署完成！"
    
    echo ""
    echo "========================================"
    echo "  访问信息"
    echo "========================================"
    echo ""
    echo "  Wiki 地址：http://${WIKI_DOMAIN}"
    echo "  文档目录：${DEPLOY_DIR}/docs/"
    echo "  站点目录：${DEPLOY_DIR}/site/"
    echo "  配置文件：${DEPLOY_DIR}/mkdocs.yml"
    echo ""
    echo "========================================"
    echo "  管理命令"
    echo "========================================"
    echo ""
    echo "  构建站点：cd ${DEPLOY_DIR} && mkdocs build --clean"
    echo "  本地预览：cd ${DEPLOY_DIR} && mkdocs serve --dev-addr=0.0.0.0:8000"
    echo "  查看状态：systemctl status nginx"
    echo "  重新加载：systemctl reload nginx"
    echo ""
    echo "========================================"
    echo "  日志文件"
    echo "========================================"
    echo ""
    echo "  部署日志：${LOG_FILE}"
    echo "  Nginx 日志：/var/log/nginx/${WIKI_DOMAIN}_*.log"
    echo ""
    echo "========================================"
    echo ""
    
    log_to_file "========================================"
    log_to_file "部署完成"
    log_to_file "Wiki: http://${WIKI_DOMAIN}"
    log_to_file "Docs: ${DEPLOY_DIR}/docs/"
    log_to_file "========================================"
}

# =============================================================================
# 【主程序】==== 按顺序执行所有步骤 ====
# =============================================================================

main() {
    echo ""
    echo "========================================"
    echo "  MkDocs Wiki 一键部署脚本"
    echo "========================================"
    echo ""
    log_info "部署时间：$(date)"
    log_info "日志文件：${LOG_FILE}"
    echo ""
    
    # 显示配置信息
    log_info "配置信息："
    echo "  域名：${WIKI_DOMAIN}"
    echo "  站点名称：${SITE_NAME}"
    echo "  部署目录：${DEPLOY_DIR}"
    echo "  pip 镜像：${PIP_MIRROR:-官方源}"
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
    check_python
    check_nginx || true
    
    install_dependencies
    install_mkdocs
    create_project
    create_config
    create_nginx_config
    build_site
    start_services
    
    final_verification
    show_completion_info
    
    log_success "部署全部完成！"
}

# 运行主程序
main "$@"
