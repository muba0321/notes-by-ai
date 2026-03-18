#!/bin/bash
#
# OpenClaw 子节点自动部署脚本（增强版）
# 用途：在多台远程服务器上自动安装 OpenClaw（无 Nginx，纯任务执行节点）
#
# 依赖：
#   - sshpass 工具（用于密码登录）
#   - ip-subagent.txt 文件中包含目标服务器信息
#
# 用法：
#   ./deploy-subagent.sh
#
# 更新日志：
#   2026-03-16 - 增强版：添加完整错误处理、问题诊断、模型配置
#

set -e

# ============ 配置区域 ============
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IP_FILE="${SCRIPT_DIR}/ip-subagent.txt"
SSH_PORT="22"

# OpenClaw 配置
OPENCLAW_VERSION="latest"
GATEWAY_PORT="18789"
GATEWAY_BIND="lan"  # lan = 局域网访问，localhost = 仅本机

# 阿里云百炼模型配置（可选）
CONFIGURE_MODELS="${CONFIGURE_MODELS:-false}"  # 设置 true 自动配置模型
DASHSCOPE_API_KEY="${DASHSCOPE_API_KEY:-}"     # 阿里云 API Key

# ============ 颜色输出 ============
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1" }
log_success() { echo -e "${GREEN}[✓ SUCCESS]${NC} $1" }
log_warn() { echo -e "${YELLOW}[⚠ WARN]${NC} $1" }
log_error() { echo -e "${RED}[✗ ERROR]${NC} $1" }
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

# 在远程服务器执行命令（密码登录）
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
    local hostname=$5
    
    log_step "正在部署到 $ip (主机名：$hostname)"
    
    # 1. 检查 SSH 连接
    log_info "检查 SSH 连接..."
    if ! remote_exec "$ip" "$port" "$user" "$password" "echo 'SSH OK'" > /dev/null 2>&1; then
        log_error "SSH 连接失败：$ip"
        return 1
    fi
    log_success "SSH 连接成功"
    
    # 2. 检查并安装 Node.js
    log_info "检查 Node.js..."
    local node_version
    node_version=$(remote_exec "$ip" "$port" "$user" "$password" "node --version 2>/dev/null || echo 'not installed'")
    
    if [[ "$node_version" == "not installed" ]] || [[ -z "$node_version" ]]; then
        log_warn "Node.js 未安装，开始安装..."
        
        # 安装 Node.js 22.x
        remote_exec "$ip" "$port" "$user" "$password" "
            curl -fsSL https://deb.nodesource.com/setup_22.x 2>/dev/null | bash - && \
            apt install -y nodejs > /dev/null 2>&1
        " || {
            log_error "Node.js 安装失败"
            log_info "故障排除："
            echo "  1. 检查网络连接：ping -c 3 deb.nodesource.com"
            echo "  2. 手动安装：curl -fsSL https://deb.nodesource.com/setup_22.x | bash"
            echo "  3. 使用国内镜像：curl -fsSL https://mirrors.tuna.tsinghua.edu.cn/nodesource/deb/setup_22.x | bash"
            return 1
        }
        
        node_version=$(remote_exec "$ip" "$port" "$user" "$password" "node --version")
        log_success "Node.js 安装完成：$node_version"
    else
        log_success "Node.js 已安装：$node_version"
    fi
    
    # 3. 安装 OpenClaw
    log_info "安装 OpenClaw..."
    remote_exec "$ip" "$port" "$user" "$password" "
        npm install -g openclaw@${OPENCLAW_VERSION} --no-fund --no-audit --loglevel=error 2>/dev/null
    " || {
        log_error "OpenClaw 安装失败"
        log_info "故障排除："
        echo "  1. 检查 npm：npm --version"
        echo "  2. 使用国内镜像：NPM_CONFIG_REGISTRY=https://registry.npmmirror.com npm install -g openclaw"
        echo "  3. 清理缓存：npm cache clean --force"
        return 1
    }
    
    local openclaw_version
    openclaw_version=$(remote_exec "$ip" "$port" "$user" "$password" "openclaw --version 2>/dev/null | head -1")
    log_success "OpenClaw 安装完成：$openclaw_version"
    
    # 4. 配置 Gateway
    log_info "配置 Gateway..."
    
    # 生成随机 Token（如果没有提供）
    local auth_token
    auth_token=$(remote_exec "$ip" "$port" "$user" "$password" "cat /proc/sys/kernel/random/uuid 2>/dev/null | tr -d '-' || echo 'subagent-token-$(date +%s)'")
    
    # 构建配置
    local models_config=""
    if [[ "$CONFIGURE_MODELS" == "true" ]] && [[ -n "$DASHSCOPE_API_KEY" ]]; then
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
        "primary": "bailian/qwen3.5-plus"
      }
    }
  }'
    fi
    
    remote_exec "$ip" "$port" "$user" "$password" "
        mkdir -p ~/.openclaw
        cat > ~/.openclaw/openclaw.json << 'EOCONFIG'
{
  \"gateway\": {
    \"port\": ${GATEWAY_PORT},
    \"mode\": \"local\",
    \"bind\": \"${GATEWAY_BIND}\",
    \"controlUi\": {
      \"enabled\": true,
      \"allowedOrigins\": [\"*\"],
      \"allowInsecureAuth\": true,
      \"dangerouslyDisableDeviceAuth\": true
    },
    \"auth\": {
      \"mode\": \"token\",
      \"token\": \"${auth_token}\"
    }
  }${models_config}
}
EOCONFIG
    "
    log_success "Gateway 配置完成"
    
    # 5. 安装并启动 Gateway 服务
    log_info "安装 Gateway 服务..."
    remote_exec "$ip" "$port" "$user" "$password" "
        openclaw gateway install > /dev/null 2>&1 || true
        systemctl --user daemon-reload
        systemctl --user enable openclaw-gateway.service
        systemctl --user start openclaw-gateway.service
        sleep 2
    "
    
    # 6. 验证运行状态
    log_info "验证运行状态..."
    local status
    status=$(remote_exec "$ip" "$port" "$user" "$password" "
        openclaw gateway status 2>/dev/null | grep -o 'running' || echo 'unknown'
    ")
    
    if [[ "$status" == "running" ]]; then
        log_success "Gateway 运行中"
    else
        log_warn "Gateway 状态：$status"
        log_info "故障排除："
        echo "  1. 查看日志：openclaw logs --follow"
        echo "  2. 重启服务：openclaw gateway restart"
        echo "  3. 检查配置：cat ~/.openclaw/openclaw.json"
    fi
    
    # 输出访问信息
    echo ""
    log_success "部署完成！"
    echo ""
    echo "========================================"
    echo "  访问信息"
    echo "========================================"
    echo "  主机名：$hostname"
    echo "  IP 地址：$ip"
    echo "  访问地址：http://$ip:${GATEWAY_PORT}"
    echo "  Auth Token: $auth_token"
    echo ""
    echo "  管理命令："
    echo "    openclaw gateway status    # 查看状态"
    echo "    openclaw gateway restart   # 重启服务"
    echo "    openclaw logs --follow     # 查看日志"
    echo "========================================"
    echo ""
    
    return 0
}

# 解析 IP 文件（支持密码）
parse_ip_file() {
    local line=$1
    
    # 跳过注释和空行
    [[ "$line" =~ ^[[:space:]]*# ]] && return 1
    [[ -z "${line// }" ]] && return 1
    
    # 解析格式：IP:PORT:USER:PASSWORD:HOSTNAME
    local ip port user password hostname
    IFS=':' read -r ip port user password hostname <<< "$line"
    
    # 默认值
    port="${port:-$SSH_PORT}"
    user="${user:-root}"
    hostname="${hostname:-subagent-$(echo $ip | tr '.' '-')}"
    
    if [[ -z "$password" ]]; then
        log_error "密码不能为空：$ip"
        return 1
    fi
    
    echo "$ip $port $user $password $hostname"
    return 0
}

# ============ 主程序 ============

main() {
    echo ""
    echo "========================================"
    echo "  OpenClaw 子节点自动部署脚本 (增强版)"
    echo "========================================"
    echo ""
    log_info "IP 文件：$IP_FILE"
    log_info "OpenClaw 版本：$OPENCLAW_VERSION"
    log_info "Gateway 端口：$GATEWAY_PORT"
    log_info "Gateway 绑定：$GATEWAY_BIND"
    log_info "配置模型：$CONFIGURE_MODELS"
    echo ""
    
    # 检查 sshpass
    check_sshpass
    
    # 检查 IP 文件
    if [[ ! -f "$IP_FILE" ]]; then
        log_error "IP 文件不存在：$IP_FILE"
        echo ""
        echo "请创建 $IP_FILE 文件，格式如下："
        echo "  IP:端口：用户名：密码：主机名"
        echo ""
        echo "示例："
        echo "  38.246.245.39:22:root:Huanxin0321:mubai-subagent1"
        echo "  192.168.1.100:22:admin:secret123:subagent-2"
        echo ""
        exit 1
    fi
    
    # 安全提醒
    log_warn "安全提醒："
    echo "  - 密码将以明文存储在 $IP_FILE 文件中"
    echo "  - 部署完成后建议删除或加密该文件"
    echo "  - 或使用 SSH 密钥登录替代密码"
    echo ""
    
    # 模型配置提醒
    if [[ "$CONFIGURE_MODELS" == "true" ]]; then
        if [[ -z "$DASHSCOPE_API_KEY" ]]; then
            log_warn "已启用模型配置但未提供 API Key，将跳过模型配置"
            log_info "设置方法：export DASHSCOPE_API_KEY='sk-xxx'"
        else
            log_success "将自动配置阿里云百炼模型"
        fi
    fi
    
    read -p "确认继续？(y/N): " confirm
    if [[ "$confirm" != "y" ]] && [[ "$confirm" != "Y" ]]; then
        log_info "已取消"
        exit 0
    fi
    
    # 统计
    local total=0
    local success=0
    local failed=0
    local tokens=()
    
    # 读取 IP 列表并部署
    while IFS= read -r line || [[ -n "$line" ]]; do
        parsed=$(parse_ip_file "$line") || continue
        
        read -r ip port user password hostname <<< "$parsed"
        
        if [[ -z "$ip" ]]; then
            continue
        fi
        
        ((total++))
        echo ""
        echo "========================================"
        echo "  部署 #$total - $hostname"
        echo "========================================"
        
        if deploy_to_remote "$ip" "$port" "$user" "$password" "$hostname"; then
            ((success++))
            # 保存 Token 信息
            tokens+=("$ip:$GATEWAY_PORT:token_placeholder")
        else
            ((failed++))
            log_error "部署失败：$ip"
        fi
        
    done < "$IP_FILE"
    
    # 汇总
    echo ""
    echo "========================================"
    echo "  部署完成汇总"
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
    echo "  1. 记录各节点的访问地址和 Token"
    echo "  2. 从主节点测试连接：curl http://<子节点 IP>:18789"
    echo "  3. 删除或加密 $IP_FILE 文件（含密码）"
    echo "  4. 在主节点配置子节点连接信息"
    echo ""
}

main "$@"
